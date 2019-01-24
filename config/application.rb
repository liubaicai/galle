require_relative 'boot'

require 'rails/all'

require 'find'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Galle
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end

ssh_path = Rails.root.join('tmp', '.ssh', 'id_rsa')
unless File.exist? ssh_path
  k = SSHKey.generate(
      type:       "RSA",
      bits:       1024,
      comment:    "Galle",
      passphrase: "galls"
  )
  privateKey = k.private_key
  publicKey = k.public_key
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
  File.chmod(0400,"#{private_key_path}")
  File.chmod(0400,"#{public_key_path}")
end
ENV["GIT_SSH_COMMAND"]="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{ssh_path}"