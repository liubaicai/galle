module ApplicationHelper

    def isDev
        environment = ENV.fetch("RAILS_ENV") { "development" }
        if environment=='production'
            return false
        end
        return true
    end

end
