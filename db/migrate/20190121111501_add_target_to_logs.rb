class AddTargetToLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :logs, :target, :string
  end
end
