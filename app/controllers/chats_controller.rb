class ChatsController < ApplicationController
  before_action :set_chat, only: %i[ show edit update destroy ]

  # GET /chats or /chats.json
  def index
    @chats = Chat.joins(:users).where(users: { id: session[:user_id] }).distinct
  end

  # GET /chats/1 or /chats/1.json
  def show
    if Chat.find(params[:id]).users.include? User.find(session[:user_id])
      @message = Message.new
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
    if Chat.find(params[:id]).users.include? User.find(session[:user_id])
      render
    else
      redirect_to root_path, status: :not_found
    end
  end

  # POST /chats or /chats.json
  def create
    @chat = Chat.new(chat_params)
    
    for user_id in params[:chat][:user_ids]
      begin
        @chat.users.append User.find(user_id.to_i)
      rescue => _
        logger.warn "Invalid user id: #{user_id.to_i}"
      end
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
    for user_id in params[:chat][:user_ids]
      begin
        @chat.users.append User.find(user_id.to_i)
      rescue => _
        logger.warn "Invalid user id: #{user_id.to_i}"
      end
    end

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
    # Use callbacks to share common setup or constraints between actions.
    def set_chat
      @chat = Chat.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def chat_params
      params.expect(chat: [ :name, :user_ids ])
    end
end
