class DiskDevsController < GenericComponentController
  def duplicate
    begin
      orig = DiskDev.find(params[:id])
      # This can potentially take much longer than what we are willing
      # to wait with a Web client expecting an answer... Forking is
      # the only sane way. Later on, maybe adding a AJAX observer,
      # monitoring the cloned device?
#      fork { orig.copy }
      orig.copy 
    rescue ActiveRecord::RecordNotFound
    end

    redirect_to :action => 'list'
  end

  def delete
    redirect_to :action => 'list'
    return true unless request.post?
    begin
      DiskDev.find(params[:id]).destroy
      flash[:notice] = _'The device has been successfully deleted'
    rescue ActiveRecord::RecordInvalid => err
      flash[:error] = _('Could not delete requested terminal: ') +
        err.record.errors.full_messages.join('<br/>')
    end
  end

  private
  def setup_ctrl
    @model = DiskDev
    @model_name = 'disk_dev'
    @labels = {:create_ok => _('The device was successfully created'),
      :create_error => _('Error registering device'),
      :list_title => _('Disk device list'),
      :new_title => _('Define a new disk device'),
      :edit_title => _('Edit disk device')
    }
    @fields = {:list => %w(id name profile filename disk_type media_type),
      :edit => %w(name filename disk_type_id media_type_id profile_id 
                  position)}
    @sortable = {'id' => 'disk_devs.id', 'name' => 'disk_devs.name', 
    'profile' => 'profiles.id', 'filename' => 'filename'}
    @list_include = [:profile, :media_type, :disk_type]
  end
end
