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
      [ link_to(edit_icon, :action => 'edit', :id => term.id),
        link_to(delete_icon, {:action => 'delete', :id => term.id},
                :method => 'post', 
                :confirm => _("Are you sure you want to remove %s?") %
                term.ipaddr)].join(' ')
    ]
  end

  def params_for_terminal(term)    
    return _('Please save the terminal before specifying any parameters') if 
      term.new_record?

    t = HtmlTable.new
    t.head('Name', 'Value')
    term.term_params.sort_by {|tp| tp.name}.each do |tp|
      t << [ text_field_tag("tp[#{tp.id}][name]", tp.name),
             text_field_tag("tp[#{tp.id}][value]", tp.value)
           ]
    end
    t << [ text_field_tag('tp[new][name]'), text_field_tag('tp[new][value]') ]

    return _('Leave any terminal parameter blank to delete it; create a ' +
             'new one by specifying its name as well.') << t.to_s
  end
end
