class MessagesController < ApplicationController
  before_action :set_chat, only: [ :create ]
  before_action :authorize_chat_access, only: [ :create ]
  before_action :set_message, only: [ :edit, :update, :destroy ]
  before_action :require_owner_or_moderator, only: [ :edit, :update, :destroy ]

  def create
    @message = @chat.messages.create(message_params)
    if !@message.errors.empty?
      redirect_to chat_path(@chat), alert: @message.errors.full_messages.join(", ")
      return
    end

    respond_to do |format|
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
    if @message.update(content: params[:message][:content])
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path(@message.chat) }
      end
    else
      redirect_to chat_path(@message.chat), alert: @message.errors.full_messages.join(", ")
    end
  end

  def destroy
    chat = @message.chat
    @message.destroy
    respond_to do |format|
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
    redirect_to root_path, alert: "Not allowed"
  end

  def require_owner_or_moderator
    return if @message.user_id == current_user.id || current_user.is_moderator?
    redirect_to chat_path(@message.chat), alert: "Not allowed"
  end

  def message_params
    { content: params[:message][:content], chat_id: params[:chat_id], user_id: current_user.id, attachment: params[:message][:attachment] }
  end
end
