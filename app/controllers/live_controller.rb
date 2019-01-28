class LiveController < ApplicationController
    include ActionController::Live
    ActionController::Live::Response.class_eval do
        include Lesponses
    end
    ActionDispatch::Response.class_eval do
        include Lesponses
    end

    def check_server
        response.live_header

        server_id = params[:id]
        server = Server.find(server_id)

        response.live_push "正在连接: #{server.address}:#{server.port}"

        begin
            ssh_path = Rails.root.join('tmp', '.ssh', 'id_rsa')
            Net::SSH.start(server.address, server.username,:port => server.port,
                           :keys => ["#{ssh_path}"], :timeout => 10, :non_interactive => true,
                           :config => false, :user_known_hosts_file => []) do |ssh|
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

        if Rails.cache.exist?('local_shell_running') && Rails.cache.read('local_shell_running')
            response.live_push "等待其他任务完成 ..."
            response.live_close
            return
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

            response.live_push "准备文件 ..."
            tmpStorePath = "#{localStorePath}.tmp"
            if Dir.exist?(tmpStorePath)
                FileUtils.rm_rf(tmpStorePath)
            end
            FileUtils.mkdir_p(tmpStorePath)

            if project.file_included.nil? || project.file_included==''
                excs = project.file_excludable.split(';')
                Find.find(localStorePath) do |path|
                    unless path==localStorePath
                        real_path = path.gsub(localStorePath,'')
                        isMV = true
                        excs.each do |exc|
                            if real_path.start_with? "/#{exc}"
                                isMV = false
                            end
                        end
                        if real_path.start_with? "/.git"
                            isMV = false
                        end
                        FileUtils.cp_r(path, "#{tmpStorePath}#{real_path}") if isMV
                    end
                end
            else
                includes = project.file_included.split(';')
                Find.find(localStorePath) do |path|
                    unless path==localStorePath
                        real_path = path.gsub(localStorePath,'')
                        isMV = false
                        includes.each do |exc|
                            if real_path.start_with? "/#{exc}"
                                isMV = true
                            end
                        end
                        FileUtils.cp_r(path, "#{tmpStorePath}#{real_path}") if isMV
                    end
                end
            end

            response.live_push "写入附加文件 ..."
            FileUtils.cd(tmpStorePath)
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
            response.live_push "共发布到"+project.publisher_servers.size.to_s+"台服务器 ..."


            ssh_path = Rails.root.join('tmp', '.ssh', 'id_rsa')
            project.publisher_servers.each do |publisher_server|
                Net::SSH.start(publisher_server.server.address, publisher_server.server.username,:port => publisher_server.server.port,
                               :keys => ["#{ssh_path}"], :timeout => 10, :non_interactive => true,
                               :config => false, :user_known_hosts_file => []) do |ssh|
                    ssh.exec!("mkdir -p #{publisher_server.server.monitor_path}")
                    response.live_push "‘#{publisher_server.server.address}:#{publisher_server.server.port}‘连接成功 ..."
                end
            end

            project.publisher_servers.each do |publisher_server|
                server = publisher_server.server
                response.live_push "开始部署到‘#{server.address}:#{server.port}‘ ..."

                Net::SFTP.start(server.address, server.username,:port => server.port, :password => server.password,
                                :keys => ["#{ssh_path}"], :timeout => 10, :non_interactive => true,
                                :config => false, :user_known_hosts_file => [])  do |sftp|


                    response.live_push "准备备份文件 ..."
                    current_backup = "#{project.target_backup_path}/#{publisher.id}"
                    sftp.session.exec!("mkdir -p #{current_backup}")
                    backups = project.publisher_ids.max(5)
                    sftp.dir.foreach(project.target_backup_path) do |entry|
                        if(entry.name!='.' && entry.name!='..')
                            isDel = true
                            backups.each do |id|
                                if entry.name==id.to_s
                                    isDel = false
                                end
                            end
                            if isDel
                                sftp.session.exec!("rm -rf #{project.target_backup_path}/#{entry.name}")
                            end
                        end
                    end
                    sftp.session.exec!("mkdir -p #{current_backup}")
                    sftp.session.exec!("rm -rf #{project.target_deploy_path}")
                    sftp.session.exec!("ln -sf #{current_backup} #{project.target_deploy_path}")

                    response.live_push "执行部署前置任务 ..."
                    unless project.task_pre_deploy.nil? || project.task_pre_deploy == ""
                        project.task_pre_deploy.split(';').each do |command|
                            sftp.session.exec!("source #{server.rc_file_path};cd #{project.target_deploy_path};#{command}") do |channel, stream, data|
                                response.live_push data
                            end
                        end
                    end

                    response.live_push "正在发布文件 ..."
                    sftp.upload!(tmpStorePath, project.target_deploy_path)

                    response.live_push "执行部署后置任务 ..."
                    unless project.task_post_deploy.nil? || project.task_post_deploy == ""
                        project.task_post_deploy.split(';').each do |command|
                            sftp.session.exec!("source #{server.rc_file_path};cd #{project.target_deploy_path};#{command}") do |channel, stream, data|
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

            Log.create_log(@current_user.id, 'Publish', "#{publisher.title}:#{project.title}")
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
