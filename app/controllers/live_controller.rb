class LiveController < ApplicationController
    include ActionController::Live
    ActionController::Live::Response.class_eval do
       include LiveResponseMethods
    end

    def check_server
        response.live_header

        server_id = params[:id]
        server = Server.find(server_id)

        response.live_push "Connecting: #{server.address}:#{server.port}"

        begin
            Net::SSH.start(server.address, server.username,:port => server.port, :password => server.password, :timeout => 10, :non_interactive => true) do |ssh|
                ssh.exec!("mkdir -p #{server.monitor_path}")
                response.live_push "Connected"
            end
        rescue Timeout::Error
            response.live_push "Timed out"
        rescue Errno::EHOSTUNREACH
            response.live_push "Host unreachable"
        rescue Errno::ECONNREFUSED
            response.live_push "Connection refused"
        rescue Net::SSH::AuthenticationFailed
            response.live_push "Authentication failure"
        end

        response.live_close
    ensure
        response.stream.close
    end

    def checkout_project
        response.live_header

        project_id = params[:id]
        project = Project.find(project_id)

        while Rails.cache.exist?('local_shell_running') && Rails.cache.read('local_shell_running')
            response.live_push "等待其他任务完成 ..."
            sleep 3
        end

        Rails.cache.write('local_shell_running', true)

        localRootPath = Rails.root.to_s

        FileUtils.cd(localRootPath)
        localStorePath = "#{localRootPath}/tmp/store/#{project.id}"
        FileUtils.mkdir_p(localStorePath)
        FileUtils.cd(localStorePath)

        begin

            response.live_push "#{project.task_pre_checkout} ..."
            do_shell(project.task_pre_checkout)
    
            if Dir.exist?('.git')
                git = Git.open('.')
                if project.git_url == git.remotes.first.url
    
                    response.live_push "git fetch ..."
                    do_shell("git fetch")
    
                    response.live_push "git reset ..."
                    do_shell("git reset --hard")
    
                    response.live_push "git pull ..."
                    do_shell("git pull")
                
                    response.live_push "git checkout #{project.git_version} ..."
                    do_shell("git checkout #{project.git_version}")
    
                else
                    
                    response.live_push "delete old repo ..."
    
                    FileUtils.cd("..")
                    FileUtils.rm_rf(localStorePath)
                    FileUtils.mkdir_p(localStorePath)
                    FileUtils.cd(localStorePath)
    
                    response.live_push "git clone #{project.git_url} ..."
                    do_shell("git clone #{project.git_url} .")
                    
                    response.live_push "git checkout #{project.git_version} ..."
                    do_shell("git checkout #{project.git_version}")
        
                end
            else
    
                response.live_push "git clone #{project.git_url} ..."
                do_shell("git clone #{project.git_url} .")
                
                response.live_push "git checkout #{project.git_version} ..."
                do_shell("git checkout #{project.git_version}")
    
            end
    
            response.live_push "#{project.task_post_checkout} ..."
            do_shell(project.task_post_checkout)

        rescue => exception
            response.live_push "#{exception.to_s} ..."
        end

        response.live_push "checkout completed"
        response.live_close

        Rails.cache.write('local_shell_running', false)
    ensure
        response.stream.close
        Rails.cache.write('local_shell_running', false)
    end

    private
    def do_shell commondStr
        unless commondStr.nil? || commondStr == ""
            IO.popen(commondStr) do |process|
                while !process.eof?
                    line = process.gets
                    response.live_push line
                end
            end
        end
    end
end
