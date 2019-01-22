class ControlPanelController < ApplicationController
    def index

    end

    def board
        @local_server_status = Machine.status.to_json
        @publishers = Publisher.where(published: false).order(id: :asc).take(5)
        @logs = Log.order(id: :desc).take(10)
    end
end
