class LiveController < ApplicationController
    include ActionController::Live
    ActionController::Live::Response.class_eval do
       include LiveResponseMethods
    end

    def check_server
        response.live_header

        server_id = params[:id]
        server = Server.find(server_id)

        response.live_push "Connecting: #{server.address}:#{server.port}"

        begin
            Net::SSH.start(server.address, server.username,:port => server.port, :password => server.password, :timeout => 10, :non_interactive => true) do |ssh|
                ssh.exec!("mkdir -p #{server.monitor_path}")
                response.live_push "Connected"
            end
        rescue Timeout::Error
            response.live_push "Timed out"
        rescue Errno::EHOSTUNREACH
            response.live_push "Host unreachable"
        rescue Errno::ECONNREFUSED
            response.live_push "Connection refused"
        rescue Net::SSH::AuthenticationFailed
            response.live_push "Authentication failure"
        end

        response.live_close
    ensure
        response.stream.close
    end

end
