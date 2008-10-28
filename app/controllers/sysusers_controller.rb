class SysusersController < ApplicationController
  before_filter :ck_admin
  before_filter :get_user, :except => [:list, :new]

  def list
    @users = Sysuser.find(:all, :order => :id)
  end

  def edit
    return true unless request.post?
    begin
      @user.update_attributes!(params[:sysuser])
      flash[:notice] = _'User data successfully updated'
      redirect_to :action => 'list'
    rescue ActiveRecord::RecordInvalid => err
      flash[:error] = _('Error saving requested data: ') + 
        err.record.errors.full_messages.join("<br/>")
    end
  end

  def delete
    redirect_to :action => 'list'
    return true unless request.post?
    if @user.destroy
      flash[:notice] = _"The user was successfully deleted"
    else
      flash[:error] = _("Could not destroy requested user: ") +
        @user.errors.full_messages
    end
  end

  def new
    @user = Sysuser.new
    return true unless request.post?
    begin
      @user.update_attributes!(params[:sysuser])
      flash[:notice] = _'The user was successfully created'
      redirect_to :action => 'list'
    rescue ActiveRecord::RecordInvalid => err
      flash[:error] = _('Error registering user: ') + 
        err.record.errors.full_messages.join("<br/>")
    end
  end

  protected
  def ck_admin
    raise AuthenticationRequired unless @sysuser.admin?
  end

  def get_user
    @user = Sysuser.find_by_id(params[:id])
    return true if @user
    redirect_to '/'
    return false
  end
end
