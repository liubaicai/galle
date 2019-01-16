class CreateProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :projects do |t|
      t.string :title
      t.string :description
      t.string :git_url
      t.string :git_version
      t.string :file_excludable
      t.string :file_added
      t.string :local_store_path
      t.string :target_deploy_path
      t.string :target_backup_path
      t.string :task_pre_checkout
      t.string :task_post_checkout
      t.string :task_pre_deploy
      t.string :task_post_deploy

      t.timestamps
    end
  end
end
