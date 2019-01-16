class CreatePublisherServers < ActiveRecord::Migration[5.2]
  def change
    create_table :publisher_servers do |t|
      t.belongs_to :publisher, index: true
      t.belongs_to :server, index: true

      t.timestamps
    end
  end
end
