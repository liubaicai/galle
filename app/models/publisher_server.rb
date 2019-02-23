# frozen_string_literal: true

# 发布目标服务器
class PublisherServer < ApplicationRecord
  belongs_to :server
  belongs_to :project
end
