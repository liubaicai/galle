class RemoveFileAddedFromProjects < ActiveRecord::Migration[5.2]
  def change
    remove_column :projects, :file_added, :string
  end
end
