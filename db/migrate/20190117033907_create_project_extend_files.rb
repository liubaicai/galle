class CreateProjectExtendFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :project_extend_files do |t|
      t.string :filename
      t.text :content

      t.timestamps
    end
  end
end
