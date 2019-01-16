class CreatePublishers < ActiveRecord::Migration[5.2]
  def change
    create_table :publishers do |t|
      t.string :title
      t.datetime :publish_time
      t.belongs_to :project, index: true

      t.timestamps
    end
  end
end
