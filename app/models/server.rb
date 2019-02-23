# frozen_string_literal: true

# 服务器
class Server < ApplicationRecord
  has_many :publisher_servers, dependent: :destroy
end
