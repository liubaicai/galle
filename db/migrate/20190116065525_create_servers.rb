class CreateServers < ActiveRecord::Migration[5.2]
  def change
    create_table :servers do |t|
      t.string :address
      t.string :port
      t.string :username
      t.string :password
      t.string :monitor_path

      t.timestamps
    end
  end
end
