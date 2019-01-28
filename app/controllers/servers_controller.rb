class ServersController < ApplicationController

    def index
        @servers = Server.all
    end

    def new
        @server = Server.new
    end

    def create
        server = Server.new(server_params)
        if server.rc_file_path.nil? || server.rc_file_path==''
            server.rc_file_path = '~/.bashrc'
        end
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
        if server.rc_file_path.nil? || server.rc_file_path==''
            server.rc_file_path = '~/.bashrc'
            server.save
        end
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
