require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

if Machine.commond('uname') == 'Linux'
    scheduler.every '10s' do
        Rails.cache.write('local_cpu_usage', Machine::CPU.usage)
    end
end