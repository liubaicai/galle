
module LiveResponseMethods

    def live_header
        self.headers['Content-Type'] = 'text/event-stream'
    end

    def live_push data
        data.split("\n") do |d|
            self.stream.write "data:#{d}"
            self.stream.write "\n\n"
        end
    end

    def live_close
        self.stream.write "event: close"
        self.stream.write "\n"
        self.stream.write "data:completed"
        self.stream.write "\n\n"
    end

end