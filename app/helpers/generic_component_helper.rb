module GenericComponentHelper
  def delete_link_for(item)
    name = item.respond_to?('name') ? item.name : _('this item')
    link_to('Delete', {:action => 'delete', :id => item.id}, 
            :method => 'post', 
            :confirm => _("Are you sure you want to remove %s?") % name)
  end

  def edit_link_for(item)
    link_to('Edit', :action => 'edit', :id => item.id)
  end
end
