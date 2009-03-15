class TerminalsController < GenericComponentController
  class PerIPPermissionDenied < Exception #:nodoc:
  end
  rescue_from PerIPPermissionDenied do |err| 
    render :text => _('ERROR: %s\n') % err, :status => :forbidden
  end


  def set_term_param
    begin
      term = Terminal.find(params[:id])
      tp = term.term_param(params[:name]) || 
        TermParam.new(:terminal => term, :name => params[:name])
      tp.value = params[:value]
      tp.save!
      render_text tp.value
    rescue ActiveRecord::RecordNotFound
      # This is called via AJAX - no real way to easily notify about
      # the problem when saving. So, in case of errors... just send
      # some asterisks? (check on this back later)
      render_text '****'
    end
  end

  def delete_term_param
    raise Exception, params.to_yaml
  end
###### AGREGAR A EDICIÓN
#         # This is suboptimal; however, I expect terminal editions to
#         # be infrequent enough for this not to be an issue. In any
#         # case, this is the spot to optimize if needed.
#         # 
#         # We are receiving the current IDs from the form - Just ignore them,
#         # as they will be recreated.
#         @terminal.term_params.map do |tp| 
#           tp.destroy or raise ActiveRecord::RecordInvalid, tp
#         end

#         params[:tp].select {|id, tp| !tp[:name].empty? and 
#           !tp[:value].empty?}.each do |id, par_tp|
#           tp = TermParam.new(:name => par_tp[:name], 
#                              :value => par_tp[:value], 
#                              :terminal => @terminal)
#           tp.save or raise ActiveRecord::RecordInvalid, tp
#         end

#         flash[:notice] = _'The terminal settings have been successfully updated'
#         redirect_to :action => 'list'
#       end

  # Generates the configuration command for a remote terminal to be
  # set up, based on its IP address. This action does not require any
  # authentication.
  def config
    client_ip = request.remote_ip
    term = Terminal.find_by_termid(client_ip) or
      raise PerIPPermissionDenied, _('Unknown terminal %s') % client_ip
    render :text => "#{term.client_command_line}\n"
  end

  private
  def setup_ctrl
    @model = Terminal
    @labels = {:create_ok => _('The terminal has been successfully created'),
      :create_error => _('Error saving requested data: '),
      :list_title => _('Terminals listing'),
      :new_title => _('Define a new terminal')}
    @fields = {:list => %w(id termid serveraddr term_class),
      :edit => %w(id termid serveraddr term_class_id)}
    @list_include = 'term_class'
    @sortable = { :id => 'terminals.id', :ip => 'termid', 
      :server => 'serveraddr', :class => 'term_classes.name, terminals.id' }
  end
end
