module ApplicationHelper

    def isDev
        if Rails.env=='production'
            return false
        end
        return true
    end

end
