class PublisherServer < ApplicationRecord
    belongs_to :server
    belongs_to :publisher
end
