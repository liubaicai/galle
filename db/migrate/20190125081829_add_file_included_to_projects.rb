class AddFileIncludedToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :file_included, :string
  end
end
