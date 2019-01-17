class AddProjectRefToProjectExtendFiles < ActiveRecord::Migration[5.2]
  def change
    add_reference :project_extend_files, :project, index: true, foreign_key: true
  end
end
