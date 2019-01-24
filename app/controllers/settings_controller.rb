class SettingsController < ApplicationController

  def sshkey
    ssh_path = Rails.root.join('tmp', '.ssh', 'id_rsa.pub')
    @public_key = ''
    if File.exist? ssh_path
      @public_key = File.read(ssh_path)
    end
  end

  def sshkey_post
    k = SSHKey.generate(
        comment:    "Galle",
        passphrase: "galle"
    )
    privateKey = k.private_key
    publicKey = k.ssh_public_key
    ssh_path = Rails.root.join('tmp', '.ssh')
    FileUtils.mkdir_p ssh_path.to_s
    private_key_path = ssh_path.join('id_rsa')
    public_key_path = ssh_path.join('id_rsa.pub')
    File.delete private_key_path if File.exist? private_key_path
    File.delete public_key_path if File.exist? public_key_path
    privateFile = File.new(private_key_path,'w+')
    privateFile.write(privateKey)
    privateFile.close
    publicFile = File.new(public_key_path,'w+')
    publicFile.write(publicKey)
    publicFile.close
    File.chmod(0600,"#{private_key_path}")
    File.chmod(0600,"#{public_key_path}")

    @public_key = publicKey
    render "sshkey"
  end

end
