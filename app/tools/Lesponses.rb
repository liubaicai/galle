
module Lesponses

    def live_header
        self.headers['Content-Type'] = 'text/event-stream'
    end

    def live_push data
        begin
            data.split("\n") do |d|
                self.stream.write "data:#{d}"
                self.stream.write "\n\n"
            end
        rescue ActionController::Live::ClientDisconnected => e
            puts e
        end
    end

    def live_error exception
        begin
            self.stream.write "event: error"
            self.stream.write "\n"
            exception.to_s.split("\n") do |d|
                self.stream.write "data:#{d}"
                self.stream.write "\n"
            end
            self.stream.write "\n\n"
        rescue ActionController::Live::ClientDisconnected => e
            puts e
        end
    end

    def live_close
        begin
            self.stream.write "event: close"
            self.stream.write "\n"
            self.stream.write "data:completed"
            self.stream.write "\n\n"
        rescue ActionController::Live::ClientDisconnected => e
            puts e
        end
    end

end