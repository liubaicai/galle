# frozen_string_literal: true

# help
module ProjectsHelper
  def check_is_in_project_servers(server, project_servers)
    project_servers.each do |s|
      return true if s.server_id == server.id
    end
    false
  end
end
