class ServersController < ApplicationController

    def index
        @servers = Server.all
    end

    def new
        @server = Server.new
    end

    def create
        server = Server.new(server_params)
        server.save
        redirect_to servers_path
    end

    def edit
        @server = Server.find(params[:id])
    end

    def update
        server = Server.find(params[:id])
        server.update(server_params)
        redirect_to servers_path
    end
    
    def destroy
        server = Server.find(params[:id])
        server.destroy
        redirect_to servers_path
    end

    private
    def server_params
        params.require(:server).permit(:address, :port, :username, :password, :monitor_path)
    end

end
