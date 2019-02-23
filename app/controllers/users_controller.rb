# frozen_string_literal: true

# 用户
class UsersController < ApplicationController
  skip_before_action :check_auth_token, only: %i[login login_post]

  def index
    if @current_user.level < 100
      render plain: '你没有权限'
    else
      @users = User.where('level < ?', 100)
    end
  end

  def new; end

  def create
    if @current_user.level < 100
      redirect_to root_path
    else
      username = params[:username]
      password = params[:password]
      if username == '' || password == ''
        @error = '用户名或密码不能为空'
        render 'new'
      else
        usr = User.find_by(username: username)
        if usr.nil?
          usr = User.new
          usr.username = username
          usr.password_digest = Digest::MD5.hexdigest(Digest::MD5.hexdigest(password))
          usr.level = 1
          usr.save
          Log.create_log(@current_user.id, 'CreateUser', usr.username.to_s)
          redirect_to users_path
        else
          @error = '该用户已经存在'
          render 'new'
        end
      end
    end
  end

  def changepwd
    render template: 'users/edit'
  end

  def changepwd_post
    password = params[:password]
    new_password = params[:new_password]
    new2_password = params[:new2_password]
    if new_password != new2_password
      @error = '两次输入的新密码不一致'
      render template: 'users/edit'
    elsif @current_user.password_digest != Digest::MD5.hexdigest(Digest::MD5.hexdigest(password))
      @error = '原密码错误'
      render template: 'users/edit'
    else
      @current_user.password_digest = Digest::MD5.hexdigest(Digest::MD5.hexdigest(new_password))
      @current_user.regenerate_auth_token
      @current_user.save
      redirect_to root_path
    end
  end

  def destroy
    if @current_user.level < 100
      redirect_to root_path
    else
      user = User.find(params[:id])
      user.destroy
      Log.create_log(@current_user.id, 'DeleteUser', user.username.to_s)
      redirect_to users_path
    end
  end

  def login; end

  def login_post
    username = params[:username]
    password = params[:password]
    user = User.find_by(username: username)
    if user.nil?
      @error = '用户不存在'
      render 'login'
    elsif user.password_digest != Digest::MD5.hexdigest(Digest::MD5.hexdigest(password))
      @error = '密码错误'
      render 'login'
    else
      user.regenerate_auth_token
      user.save
      cookies[:user_auth_token] = user.auth_token
      redirect_to root_path
    end
  end

  def logout
    cookies.delete(:user_auth_token)
    redirect_to users_login_path
  end

  def logout_post
    cookies.delete(:user_auth_token)
    redirect_to users_login_path
  end
end
