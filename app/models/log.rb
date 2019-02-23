# frozen_string_literal: true

# 操作日志
class Log < ApplicationRecord
  belongs_to :user
end
