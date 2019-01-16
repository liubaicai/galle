class Publisher < ApplicationRecord
    has_many :publisher_servers
    belongs_to :project
end
