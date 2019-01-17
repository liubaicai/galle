class ControlPanelController < ApplicationController
    def index
        @status = Machine.status.to_json
    end
end
  