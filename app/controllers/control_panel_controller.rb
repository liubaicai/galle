# frozen_string_literal: true

# 面板页
class ControlPanelController < ApplicationController
  def index
    @local_server_status = Rails.cache.read('local_server_status')
    @publishers = Publisher.where(published: false).order(id: :asc).take(5)
    @logs = Log.order(id: :desc).take(10)
  end
end
