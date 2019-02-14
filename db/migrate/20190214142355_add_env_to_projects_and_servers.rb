class AddEnvToProjectsAndServers < ActiveRecord::Migration[5.2]
  def change
    add_column :servers, :env_level, :integer
    add_column :projects, :env_level, :integer
  end
end
