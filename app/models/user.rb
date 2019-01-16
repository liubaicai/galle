class User < ApplicationRecord
  has_many :logs
  has_secure_token :auth_token
end
