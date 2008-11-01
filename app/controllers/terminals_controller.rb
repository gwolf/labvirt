class TerminalsController < ApplicationController
  class PerIPPermissionDenied < Exception #:nodoc:
  end
  rescue_from PerIPPermissionDenied do |err| 
    render :text => "ERROR: #{err}\n", :status => :forbidden
  end

  def index
    redirect_to :action => 'list'
  end

  def list
    sortable = { :id => 'terminals.id', :ip => 'ipaddr', 
      :server => 'serveraddr', :class => 'term_classes.name, terminals.id' }

    session[:term_sort] ||= :id
    session[:term_sort] = params[:sort_by].to_sym if
      params.has_key?(:sort_by) and 
      sortable.keys.include?(params[:sort_by].to_sym)

    @terminals = Terminal.paginate(:order => sortable[session[:term_sort]], 
                                   :include => 'term_class',
                                   :page => params[:page])
  end

  def edit
    begin
      @terminal = Terminal.find(params[:id])
      return true unless request.post?

      @terminal.transaction do
        @terminal.update_attributes!(params[:terminal])

        # This is suboptimal; however, I expect terminal editions to
        # be infrequent enough for this not to be an issue. In any
        # case, this is the spot to optimize if needed.
        # 
        # We are receiving the current IDs from the form - Just ignore them,
        # as they will be recreated.
        @terminal.term_params.map do |tp| 
          tp.destroy or raise ActiveRecord::RecordInvalid, tp
        end

        params[:tp].select {|id, tp| !tp[:name].empty? and 
          !tp[:value].empty?}.each do |id, par_tp|
          tp = TermParam.new(:name => par_tp[:name], 
                             :value => par_tp[:value], 
                             :terminal => @terminal)
          tp.save or raise ActiveRecord::RecordInvalid, tp
        end

        flash[:notice] = _'The terminal settings have been successfully updated'
        redirect_to :action => 'list'
      end

    rescue ActiveRecord::RecordNotFound
      redirect_to :action => 'list'
      flash[:error] = _'Specified terminal does not exist'
      return false

    rescue ActiveRecord::RecordInvalid => err
      flash[:error] = _('Error saving requested data: ') +
        err.record.errors.full_messages.join('<br/>')
    end
  end

  def new
    begin
      @terminal = Terminal.new
      return true unless request.post?

      @terminal.update_attributes!(params[:terminal])
      flash[:notice] = _'The terminal has been successfully created'
      redirect_to :action => 'list'
    rescue ActiveRecord::RecordInvalid => err
      flash[:error] = _('Error saving requested data: ') +
        err.record.errors.full_messages.join('<br/>')
    end
  end

  def delete
    begin
      Terminal.find(params[:id]).destroy
      flash[:notice] = _'The terminal has been successfully deleted'
      redirect_to :action => 'list'
    rescue ActiveRecord::RecordInvalid => err
      flash[:error] = _('Could not delete requested terminal: ') +
        err.record.errors.full_messages.join('<br/>')
    end
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
end
