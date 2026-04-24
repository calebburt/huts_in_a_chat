class MessagesController < ApplicationController
  before_action :set_message, only: [ :edit, :update, :destroy ]
  before_action :require_owner, only: [ :edit, :update, :destroy ]

  def create
    @chat = Chat.find(params[:chat_id])
    @message = @chat.messages.create(message_params)
    if !@message.errors.empty?
      logger.error(@message.errors.full_messages)
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

  def set_message
    @message = Message.find(params[:id])
  end

  def require_owner
    unless @message.user_id == session[:user_id]
      redirect_to chat_path(@message.chat), alert: "Not allowed"
    end
  end

  def message_params
    { content: params[:message][:content], chat_id: params[:chat_id], user_id: session[:user_id], attachment: params[:message][:attachment] }
  end
end
