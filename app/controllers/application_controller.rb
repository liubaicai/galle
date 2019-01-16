class ApplicationController < ActionController::Base
    before_action :check_auth_token

    def check_auth_token
        puts cookies.to_hash
        token = cookies[:user_auth_token]
        if token.nil?
            redirect_to '/user/login'
        else
            user = User.find_by(auth_token: token)
            if user.nil?
                redirect_to '/user/login'
            else
                @current_user = user
            end
        end
    end
end
