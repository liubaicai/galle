class AddDefaultToEnv < ActiveRecord::Migration[5.2]
  def change
    change_column_default :servers, :env_level, 1
    change_column_default :projects, :env_level, 1
  end
end
