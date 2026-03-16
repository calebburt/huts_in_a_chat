class MessagesController < ApplicationController
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

  private

  def message_params
    { content: params[:message][:content], chat_id: params[:chat_id], user_id: session[:user_id], attachment: params[:message][:attachment] }
  end
end
