class ProfilesController < GenericComponentController

  private
  def setup_ctrl
    @model = Profile
    @model_name = 'profile'
    @labels = {:create_ok => _('The profile was successfully created'),
      :create_error => _('Error registering profile'),
      :list_title => _('Profile list'),
      :new_title => _('Define a new profile'),
      :edit_title => _('Edit profile')
    }
    @fields = {:list => %w(id name laboratory active maint_mode ram),
      :edit => %w(name descr laboratory_id position ram extra_params active 
                  maint_mode net_iface_id)}
    @sortable = {'id' => 'profiles.id', 'name' => 'name',
      'laboratory' => 'laboratories.name', 'active' => 'active, profiles.id',
      'maint_mode' => 'maint_mode, profiles.id'}
    @list_include = 'laboratory'
  end
end
