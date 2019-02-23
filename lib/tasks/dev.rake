# frozen_string_literal: true

namespace :dev do
  task :install do
    system('bundle install')
    system('rails db:migrate')
    system('rails db:seed')
  end

  task :run do
    system('rails server')
  end
end
