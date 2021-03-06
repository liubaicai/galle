# frozen_string_literal: true

# 实时流
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
      ssh_root_path = Pathname.new(ENV.fetch('SSH_KEY_PATH') { Rails.root.join('tmp', '.ssh').to_s })
      ssh_path = ssh_root_path.join('id_rsa')
      Net::SSH.start(server.address, server.username, port: server.port,
                                                      keys: [ssh_path.to_s], timeout: 10, non_interactive: true,
                                                      config: false, user_known_hosts_file: []) do |ssh|
        ssh.exec!("mkdir -p #{server.monitor_path}")
        response.live_push '连接成功'
      end
    rescue Timeout::Error
      response.live_error 'Timed out'
    rescue Errno::EHOSTUNREACH
      response.live_error 'Host unreachable'
    rescue Errno::ECONNREFUSED
      response.live_error 'Connection refused'
    rescue Errno::EALREADY
      response.live_error 'Connection refused(Operation already in progress)'
    rescue Net::SSH::AuthenticationFailed
      response.live_error 'Authentication failure'
    rescue StandardError => exception
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
      response.live_push '等待其他任务完成 ...'
      sleep 3
    end

    Rails.cache.write('local_shell_running', true)

    local_root_path = Rails.root.to_s

    FileUtils.cd(local_root_path)
    local_store_path = "#{local_root_path}/tmp/store/#{project.id}"
    FileUtils.mkdir_p(local_store_path)
    FileUtils.cd(local_store_path)

    begin
      do_checkout_project(project, response)
      response.live_push '检出完成'
    rescue StandardError => exception
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
    project = publisher.project

    return unless check_publisher_status(publisher, project, response)

    Rails.cache.write('local_shell_running', true)

    begin
      local_root_path = Rails.root.to_s
      FileUtils.cd(local_root_path)
      local_store_path = "#{local_root_path}/tmp/store/#{project.id}"
      FileUtils.mkdir_p(local_store_path)
      FileUtils.cd(local_store_path)

      do_checkout_project(project, response)

      response.live_push '代码检出完成 ...'

      response.live_push '准备文件 ...'
      tmp_store_path = "#{local_store_path}.tmp"
      do_add_del_file(project, tmp_store_path, local_store_path)

      response.live_push '写入附加文件 ...'
      FileUtils.cd(tmp_store_path)
      write_extend_file(project, tmp_store_path)

      response.live_push '文件准备完成 ...'
      response.live_push '共发布到' + project.publisher_servers.size.to_s + '台服务器 ...'

      ssh_root_path = Pathname.new(ENV.fetch('SSH_KEY_PATH') { Rails.root.join('tmp', '.ssh').to_s })
      ssh_path = ssh_root_path.join('id_rsa')
      project.publisher_servers.each do |publisher_server|
        Net::SSH.start(publisher_server.server.address,
                       publisher_server.server.username,
                       port: publisher_server.server.port,
                       keys: [ssh_path.to_s], timeout: 10, non_interactive: true,
                       config: false, user_known_hosts_file: []) do |ssh|
          ssh.exec!("mkdir -p #{publisher_server.server.monitor_path}")
          response.live_push "‘#{publisher_server.server.address}:#{publisher_server.server.port}‘连接成功 ..."
        end
      end

      project.publisher_servers.each do |publisher_server|
        server = publisher_server.server
        response.live_push "开始部署到‘#{server.address}:#{server.port}‘ ..."

        Net::SFTP.start(server.address, server.username, port: server.port, password: server.password,
                                                         keys: [ssh_path.to_s], timeout: 10, non_interactive: true,
                                                         config: false, user_known_hosts_file: []) do |sftp|

          publish_to_server_pre(project, response, sftp, server)

          publish_to_server_backup(project, response, sftp, publisher)

          response.live_push '正在发布文件 ...'
          sftp.upload!(tmp_store_path, project.target_deploy_path)

          publish_to_server_post(project, response, sftp, server)
        end
      end

      publisher.published = true
      publisher.publish_time = Time.now.utc
      publisher.save

      response.live_push '部署完成'

      Log.create_log(@current_user.id, 'Publish', "#{publisher.title}:#{project.title}")
    rescue Timeout::Error
      response.live_error 'Timed out'
    rescue Errno::EHOSTUNREACH
      response.live_error 'Host unreachable'
    rescue Errno::ECONNREFUSED
      response.live_error 'Connection refused'
    rescue Net::SSH::AuthenticationFailed
      response.live_error 'Authentication failure'
    rescue Net::SFTP::StatusException => exception
      response.live_error "StatusException: #{exception.description};#{exception.response}"
    rescue StandardError => exception
      response.live_error exception
    end

    response.live_close
    Rails.cache.write('local_shell_running', false)
  ensure
    response.stream.close
    Rails.cache.write('local_shell_running', false)
  end

  private

  def do_shell(command_str)
    return if command_str.nil? || command_str == ''

    IO.popen(command_str) do |process|
      until process.eof?
        line = process.gets
        response.live_push line
      end
    end
  end

  def do_shell_without_put(command_str)
    return if command_str.nil? || command_str == ''

    IO.popen(command_str) do |process|
      until process.eof?
        line = process.gets
        Rails.logger.info line
      end
    end
  end

  def do_checkout_project(project, response)
    response.live_push '执行检出前置任务 ...'
    project.task_pre_checkout.split(';').each do |command|
      do_shell(command)
    end

    if Dir.exist?('.git')
      git = Git.open('.')
      if project.git_url == git.remotes.first.url

        response.live_push '更新本地代码 ...'
        git.fetch
        git.reset_hard
        git.clean(force: true, d: true)
        git.pull

      else

        response.live_push '删除旧仓库 ...'

        FileUtils.cd('..')
        FileUtils.rm_rf(local_store_path)
        FileUtils.mkdir_p(local_store_path)
        FileUtils.cd(local_store_path)

        response.live_push '克隆代码库 ...'
        git = Git.clone(project.git_url, '.')

      end

    else

      response.live_push '克隆代码库 ...'
      git = Git.clone(project.git_url, '.')

    end

    response.live_push "检出'#{project.git_version}'版本 ..."
    git.checkout project.git_version

    do_shell 'git submodule init;git submodule update'

    response.live_push '执行检出后置任务 ...'
    project.task_post_checkout.split(';').each do |command|
      do_shell(command)
    end
  end

  def check_publisher_status(publisher, project, response)
    if publisher.published
      response.live_push '该发布已经完成'
      response.live_close
      false
    elsif @current_user.level <= 100 && project.env_level.zero?
      response.live_push '你没有权限'
      response.live_close
      false
    elsif Rails.cache.exist?('local_shell_running') && Rails.cache.read('local_shell_running')
      response.live_push '等待其他任务完成 ...'
      response.live_close
      false
    end
    true
  end

  def do_add_del_file(project, tmp_store_path, local_store_path)
    FileUtils.rm_rf(tmp_store_path) if Dir.exist?(tmp_store_path)
    FileUtils.mkdir_p(tmp_store_path)

    if project.file_included.nil? || project.file_included == ''
      excludes = project.file_excludable.split(';')
      Find.find(local_store_path) do |path|
        next if path == local_store_path

        real_path = path.gsub(local_store_path, '')
        is_mv = do_add_del_file_check_excludable(excludes, real_path)
        do_add_del_file_mv(path, is_mv, "#{tmp_store_path}#{real_path}")
      end
    else
      includes = project.file_included.split(';')
      Find.find(local_store_path) do |path|
        next if path == local_store_path

        real_path = path.gsub(local_store_path, '')
        is_mv = do_add_del_file_check_included(includes, real_path)
        do_add_del_file_mv(path, is_mv, "#{tmp_store_path}#{real_path}")
      end
    end
  end

  def do_add_del_file_check_excludable(files, real_path)
    is_mv = true
    files.each do |file|
      is_mv = false if real_path.start_with? "/#{file}"
    end
    is_mv = false if real_path.start_with? '/.git'
    is_mv
  end

  def do_add_del_file_check_included(files, real_path)
    is_mv = false
    files.each do |file|
      is_mv = true if real_path.start_with? "/#{file}"
    end
    is_mv
  end

  def do_add_del_file_mv(path, is_mv, new_path)
    if File.directory?(path) && is_mv
      FileUtils.mkdir_p(new_path)
    elsif is_mv
      FileUtils.cp_r(path, new_path)
    end
  end

  def write_extend_file(project, tmp_store_path)
    FileUtils.cd(tmp_store_path)
    project_extend_files = project.project_extend_files
    project_extend_files.each do |project_extend_file|
      tname = project_extend_file.filename
      tarr = tname.split('/')
      if tarr.size > 1
        tarr.delete_at(tarr.size - 1)
        project_extend_file_path = tarr.join('/')
        FileUtils.mkdir_p(project_extend_file_path)
      end
      a_file = File.new(project_extend_file.filename, 'w+')
      a_file.syswrite(project_extend_file.content)
      a_file.close
    end
  end

  def publish_to_server_pre(project, response, sftp, server)
    response.live_push '执行部署前置任务 ...'

    project.task_pre_deploy.split(';').each do |command|
      command_str = "source #{server.rc_file_path};cd #{project.target_deploy_path};#{command}"
      sftp.session.exec!(command_str) do |_channel, _stream, data|
        response.live_push data
      end
    end
  end

  def publish_to_server_post(project, response, sftp, server)
    response.live_push '执行部署后置任务 ...'
    return if project.task_post_deploy.nil? || project.task_post_deploy == ''

    project.task_post_deploy.split(';').each do |command|
      command_str = "source #{server.rc_file_path};cd #{project.target_deploy_path};#{command}"
      sftp.session.exec!(command_str) do |_channel, _stream, data|
        response.live_push data
      end
    end
  end

  def publish_to_server_backup(project, response, sftp, publisher)
    response.live_push '准备备份文件 ...'
    current_backup = "#{project.target_backup_path}/#{publisher.id}"
    sftp.session.exec!("mkdir -p #{current_backup}")
    backups = project.publisher_ids.max(5)
    sftp.dir.foreach(project.target_backup_path) do |entry|
      if entry.name != '.' && entry.name != '..'
        is_del = true
        backups.each do |id|
          is_del = false if entry.name == id.to_s
        end
        sftp.session.exec!("rm -rf #{project.target_backup_path}/#{entry.name}") if is_del
      end
    end
    sftp.session.exec!("mkdir -p #{current_backup}")
    sftp.session.exec!("rm -rf #{project.target_deploy_path}")
    sftp.session.exec!("ln -sf #{current_backup} #{project.target_deploy_path}")
  end
end
