class ControlPanelController < ApplicationController
    def index
        @local_server_status = Machine.status.to_json
    end
end
  