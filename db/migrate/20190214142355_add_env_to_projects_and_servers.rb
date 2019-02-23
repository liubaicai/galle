class AddEnvToProjectsAndServers < ActiveRecord::Migration[5.2]
  def change
    add_column :servers, :env_level, :integer # 1测试 0线上
    add_column :projects, :env_level, :integer # 1测试 0线上
  end
end
