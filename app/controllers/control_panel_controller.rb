class ControlPanelController < ApplicationController
    def index
        @status = Machine.status.to_json
        if Rails.cache.exist?('local_cpu_usage')
            @local_cpu_usage = "cpu占用率: #{ '%.2f' % Rails.cache.read('local_cpu_usage') }%"
        else
            @local_cpu_usage = 'cpu占用率: 暂无数据'
        end
    end
end
  