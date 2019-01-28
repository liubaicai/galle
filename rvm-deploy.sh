#!/usr/bin/env bash

rvm use 2.6.0
bundle install
rails db:migrate RAILS_ENV=production
rails db:seed RAILS_ENV=production
rails assets:precompile
