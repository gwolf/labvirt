class DiskDevsController < GenericComponentController

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
