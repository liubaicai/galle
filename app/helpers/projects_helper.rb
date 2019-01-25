module ProjectsHelper

    def check_is_in_project_servers(server, project_servers)
        project_servers.each do |s|
            if s.server_id==server.id
                return true
            end
        end
        return false
    end

end