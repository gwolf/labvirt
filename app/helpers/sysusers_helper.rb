module SysusersHelper
  def sysusers_listing(users)
    t = HtmlTable.new
    t.head(_('ID'), _('Login'), _('Name'), _('Admin'), _('Action'))
    users.each { |u| t << row_for_user_list(u) }
    t.to_s
  end

  def row_for_user_list(sysuser)
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
