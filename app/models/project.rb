# frozen_string_literal: true

# 项目
class Project < ApplicationRecord
  has_many :publishers, dependent: :destroy
  has_many :project_extend_files, dependent: :destroy
  has_many :publisher_servers, dependent: :destroy
end
