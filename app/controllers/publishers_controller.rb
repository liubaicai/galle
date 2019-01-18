class PublishersController < ApplicationController

    def index
        @publishers = Publisher.all
    end

    def new
        pid = params[:project_id]
        @project = Project.find(pid)
    end

    def create
        publisher = Publisher.new(publisher_params)
        publisher.save
        redirect_to publishers_path
    end

    private
    def publisher_params
        params.require(:publisher).permit(:title, :project_id)
    end

end
