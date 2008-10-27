# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'pseudo_gettext'

class ApplicationController < ActionController::Base
  init_gettext 'labvirt'
  before_filter :ck_user
  before_filter :header_and_footer

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => '6f788bd1d56d19783a1a3e00e1d2d51b'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :passwd

  protected
  def is_public_action?(ctrl, action)
    public_actions = { :terminal => [:config],
      :login => [:login, :logout] }

    return true if public_actions.has_key?(ctrl) and
      public_actions[ctrl].include? action
  end

  def ck_user
    ctrl = request.path_parameters['controller'].to_sym
    action = request.path_parameters['action'].to_sym
    flash[:warnings] = []


    # Are we handling an already authenticated system user?
    if session[:sysuser_id]
      @sysuser = Sysuser.find_by_id(session[:sysuser_id])
      return true if @sysuser
    end

    # Is the user requesting a nonpublic area?
    if !is_public_action?(ctrl, action)
      # Request a login
      redirect_to :controller => 'login', :action => 'login'
      return false
    end

    # Ok, this is a public area - go ahead
    return true
  end

  def header_and_footer
    @title = 'Labvirt'
    @footer = 'Something nice should go down here...'
  end
end
