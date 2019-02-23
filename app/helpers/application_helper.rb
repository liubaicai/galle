# frozen_string_literal: true

# help
module ApplicationHelper
  def dev?
    return false if Rails.env.production?

    true
  end
end
