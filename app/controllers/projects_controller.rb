class ProjectsController < ApplicationController

    def index
        @projects = Project.all
    end

    def show
        @project = Project.find(params[:id])
    end

    def new
        @project = Project.new
        @servers = Server.all
    end

    def create
        project = Project.new(project_params)
        if project.git_version == ''
            project.git_version = 'master'
        end
        project.save
        publisher_servers = params[:publisher_servers]
        unless publisher_servers.nil?
            publisher_servers.each do |server_id|
                publisher_server = PublisherServer.new
                publisher_server.server_id = server_id
                publisher_server.project_id = project.id
                publisher_server.save
            end
        end
        Log.create_log(@current_user.id, 'CreateProject', "#{project.title}:#{project.description}")
        redirect_to project_path(project)
    end

    def edit
        @project = Project.find(params[:id])
        @servers = Server.all
    end

    def update
        project = Project.find(params[:id])
        project.update(project_params)
        if project.git_version == ''
            project.git_version = 'master'
            project.save
        end
        publish_servers = PublisherServer.where(project_id: project.id)
        publish_servers.destroy_all
        project_servers = params[:publisher_servers]
        unless project_servers.nil?
            project_servers.each do |server_id|
                publisher_server = PublisherServer.new
                publisher_server.server_id = server_id
                publisher_server.project_id = project.id
                publisher_server.save
            end
        end
        Log.create_log(@current_user.id, 'UpdateProject', "#{project.title}:#{project.description}")
        redirect_to project_path(project)
    end

    def destroy
        project = Project.find(params[:id])
        project.destroy
        publish_servers = PublisherServer.where(project_id: project.id)
        publish_servers.destroy_all
        publishers = Publisher.where(project_id: project.id)
        publishers.destroy_all
        Log.create_log(@current_user.id, 'DeleteProject', "#{project.title}:#{project.description}")
        redirect_to projects_path
    end

    def copy
        project = Project.find(params[:id])
        new_project = project.dup
        new_project.save
        redirect_to projects_path
    end

    private

    def project_params
        params.require(:project).permit(
            :title, :description, :git_url, :git_version, :file_included, :file_excludable,
            :local_store_path, :target_deploy_path, :target_backup_path, :task_pre_checkout,
            :task_post_checkout, :task_pre_deploy, :task_post_deploy
        )
    end

end
