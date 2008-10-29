class TerminalsController < ApplicationController
  class PerIPPermissionDenied < Exception; end
  rescue_from PerIPPermissionDenied do |err| 
    render :text => "ERROR: #{err}\n", :status => :forbidden
  end

  def index
    redirect_to :action => 'list'
  end

  # Generates the configuration command for a remote terminal to be
  # set up, based on its IP address. This action does not require any
  # authentication.
  def config
    client_ip = request.remote_ip
    term = Terminal.find_by_ipaddr(client_ip) or
      raise PerIPPermissionDenied, _('Unknown terminal %s') % client_ip
    render :text => "#{term.client_command_line}\n"
  end

  def list
    @terminals = Terminal.paginate(:order => 'id', :page => params[:page])
  end
end
