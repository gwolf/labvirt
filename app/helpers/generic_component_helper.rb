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
    @fields[:list].map do |fld|
      value = item.send(fld)
      case fld
      when 'laboratory'
        link_to_laboratory(value)
      when 'profile'
        link_to_profile(value)
      when 'media_type'
        link_to_media_type(value)
      when 'disk_type'
        link_to_disk_type(value)
      when 'term_class'
        link_to_term_class(value)
      else
        value
      end
    end.map {|col| "<td>#{col}</td>"}.join("\n")
  end

  %w(laboratory profile disk_type media_type term_class).each do |dest|
    eval <<-END_SRC
      def link_to_#{dest}(item)
        link_to(item.name, :controller => '#{dest.pluralize}',
                :action => 'edit', :id => item.id)
      end
    END_SRC
  end

  # Optional partials that can be called from the relevant actions
  # (see #GenericComponentController for further details)
  %w(before_list after_list before_form form_begin form_end
     after_form list_head_extra_col).each do |part|
    eval <<-END_SRC
      def #{part}
        begin
          render :partial => '#{part}'
        rescue ActionView::MissingTemplate
        end
      end
    END_SRC
  end
  %w(list_extra_col).each do |part|
    eval <<-END_SRC
      def #{part}(item)
        begin
          render :partial => '#{part}', :locals => {:item => item}
        rescue ActionView::MissingTemplate
        end
      end
    END_SRC
  end
end
