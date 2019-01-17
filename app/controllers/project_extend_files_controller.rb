class ProjectExtendFilesController < ApplicationController

    def new
        pid = params[:project_id]
        @project = Project.find(pid)
    end

    def create
        file = ProjectExtendFile.new(project_extend_file_params)
        file.save
        redirect_to project_path(file.project_id)
    end

    def edit
        @file = ProjectExtendFile.find(params[:id])
    end

    def update
        file = ProjectExtendFile.find(params[:id])
        file.update(project_extend_file_params)
        redirect_to project_path(file.project_id)
    end
    
    def destroy
        file = ProjectExtendFile.find(params[:id])
        pid = file.project_id
        file.destroy
        redirect_to project_path(pid)
    end

    private
    def project_extend_file_params
        params.require(:project_extend_file).permit(:project_id, :filename, :content)
    end

end
