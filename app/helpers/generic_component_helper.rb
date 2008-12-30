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

  def list_head
    (@fields[:list]).map { |fld|
      @sortable.has_key?(fld) ? link_to(fld, :sort_by => fld) : fld
    }.map {|col| "<th>#{col}</th>"}.join "\n"
  end

  def list_row(item)
    @fields[:list].map { |fld| "<td>#{item.send(fld)}</td>" }.join "\n"
  end

  # Optional partials that can be called from the relevant actions
  # (see #GenericComponentController for further details)
  %w(before_list after_list before_form form_begin form_end
     after_form).each do |part|
    eval <<-END_SRC
      def #{part}
        begin
          render :partial => '#{part}'
        rescue ActionView::MissingTemplate
        end
      end
    END_SRC
  end
end
