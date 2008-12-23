class LaboratoriesController < GenericComponentController

  private
  def setup_ctrl
    @model = Laboratory
    @model_name = 'laboratory'
    @labels = {:create_ok => _('The laboratory was successfully created'),
      :create_error => _('Error registering laboratory'),
      :list_title => _('Laboratory list'),
      :new_title => _('Define a new laboratory'),
      :edit_title => _('Edit laboratory'),
    }
    @fields = {:list => %w(id name mac_base_addr max_instances start_instances),
      :edit => %w(name descr mac_base_addr max_instances start_instances)}
    @sortable = {'id' => 'laboratories.id', 'name' => 'name', 
      'mac_base_addr' => 'mac_base_addr'}
  end
end
