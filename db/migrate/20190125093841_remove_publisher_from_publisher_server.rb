class RemovePublisherFromPublisherServer < ActiveRecord::Migration[5.2]
  def change
    remove_reference :publisher_servers, :publisher
    add_reference :publisher_servers, :project, index: true, foreign_key: true
  end
end
