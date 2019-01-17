class AddStatusToPublishers < ActiveRecord::Migration[5.2]
  def change
    add_column :publishers, :published, :boolean, default: false
  end
end
