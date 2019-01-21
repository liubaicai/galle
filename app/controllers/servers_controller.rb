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
        Log.create_log(@current_user.id, 'CreateServer', "#{server.address}:#{server.port}")
        redirect_to servers_path
    end

    def edit
        @server = Server.find(params[:id])
    end

    def update
        server = Server.find(params[:id])
        server.update(server_params)
        Log.create_log(@current_user.id, 'UpdateServer', "#{server.address}:#{server.port}")
        redirect_to servers_path
    end
    
    def destroy
        server = Server.find(params[:id])
        server.destroy
        Log.create_log(@current_user.id, 'DeleteServer', "#{server.address}:#{server.port}")
        redirect_to servers_path
    end

    private
    def server_params
        params.require(:server).permit(:address, :port, :username, :password, :monitor_path)
    end

end
