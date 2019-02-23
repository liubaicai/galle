# frozen_string_literal: true

# 发布项
class Publisher < ApplicationRecord
  belongs_to :project
end
