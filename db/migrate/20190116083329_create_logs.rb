class CreateLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :logs do |t|
      t.string :job
      t.belongs_to :user, index: true

      t.timestamps
    end
  end
end
