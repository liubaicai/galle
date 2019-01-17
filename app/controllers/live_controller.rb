class LiveController < ApplicationController
    include ActionController::Live

    def check_server
        response.headers['Content-Type'] = 'text/event-stream'
        10.times {
            response.stream.write "data:hello world"
            response.stream.write "\n\n"
            sleep 1
        }
        response.stream.write "event: close"
        response.stream.write "\n"
        response.stream.write "data:completed"
        response.stream.write "\n\n"
    ensure
        response.stream.close
    end

end
