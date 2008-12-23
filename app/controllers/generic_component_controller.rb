class GenericComponentController < ApplicationController
  before_filter :setup_ctrl

  def list
    session[@model_name] ||= @sortable[0]
    session[@model_name] = params[:sort_by].to_s if
      params.has_key?(:sort_by) and
      @sortable.keys.include?(params[:sort_by].to_s)

    @items = @model.paginate(:order => @sortable[session[@model_name]], 
                             :include => @list_include,
                             :page => params[:page])
  end

  def new
    @item = @model.new
    @pg_title = @labels[:new_title]
    render :action => 'edit'
    return true unless request.post?
    begin
      @item.update_attributes!(params[:item])
      flash[:notice] = @labels[:create_ok]
      redirect_to :action => 'list'
    rescue ActiveRecord::RecordInvalid => err
      flash[:error] = @labels[:create_error] +
        err.record.errors.full_messages.join('<br/>')
    end
  end

  def edit
    begin
      @item = @model.find(params[:id])
      @pg_title = @labels[:edit_title]
      return true unless request.post?

      @item.transaction do
        @item.update_attributes(params[:item])

        flash[:notice] = _'The specified settings were successfully updated'
        redirect_to :action => 'list'
      end

    rescue ActiveRecord::RecordNotFound
      redirect_to :action => 'list'
      flash[:error] = _'Specified item does not exist'
      return false
    rescue ActiveRecord::RecordInvalid => err
      flash[:error] = _('Error saving requested data: ') +
        err.record.errors.full_messages.join('<br/>')
    end
  end

  def delete
    redirect_to :action => 'list'
    return true unless request.post?
    begin
      @model.find(params[:id]).destroy
      flash[:notice] = _'The terminal has been successfully deleted'
    rescue ActiveRecord::RecordInvalid => err
      flash[:error] = _('Could not delete requested terminal: ') +
        err.record.errors.full_messages.join('<br/>')
    end
  end

  private
  def setup_ctrl
    raise RuntimeError, _('This controller should not be directly invoked')
  end
end
