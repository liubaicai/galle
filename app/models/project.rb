class Project < ApplicationRecord
    has_many :publishers
    has_many :project_extend_files
    has_many :publisher_servers
end
