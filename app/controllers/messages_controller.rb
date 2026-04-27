class MessagesController < ApplicationController
  before_action :set_chat, only: [ :create ]
  before_action :authorize_chat_access, only: [ :create ]
  before_action :set_message, only: [ :edit, :update, :destroy ]
  before_action :require_owner_or_moderator, only: [ :edit, :update, :destroy ]

  def create
    @message = @chat.messages.create(message_params)
    if @message.errors.any?
      respond_to do |format|
        format.json { render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity }
        format.any(:html, :turbo_stream) { redirect_to chat_path(@chat), alert: @message.errors.full_messages.join(", ") }
      end
      return
    end

    respond_to do |format|
      format.json { render :show, status: :created }
      format.turbo_stream
      format.html { redirect_to chat_path(@chat) }
    end
  end

  def edit
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path(@message.chat) }
    end
  end

  def update
    if @message.update(message_update_params)
      respond_to do |format|
        format.json { render :show }
        format.turbo_stream
        format.html { redirect_to chat_path(@message.chat) }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity }
        format.any(:html, :turbo_stream) { redirect_to chat_path(@message.chat), alert: @message.errors.full_messages.join(", ") }
      end
    end
  end

  def destroy
    chat = @message.chat
    @message.destroy
    respond_to do |format|
      format.json { head :no_content }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@message) }
      format.html { redirect_to chat_path(chat) }
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def authorize_chat_access
    return if @chat.users.include?(current_user) || current_user.is_moderator?
    deny_access(root_path)
  end

  def require_owner_or_moderator
    return if @message.user_id == current_user.id || current_user.is_moderator?
    deny_access(chat_path(@message.chat))
  end

  def deny_access(html_redirect)
    respond_to do |format|
      format.json { render json: { error: "Not allowed" }, status: :forbidden }
      format.any(:html, :turbo_stream) { redirect_to html_redirect, alert: "Not allowed" }
    end
  end

  def message_params
    params.expect(message: [ :content, :attachment ])
          .merge(chat_id: params[:chat_id], user_id: current_user.id)
  end

  def message_update_params
    params.expect(message: [ :content ])
  end
end
