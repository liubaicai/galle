require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

scheduler.every '10s' do
    Rails.cache.write('local_cpu_usage', Machine::CPU.usage)
end