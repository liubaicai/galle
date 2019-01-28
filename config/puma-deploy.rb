threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

preload_app!

environment 'production'

cwd = File.dirname(__FILE__) + '/..'
directory cwd

rackup "#{cwd}/config.ru"

pidfile "#{cwd}/tmp/pids/puma.pid"

bind 'tcp://0.0.0.0:10088'
bind "unix://#{cwd}/tmp/sockets/puma.sock"

plugin :tmp_restart