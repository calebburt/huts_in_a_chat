class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end

  def edit
    logger.error(params)
    @user = User.find(params[:id].to_i)
    logger.error(session[:user_id])
    if params[:id].to_i != session[:user_id]
      redirect_to root_path, alert: "User not found."
    end
  end

  def update
    @user = User.find(params[:id])
    @user.update(user_params)
    print(@user, user_params)
    redirect_to root_path, notice: "Edited profile successfully."
  end

  private
  def user_params
    params.require(:user).permit(:bio, :email, :img_url)
  end
end
