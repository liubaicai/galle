#!/usr/bin/env bash

rvm use 2.6.0 do bundle install
rvm use 2.6.0 do rails db:migrate RAILS_ENV=production
rvm use 2.6.0 do rails db:seed RAILS_ENV=production
rvm use 2.6.0 do rails assets:precompile
