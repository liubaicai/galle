class LiveController < ApplicationController
    include ActionController::Live
    ActionController::Live::Response.class_eval do
       include LiveResponseMethods
    end

    def check_server
        response.live_header

        server_id = params[:id]
        server = Server.find(server_id)

        response.live_push "正在连接: #{server.address}:#{server.port}"

        begin
            Net::SSH.start(server.address, server.username,:port => server.port, :password => server.password, :timeout => 10, :non_interactive => true) do |ssh|
                ssh.exec!("mkdir -p #{server.monitor_path}")
                response.live_push "连接成功"
            end
        rescue Timeout::Error
            response.live_error "Timed out"
        rescue Errno::EHOSTUNREACH
            response.live_error "Host unreachable"
        rescue Errno::ECONNREFUSED
            response.live_error "Connection refused"
        rescue Errno::EALREADY 
            response.live_error "Connection refused(Operation already in progress)"
        rescue Net::SSH::AuthenticationFailed
            response.live_error "Authentication failure"
        rescue => exception
            response.live_error exception
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

            response.live_push "执行检出前置任务 ..."
            project.task_pre_checkout.split(';').each do |command|
                do_shell(command)
            end
    
            if Dir.exist?('.git')
                git = Git.open('.')
                if project.git_url == git.remotes.first.url

                    response.live_push "更新本地代码 ..."
                    git.fetch
                    git.reset_hard
                    git.clean(:force=>true,:d=>true)
                    git.pull
                
                    response.live_push "检出'#{project.git_version}'版本 ..."
                    git.checkout project.git_version
    
                else
                    
                    response.live_push "删除旧仓库 ..."
    
                    FileUtils.cd("..")
                    FileUtils.rm_rf(localStorePath)
                    FileUtils.mkdir_p(localStorePath)
                    FileUtils.cd(localStorePath)
    
                    response.live_push "克隆代码库 ..."
                    git = Git.clone(project.git_url,".")

                    response.live_push "检出'#{project.git_version}'版本 ..."
                    git.checkout project.git_version
        
                end
            else

                response.live_push "克隆代码库 ..."
                git = Git.clone(project.git_url,".")

                response.live_push "检出'#{project.git_version}'版本 ..."
                git.checkout project.git_version
    
            end

            response.live_push "执行检出后置任务 ..."
            project.task_post_checkout.split(';').each do |command|
                do_shell(command)
            end

            response.live_push "检出完成"
        rescue => exception
            response.live_error exception
        end

        response.live_close

        Rails.cache.write('local_shell_running', false)
    ensure
        response.stream.close
        Rails.cache.write('local_shell_running', false)
    end

    def publish_project
        response.live_header

        publisher_id = params[:id]
        publisher = Publisher.find(publisher_id)

        if publisher.published
            response.live_push "该发布已经完成"
            response.live_close
            return
        end

        project = publisher.project

        while Rails.cache.exist?('local_shell_running') && Rails.cache.read('local_shell_running')
            response.live_push "等待其他任务完成 ..."
            sleep 3
        end

        Rails.cache.write('local_shell_running', true)

        begin
            localRootPath = Rails.root.to_s
            FileUtils.cd(localRootPath)
            localStorePath = "#{localRootPath}/tmp/store/#{project.id}"
            FileUtils.mkdir_p(localStorePath)
            FileUtils.cd(localStorePath)

            response.live_push "执行检出前置任务 ..."
            project.task_pre_checkout.split(';').each do |command|
                do_shell(command)
            end
    
            if Dir.exist?('.git')
                git = Git.open('.')
                if project.git_url == git.remotes.first.url

                    response.live_push "更新本地代码 ..."
                    git.fetch
                    git.reset_hard
                    git.clean(:force=>true,:d=>true)
                    git.pull

                    response.live_push "检出'#{project.git_version}'版本 ..."
                    git.checkout project.git_version


                else

                    response.live_push "删除旧仓库 ..."

                    FileUtils.cd("..")
                    FileUtils.rm_rf(localStorePath)
                    FileUtils.mkdir_p(localStorePath)
                    FileUtils.cd(localStorePath)

                    response.live_push "克隆代码库 ..."
                    git = Git.clone(project.git_url,".")

                    response.live_push "检出'#{project.git_version}'版本 ..."
                    git.checkout project.git_version

                end
            else

                response.live_push "克隆代码库 ..."
                git = Git.clone(project.git_url,".")

                response.live_push "检出'#{project.git_version}'版本 ..."
                git.checkout project.git_version

            end

            response.live_push "执行检出后置任务 ..."
            project.task_post_checkout.split(';').each do |command|
                do_shell(command)
            end

            response.live_push "代码检出完成 ..."

            response.live_push "写入附加文件 ..."
            project_extend_files = project.project_extend_files
            project_extend_files.each do |project_extend_file|
                tname = project_extend_file.filename
                tarr = tname.split('/')
                if tarr.size>1
                    tarr.delete_at(tarr.size-1)
                    project_extend_file_path = tarr.join('/')
                    FileUtils.mkdir_p(project_extend_file_path)
                end
                aFile = File.new(project_extend_file.filename, "w+")
                aFile.syswrite(project_extend_file.content)
                aFile.close
            end

            response.live_push "文件准备完成 ..."
            response.live_push "共发布到"+publisher.publisher_servers.size.to_s+"台服务器 ..."

            publisher.publisher_servers.each do |publisher_server|
                server = publisher_server.server
                response.live_push "开始连接到‘#{server.address}:#{server.port}‘ ..."

                Net::SFTP.start(server.address, server.username,:port => server.port, :password => server.password, :timeout => 10, :non_interactive => true)  do |sftp|

                    response.live_push "执行部署前置任务 ..."
                    unless project.task_pre_deploy.nil? || project.task_pre_deploy == ""
                        project.task_pre_deploy.split(';').each do |command|
                            sftp.session.exec!("cd #{project.target_deploy_path};#{command}") do |channel, stream, data|
                                response.live_push data
                            end
                        end
                    end

                    response.live_push "准备文件 ..."
                    tmpStorePath = "#{localStorePath}.tmp"
                    if Dir.exist?(tmpStorePath)
                        FileUtils.rm_rf(tmpStorePath)
                    end
                    FileUtils.mkdir_p(tmpStorePath)
                    Find.find(localStorePath) do |path|
                        unless path==localStorePath
                            real_path = path.gsub(localStorePath,'')
                            FileUtils.cp_r(path, "#{tmpStorePath}#{real_path}")
                        end
                    end
                    excs = project.file_excludable.split(';')
                    excs.each do |exc|
                        excp = "#{tmpStorePath}/#{exc}"
                        FileUtils.rm_rf(excp)
                    end

                    response.live_push "正在发布文件 ..."
                    sftp.session.exec!("mkdir -p #{project.target_deploy_path}")
                    sftp.dir.foreach(project.target_deploy_path) do |entry|
                        if(entry.name!='.' && entry.name!='..')
                            sftp.session.exec!("rm -rf #{project.target_deploy_path}/#{entry.name}")
                        end
                    end
                    sftp.upload!(tmpStorePath, project.target_deploy_path)

                    response.live_push "执行部署后置任务 ..."
                    unless project.task_post_deploy.nil? || project.task_post_deploy == ""
                        project.task_post_deploy.split(';').each do |command|
                            sftp.session.exec!("cd #{project.target_deploy_path};#{command}") do |channel, stream, data|
                                response.live_push data
                            end
                        end
                    end
                end
                
            end

            publisher.published = true
            publisher.publish_time = Time.now
            publisher.save

            response.live_push "部署完成"
        rescue Timeout::Error
            response.live_error "Timed out"
        rescue Errno::EHOSTUNREACH
            response.live_error "Host unreachable"
        rescue Errno::ECONNREFUSED
            response.live_error "Connection refused"
        rescue Net::SSH::AuthenticationFailed
            response.live_error "Authentication failure"
        rescue Net::SFTP::StatusException => exception
            response.live_error "StatusException: #{exception.description};#{exception.response}"
        rescue => exception
            response.live_error exception
        end

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
    def do_shell_without_put commondStr
        unless commondStr.nil? || commondStr == ""
            IO.popen(commondStr) do |process|
                while !process.eof?
                    line = process.gets
                    puts line
                end
            end
        end
    end
end
