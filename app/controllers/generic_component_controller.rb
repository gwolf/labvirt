# #LaboratoriesController, #TerminalsController, #ProfilesController,
# #DiskDevsController (and potentially others) are very similar - so,
# for DRYness sake, abstract them all into this generic controller.
#
# This controller provides the basic, traditional CRUD actions (#list,
# #new, #edit, #delete). No #show is provided (as #edit is
# enough). Besides said actions, the #GenericComponentHelper provides
# hooks from which any class inheriting from this one can add elements
# to given views. Those hooks will be triggered if a partial with a
# suitable name is found - i.e. for adding information at the end of a
# #TerminalsController' edit/new form, you can just drop a
# _form_end.haml file in app/views/terminals. The provided hooks are
# 
#  * In #list: before_list, after_list, list_head_extra_col,
#    list_extra_col 
#  * In #edit: before_form, after_form, form_begin,
#    form_end
#
# The list_extra_col hook in #list has a local 'item' variable
# available, containing the item for the current row. All the other
# partials have no special variables set.
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
    render :action => 'generic/list'
  end

  def new
    @item = @model.new
    @pg_title = @labels[:new_title]
    render :action => 'generic/edit'
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

      if request.post?
        @item.transaction do
          @item.update_attributes!(params[:item])

          flash[:notice] = _'The specified settings were successfully updated'
          redirect_to :action => 'list'
          return true
        end
      end

    rescue ActiveRecord::RecordNotFound
      redirect_to :action => 'list'
      flash[:error] = _'Specified item does not exist'
      return false
    rescue ActiveRecord::RecordInvalid => err
      flash[:error] = _('Error saving requested data: ') +
        err.record.errors.full_messages.join('<br/>')
    end
    render :action => 'generic/edit'
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
