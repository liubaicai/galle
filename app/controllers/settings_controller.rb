class SettingsController < ApplicationController

    def sshkey
        ssh_root_path = Pathname.new( ENV.fetch("SSHKey") { Rails.root.join('tmp', '.ssh').to_s })
        ssh_path = ssh_root_path.join('id_rsa.pub')
        @public_key = ''
        if File.exist? ssh_path
            @public_key = File.read(ssh_path)
        end
    end

    def sshkey_post
        if @current_user.level < 100
            render plain: '你没有权限'
        else
            k = SSHKey.generate(
                comment: "Galle",
                passphrase: "galle"
            )
            privateKey = k.private_key
            publicKey = k.ssh_public_key
            ssh_path = Pathname.new( ENV.fetch("SSHKey") { Rails.root.join('tmp', '.ssh').to_s })
            FileUtils.mkdir_p ssh_path.to_s
            private_key_path = ssh_path.join('id_rsa')
            public_key_path = ssh_path.join('id_rsa.pub')
            File.delete private_key_path if File.exist? private_key_path
            File.delete public_key_path if File.exist? public_key_path
            privateFile = File.new(private_key_path, 'w+')
            privateFile.write(privateKey)
            privateFile.close
            publicFile = File.new(public_key_path, 'w+')
            publicFile.write(publicKey)
            publicFile.close
            File.chmod(0600, "#{private_key_path}")
            File.chmod(0600, "#{public_key_path}")

            Log.create_log(@current_user.id, 'ReGenerateSSHKey', "")

            @public_key = publicKey
            render "sshkey"
        end
    end

end
