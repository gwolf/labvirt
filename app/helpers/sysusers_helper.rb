module SysusersHelper
  def row_for_listing(sysuser)
    [ sysuser.id,
      sysuser.login,
      sysuser.name,
      sysuser.admin? ? _('Yes') : _('No'),
      [ link_to(_('Edit'), :action => 'edit', :id => sysuser.id),
        link_to_unless(@sysuser == sysuser, _('Delete'), 
                       {:action => 'delete', :id => sysuser.id},
                       :method => 'post', 
                       :confirm => _("Are you sure you want to remove %s?") %
                       sysuser.name)].join(' ')
    ]
  end
end
