class ReactionsController < ApplicationController
  before_action :set_message
  before_action :authorize_chat_access

  # Toggles the current user's reaction with the given emoji on the message:
  # adds it if absent, removes it if already present. Idempotent for the
  # caller — the same request always flips state, so the JS doesn't need
  # to know which one to send.
  def create
    emoji = reaction_params[:emoji].to_s.strip
    return head :unprocessable_entity if emoji.blank?

    existing = @message.reactions.find_by(user_id: current_user.id, emoji: emoji)
    if existing
      existing.destroy!
      head :no_content
    else
      @message.reactions.create!(user: current_user, emoji: emoji)
      head :created
    end
  end

  def destroy
    reaction = @message.reactions.find(params[:id])
    return head :forbidden if reaction.user_id != current_user.id && !current_user.is_moderator?
    reaction.destroy!
    head :no_content
  end

  private

  def set_message
    @message = Message.find(params[:message_id])
  end

  def authorize_chat_access
    return if @message.chat.users.include?(current_user) || current_user.is_moderator?
    head :forbidden
  end

  def reaction_params
    params.require(:reaction).permit(:emoji)
  end
end
