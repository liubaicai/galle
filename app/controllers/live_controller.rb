class LiveController < ApplicationController
    include ActionController::Live
    ActionController::Live::Response.class_eval do
       include LiveResponseMethods
    end

    def check_server
        response.live_header

        server_id = params[:id]
        server = Server.find(server_id)

        response.live_push server.address
        response.live_push server.port
        response.live_push server.username
        response.live_push server.password
        response.live_push server.monitor_path

        response.live_close
    ensure
        response.stream.close
    end

end
