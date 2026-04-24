class UsersController < ApplicationController
  before_action :require_self, only: [ :edit, :update ]

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    @user.update(user_params)
    redirect_to root_path, notice: "Edited profile successfully."
  end

  def index
    @users = User.all.where.not(confirmed: false)
  end

  private
  def require_self
    unless params[:id].to_i == current_user.id
      redirect_to root_path, alert: "User not found."
    end
  end

  def user_params
    params.require(:user).permit(:bio, :email, :img_url, :name, :avatar)
  end
end
