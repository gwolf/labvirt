class LoginController < ApplicationController
  before_filter :clear_session

  def login
    return true unless request.post?
    if @sysuser = Sysuser.ck_login(params[:login], params[:passwd])
      session[:sysuser_id] = @sysuser.id
      redirect_to '/'
      return true
    end
  end

  def logout
    redirect_to '/'
  end

  protected
  def clear_session
    session[:sysuser_id] = nil
  end
end
