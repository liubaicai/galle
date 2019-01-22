class ControlPanelController < ApplicationController
    def index

    end

    def board
        @local_server_status = Machine.status.to_json
    end
end
  