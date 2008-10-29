module TerminalsHelper
  def terminals_listing(terms)
    t = HtmlTable.new
    t.head(link_to(_('ID'), :sort_by => 'id'),
           link_to(_('IP address'), :sort_by => 'ip'),
           link_to(_('Server address'), :sort_by => 'server'),
           link_to(_('Terminal class'), :sort_by => 'class'),
           _('Action'))
    terms.each { |term| t << row_for_term_list(term) }
    t.to_s
  end

  def row_for_term_list(term)
    [ term.id, term.ipaddr, term.serveraddr, term.term_class.name, 
      [ link_to(_('Edit'), :action => 'edit', :id => term.id),
        link_to( _('Delete'), {:action => 'delete', :id => term.id},
                 :method => 'post', 
                 :confirm => _("Are you sure you want to remove %s?") %
                 term.ipaddr)].join(' ')
    ]
  end
end
