class AddRcFileToServers < ActiveRecord::Migration[5.2]
  def change
    add_column :servers, :rc_file_path, :string
  end
end
