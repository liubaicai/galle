# frozen_string_literal: true

# 用户
class User < ApplicationRecord
  has_many :logs, dependent: :nullify
  has_secure_token :auth_token
end
