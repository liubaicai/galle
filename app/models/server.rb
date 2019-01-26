class Server < ApplicationRecord
    has_many :publisher_servers, dependent: :destroy
end
