# frozen_string_literal: true

# 向ActionController::Live写数据
module Lesponses
  def live_header
    headers['Content-Type'] = 'text/event-stream'
  end

  def live_push(data)
    data.split("\n") do |d|
      stream.write "data:#{d}"
      stream.write "\n\n"
    end
  rescue ActionController::Live::ClientDisconnected => e
    Rails.logger.error e
  end

  def live_error(exception)
    stream.write 'event: error'
    stream.write "\n"
    exception.to_s.split("\n") do |d|
      stream.write "data:#{d}"
      stream.write "\n"
    end
    stream.write "\n\n"
  rescue ActionController::Live::ClientDisconnected => e
    Rails.logger.error e
  end

  def live_close
    stream.write 'event: close'
    stream.write "\n"
    stream.write 'data:completed'
    stream.write "\n\n"
  rescue ActionController::Live::ClientDisconnected => e
    Rails.logger.error e
  end
end
