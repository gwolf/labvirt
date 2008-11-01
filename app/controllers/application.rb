# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'pseudo_gettext'

class ApplicationController < ActionController::Base
  class AuthenticationRequired < Exception #:nodoc:
  end
  rescue_from AuthenticationRequired do |err|
    redirect_to :controller => 'login'
  end

  init_gettext 'labvirt'
  before_filter :ck_user
  before_filter :gen_menu
  before_filter :header_and_footer
  before_filter :set_lang

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => '6f788bd1d56d19783a1a3e00e1d2d51b'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :passwd

  protected
  # Is the requested action public? (this means, can it be allowed
  # with no user validation?)
  def is_public_action?(ctrl, action)
    public_actions = { :terminals => [:config],
      :login => [:login, :logout] }

    return true if public_actions.has_key?(ctrl) and
      public_actions[ctrl].include? action
  end

  # Validates we have a valid system user, and instantiates the
  # @sysuser variable. Raises an AuthenticationRequired exception if
  # no valid user is received and the requested action is not public.
  def ck_user
    ctrl = request.path_parameters['controller'].to_sym
    action = request.path_parameters['action'].to_sym
    flash[:warnings] = []


    # Are we handling an already authenticated system user?
    if session[:sysuser_id]
      @sysuser = Sysuser.find_by_id(session[:sysuser_id])
      return true if @sysuser
    end

    # Is the user requesting a public action?
    raise AuthenticationRequired unless is_public_action?(ctrl, action)

    # Ok, this is a public area - go ahead
    return true
  end

  # Specifies the GetText language environment
  def set_lang
    return true unless lang = params[:lang]
    cookies[:lang] = {:value => lang, :expires => Time.now+1.day, :path => '/'}
  end

  # Sets header and footer variables
  def header_and_footer
    @title = _'Labvirt'
    @footer = _'Something nice should go down here...'
  end

  # Generates the user menu tree
  def gen_menu
    @menu = MenuTree.new

    return unless @sysuser

    ['laboratories', 'terminals'].each do |ctrl|
      @menu << MenuItem.new(_(ctrl.camelcase), 
                            url_for(:action => 'list', :controller => ctrl))
    end

    if @sysuser.admin?
      @menu << MenuItem.new(_('User management'),
                            url_for(:action => 'list', 
                                    :controller => 'sysusers'))
    end
  end
end
