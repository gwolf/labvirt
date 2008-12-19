class LaboratoriesController < ApplicationController
  def list
    @labs = Laboratory.find(:all)
  end

  def new
    @lab = Laboratory.new
    return true unless request.post?
    begin
      @lab.update_attributes!(params[:laboratory])
      flash[:notice] = _'The laboratory was successfully created'
      redirect_to :action => 'list'
    rescue ActiveRecord::RecordInvalid => err
      flash[:error] = _('Error registering laboratory: ') +
        err.record.errors.full_messages.join('<br/>')
    end
  end
end
