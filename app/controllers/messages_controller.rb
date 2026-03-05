class MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])
    @message = @chat.messages.create(message_params)
    redirect_to chat_path(@chat)
  end

  private

  def message_params
    { content: params[:message][:content], chat_id: params[:chat_id], user_id: session[:user_id] }
  end
end
