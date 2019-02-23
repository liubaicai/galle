# frozen_string_literal: true

# 设置页
class SettingsController < ApplicationController
  def sshkey
    ssh_root_path = Pathname.new(ENV.fetch('SSH_KEY_PATH') { Rails.root.join('tmp', '.ssh').to_s })
    ssh_path = ssh_root_path.join('id_rsa.pub')
    @public_key = ''
    @public_key = File.read(ssh_path) if File.exist? ssh_path
  end

  def sshkey_post
    if @current_user.level < 100
      render plain: '你没有权限'
    else
      k = SSHKey.generate(
        comment: 'Galle',
        passphrase: 'galle'
      )
      private_key = k.private_key
      public_key = k.ssh_public_key
      ssh_path = Pathname.new(ENV.fetch('SSH_KEY_PATH') { Rails.root.join('tmp', '.ssh').to_s })
      FileUtils.mkdir_p ssh_path.to_s
      private_key_path = ssh_path.join('id_rsa')
      public_key_path = ssh_path.join('id_rsa.pub')
      File.delete private_key_path if File.exist? private_key_path
      File.delete public_key_path if File.exist? public_key_path
      private_file = File.new(private_key_path, 'w+')
      private_file.write(private_key)
      private_file.close
      public_file = File.new(public_key_path, 'w+')
      public_file.write(public_key)
      public_file.close
      File.chmod(0o600, private_key_path.to_s)
      File.chmod(0o600, public_key_path.to_s)

      Log.create_log(@current_user.id, 'ReGenerateSSHKey', '')

      @public_key = publicKey
      render 'sshkey'
    end
  end
end
