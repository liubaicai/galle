class UsersController < ApplicationController
    skip_before_action :check_auth_token, only: [:login, :login_post]
  
    def login
    end
  
    def login_post
        username = params[:username]
        password = params[:password]
        user = User.find_by(username: username)
        if user.nil?
            @error = '用户不存在'
            render "login" 
        elsif user.password_digest != Digest::MD5.hexdigest(Digest::MD5.hexdigest(password))
            @error = '密码错误'
            render "login" 
        else
            user.regenerate_auth_token
            user.save
            cookies[:user_auth_token] = user.auth_token
            redirect_to '/'
        end
    end
  
    def logout_post
        cookies.delete(:user_auth_token)
        render "login" 
    end
  
end
  