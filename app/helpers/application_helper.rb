# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  ######################################################################
  # Layout-related elements
  def show_flash
    flash.map do |level, message|
      message = message.join("<br/>") if message.is_a? Array
      flash.discard(level)
      '<div id="flash-%s">%s</div>' % [level, message]
    end
  end

  def login_data
    return '' unless @sysuser
    '<div id="logindata">%s (%s) - %s</div>' % 
      [h(@sysuser.login), h(@sysuser.name), 
       link_to(_('Log out'), {:controller => 'login', :action => 'logout'})]
  end
end
