class PublishersController < ApplicationController

    def index
        @publishers = Publisher.all
    end

    def new
        pid = params[:project_id]
        @project = Project.find(pid)
        @servers = Server.all
    end

    def create
        publisher = Publisher.new(publisher_params)
        publisher.save
        publisher_servers = params[:publisher_servers]
        unless publisher_servers.nil?
            publisher_servers.each do |server_id|
                publisher_server = PublisherServer.new
                publisher_server.server_id = server_id
                publisher_server.publisher_id = publisher.id
                publisher_server.save
            end
        end
        redirect_to publishers_path
    end
    
    def destroy
        publisher = Publisher.find(params[:id])
        publisher.destroy
        redirect_to publishers_path
    end

    private
    def publisher_params
        params.require(:publisher).permit(:title, :project_id)
    end

end
