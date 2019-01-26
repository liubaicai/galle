class PublishersController < ApplicationController

    def index
        @publishers = Publisher.order(published: :asc, id: :desc).paginate(:page => params[:page], :per_page => 5)
    end

    def new
        pid = params[:project_id]
        @project = Project.find(pid)
    end

    def create
        publisher = Publisher.new(publisher_params)
        publisher.save
        Log.create_log(@current_user.id, 'CreatePublisher', "#{publisher.title}:#{publisher.project.title}")
        redirect_to publishers_path
    end
    
    def destroy
        publisher = Publisher.find(params[:id])
        publisher.destroy
        Log.create_log(@current_user.id, 'DeletePublisher', "#{publisher.title}:#{publisher.project.title unless publisher.project.nil?}")
        redirect_to publishers_path
    end

    private
    def publisher_params
        params.require(:publisher).permit(:title, :project_id)
    end

end
