require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

if Machine.commond('uname') == 'Linux'
    scheduler.every '10s' do
        Rails.cache.write('local_cpu_usage', Machine::CPU.usage)
    end
end

Rails.cache.write('local_server_status', Machine.status.to_json)
scheduler.every '10m' do
    Rails.cache.write('local_server_status', Machine.status.to_json)
end