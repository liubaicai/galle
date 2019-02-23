# frozen_string_literal: true

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
  # 主程序
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

ssh_path = Pathname.new(ENV.fetch('SSH_KEY_PATH') { Rails.root.join('tmp', '.ssh').to_s })
private_key_path = ssh_path.join('id_rsa')
public_key_path = ssh_path.join('id_rsa.pub')
unless File.exist? private_key_path
  k = SSHKey.generate(
    comment: 'Galle',
    passphrase: 'galle'
  )
  private_key = k.private_key
  public_key = k.ssh_public_key
  FileUtils.mkdir_p ssh_path.to_s
  private_file = File.new(private_key_path, 'w+')
  private_file.write(private_key)
  private_file.close
  public_file = File.new(public_key_path, 'w+')
  public_file.write(public_key)
  public_file.close
end
File.chmod(0o600, private_key_path.to_s)
File.chmod(0o600, public_key_path.to_s)

# win10的wsl子系统，chmod权限bug，导致项目目录里的key文件不符合git的权限要求，因此在development环境采用用户默认key
ENV['GIT_SSH_COMMAND'] = if Rails.env.production?
                           "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{private_key_path}"
                         else
                           'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
                         end
