class ChatsController < ApplicationController
  before_action :set_chat, only: %i[ show edit update destroy ]
  before_action :authorize_manage, only: %i[ edit update destroy ]
  before_action :require_group_chat, only: %i[ edit update destroy ]

  # GET /chats or /chats.json
  def index
    if current_user.is_moderator?
      @chats = Chat.where(chat_type: :group_chat).distinct
      @shown_as_moderator = true
    else
      @chats = Chat.where(chat_type: :group_chat).joins(:users).where(users: { id: current_user.id }).distinct
    end
  end

  def index_dm
    @users = User.where.not(id: current_user.id).where(confirmed: true)
  end

  def dm
    target = User.find_by(id: params[:user_id])
    if target.nil? || !target.confirmed? || target.id == current_user.id
      redirect_to dm_chats_path, alert: "Cannot start that DM."
      return
    end
    @chat = Chat.find_or_create_dm(current_user, target)
    redirect_to @chat
  end

  # GET /chats/1 or /chats/1.json
  def show
    if @chat.users.include?(current_user)
      @message = Message.new
    elsif current_user.is_moderator?
      @message = Message.new
      @shown_as_moderator = true
    else
      redirect_to root_path, status: :not_found
    end
  end

  # GET /chats/new
  def new
    @chat = Chat.new
  end

  # GET /chats/1/edit
  def edit
  end

  # POST /chats or /chats.json
  def create
    @chat = Chat.new(chat_params.merge(chat_type: :group_chat))

    assign_users_from_params(@chat)

    unless @chat.users.include?(current_user)
      redirect_to root_path, alert: "Chat was not created: you must include yourself."
      return
    end

    respond_to do |format|
      if @chat.save
        format.html { redirect_to @chat, notice: "Chat was successfully created." }
        format.json { render :show, status: :created, location: @chat }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chat.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chats/1 or /chats/1.json
  def update
    @chat.users = []
    assign_users_from_params(@chat)

    respond_to do |format|
      if @chat.update(chat_params)
        format.html { redirect_to @chat, notice: "Chat was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @chat }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chat.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chats/1 or /chats/1.json
  def destroy
    @chat.destroy!

    respond_to do |format|
      format.html { redirect_to chats_path, notice: "Chat was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_chat
      @chat = Chat.find(params.expect(:id))
    end

    def authorize_manage
      if @chat.users.include?(current_user)
        # allowed as member
      elsif current_user.is_moderator?
        @shown_as_moderator = true
      else
        redirect_to root_path, status: :not_found
      end
    end

    def require_group_chat
      return if @chat.group_chat?
      redirect_to root_path, status: :not_found
    end

    # Only allow a list of trusted parameters through.
    def chat_params
      params.expect(chat: [ :name ])
    end

    def assign_users_from_params(chat)
      Array(params.dig(:chat, :user_ids)).each do |user_id|
        user = User.find_by(id: user_id.to_i)
        if user
          chat.users.append(user) unless chat.users.include?(user)
        else
          logger.warn "Invalid user id: #{user_id.to_i}"
        end
      end
    end
end
