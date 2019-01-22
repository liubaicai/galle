class ProjectsController < ApplicationController

    def index
        @projects = Project.all
    end

    def show
        @project = Project.find(params[:id])
    end

    def new
        @project = Project.new
    end

    def create
        project = Project.new(project_params)
        project.save
        Log.create_log(@current_user.id, 'CreateProject', "#{project.title}:#{project.description}")
        redirect_to project_path(project)
    end

    def edit
        @project = Project.find(params[:id])
    end

    def update
        project = Project.find(params[:id])
        project.update(project_params)
        Log.create_log(@current_user.id, 'UpdateProject', "#{project.title}:#{project.description}")
        redirect_to projects_path
    end
    
    def destroy
        project = Project.find(params[:id])
        project.destroy
        Log.create_log(@current_user.id, 'DeleteProject', "#{project.title}:#{project.description}")
        redirect_to projects_path
    end

    private
    def project_params
        params.require(:project).permit(
            :title, :description, :git_url, :git_version, :file_excludable,
            :local_store_path, :target_deploy_path, :target_backup_path, :task_pre_checkout, 
            :task_post_checkout, :task_pre_deploy, :task_post_deploy
        )
    end

end
