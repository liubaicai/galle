# frozen_string_literal: true

# 系统状态
class StatusController < ApplicationController
  def cpu
    if Rails.cache.exist?('local_cpu_usage')
      render plain: format('%.2f', Rails.cache.read('local_cpu_usage'))
    else
      render plain: '0'
    end
  end
end
