class TerminalController < ApplicationController
  class PermissionDenied < Exception; end

  rescue_from PermissionDenied do |err| 
    render :text => "ERROR: #{err}\n", :status => :forbidden
  end

  def config
    client_ip = request.remote_ip
    term = Terminal.find_by_ipaddr(client_ip) or
      raise PermissionDenied, _('Unknown terminal %s') % client_ip
    render :text => "#{term.client_command_line}\n"
  end
end
