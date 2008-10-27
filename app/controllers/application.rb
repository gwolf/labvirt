# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  before_filter :ck_user

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '6f788bd1d56d19783a1a3e00e1d2d51b'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  protected
  def public_actions
    { :terminal => [:config],
      :login => [:login, :logout] }
  end

  def ck_user
    ctrl = request.path_parameters['controller'].to_sym
    action = request.path_parameters['action'].to_sym

    if session[:sysuser_id]
      @sysuser = Sysuser.find_by_id(session[:sysuser_id])
      return true if @sysuser
    end

    return true if public_actions.keys.include?(ctrl) and 
      public_actions[ctrl].include?(action)

    redirect_to :controller => 'login', :action => 'login'
    return false
  end
end
