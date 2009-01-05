class TermClassesController < GenericComponentController
  def setup_ctrl
    @model = TermClass
    @labels = {:create_ok => _('The terminal class has been '+
                               'successfully created'),
      :create_error => _('Error saving requested data: '),
      :list_title => _('Terminal classes listing'),
      :new_title => _('Define new terminal class')
    }
    @fields = {:list => %w(id name path terminal_ids),
      :edit => %w(id name path params)}
    @list_include = 'terminals'
    @sortable = {'id' => 'id', 'name' => 'name'}
  end
end
