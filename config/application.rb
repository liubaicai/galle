require_relative 'boot'

# require 'rails/all'

require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
# require 'action_mailer/railtie'
# require 'active_job/railtie'
# require 'action_cable/engine'
# require 'active_storage/engine'
# require 'rails/test_unit/railtie'
# require 'sprockets/railtie'

require 'find'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Railtie.load

module Galle
    class Application < Rails::Application
        # Initialize configuration defaults for originally generated Rails version.
        config.load_defaults 5.2

        # config.assets.enabled = false

        # Settings in config/environments/* take precedence over those specified here.
        # Application configuration can go into files in config/initializers
        # -- all .rb files in that directory are automatically loaded after loading
        # the framework and any gems in your application.
    end
end

ssh_path = Pathname.new(ENV.fetch("SSH_KEY_PATH") {Rails.root.join('tmp', '.ssh').to_s})
private_key_path = ssh_path.join('id_rsa')
public_key_path = ssh_path.join('id_rsa.pub')
unless File.exist? private_key_path
    k = SSHKey.generate(
        comment: "Galle",
        passphrase: "galle"
    )
    privateKey = k.private_key
    publicKey = k.ssh_public_key
    FileUtils.mkdir_p ssh_path.to_s
    privateFile = File.new(private_key_path, 'w+')
    privateFile.write(privateKey)
    privateFile.close
    publicFile = File.new(public_key_path, 'w+')
    publicFile.write(publicKey)
    publicFile.close
end
File.chmod(0600, "#{private_key_path}")
File.chmod(0600, "#{public_key_path}")

# win10的wsl子系统，chmod权限bug，导致项目目录里的key文件不符合git的权限要求，因此在development环境采用用户默认key
if Rails.env.production?
    ENV["GIT_SSH_COMMAND"] = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{private_key_path}"
else
    ENV["GIT_SSH_COMMAND"] = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
end
