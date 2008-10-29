# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  ######################################################################
  # Layout-related elements
  def show_flash
    flash.map do |level, message|
      message = message.join("<br/>") if message.is_a? Array
      flash.discard(level)
      '<div id="flash-%s">%s</div>' % [level, message]
    end
  end

  def login_data
    return '' unless @sysuser
    '<div id="logindata">%s (%s) - %s</div>' % 
      [h(@sysuser.login), h(@sysuser.name), 
       link_to(_('Log out'), {:controller => 'login', :action => 'logout'})]
  end

  ############################################################
  # Icons and similar stuff
  def locale_links
    available_locales.map { |loc|
      '[%s]' % link_to_unless(normalized_locale == loc,
                              loc, :lang => loc)
    }.join(' ')
  end

  ############################################################
  # Form builders
  class LabvirtFormBuilder < ActionView::Helpers::FormBuilder
    include GetText
    include ActionView::Helpers::DateHelper

    (%w(date_field) +
     field_helpers - %w(check_box radio_button select 
                        hidden_field)).each do |fldtype|
      src = <<-END_SRC
        def #{fldtype}(field, options={})
          title = options.delete(:title) || label_for_field(@object, field)
          note = options.delete(:note)

          options[:size] ||= 60 if '#{fldtype}' == 'text_field'

          with_format(title, super(field, options), note)
        end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    def auto_field(field, options={})
      column = @object.class.columns.select { |col| 
        col.name.to_s == field.to_s}.first

      # To check for specially treated fields, we need the field to be
      # a string (not a symbol, as it is usually specified)
      field = field.to_s

      if !column
        if @object.respond_to?(field) and 
            @object.connection.tables.include?(field) and
            model = field.camelcase.singularize.constantize
          # HABTM relation
          return checkbox_group(field, model.find(:all), options)
        else
          # Don't know how to handle this
          raise(NoMethodError,
                _('Field %s not defined for %s') % [field, @object.class])
        end
      end

      # Specially treated fields
      if field == 'id'
        return info_row(field, options)

      elsif field == 'passwd'
        options[:value] = ''
        return password_field(field, options)

      elsif field =~ /_id$/ and column.type == :integer and
          model = table_from_field(field)
        # field_id and there is a corresponding table? Present the catalog.
        choices = model.qualified_collection_by_id
        return select(field, 
                      choices.map {|it| [_(it[0]), it[1]]},
                      {:include_blank => true})
      end

      # Generic fields, based on data type
      case column.type.to_sym
      when :string
        return text_field(field, options) 

      when :text
        options[:size] ||= '70x15'
        return text_area(field, options) 

      when :integer, :decimal, :float
        options[:class] ||= 'numeric'
        return text_field(field, options)

      when :boolean
        return radio_group(field, [[_('Yes'), true], [_('No'), false]], 
                           options)

      when :date
        return date_field(field, options)

      when :datetime
        return datetime_select(field, options)

      else
        # What is it, then? just report it...
        return info_row(field, options)

      end

    end

    def datetime_select(field, options={})
      title = options.delete(:title) || label_for_field(@object, field)
      note = options.delete(:note)
      options[:default] = @object.send(field)
      with_format(title, super(@object_name, field, 
                               {:default=>@object.send(field)}.merge(options)),
                  note)
    end

    def select(field, choices, options={})
      title = options.delete(:title) || label_for_field(@object, field)
      note = options.delete(:note)
      with_format(title, super(field, choices, options), note)
    end

    def radio_group(field, choices, options={})
      title = options.delete(:title) || label_for_field(@object, field)
      note = options.delete(:note)
      with_format(title, choices.map { |item|
                    radio_button(field, item[1]) << ' ' << item[0] },
                  note)
    end

    def checkbox_group(field, choices, options={})
      title = options.delete(:title) || label_for_field(@object, field)
      note = options.delete(:note)

      fieldname = "#{@object_name}[#{field.singularize}_ids][]"

      with_format(title,
                  choices.map { |item|
                    res = []
                    res << '<span'
                    res << "class=\"#{options[:class]}\"" if options[:class]
                    res << '><input type="checkbox"'
                    if @object.send(field.to_s.pluralize).include? item
                      res << 'checked="checked"'
                    end
                    res << "id=\"#{fieldname}\" name=\"#{fieldname}\" "
                    res << "value=\"#{item.id}\"> #{_ item.name}</span><br/>"
                    
                    res.join(' ') },
                  note)
    end

    def info_row(field, options={})
      title = options[:title] || label_for_field(@object, field)
      note = options[:note]

      with_format(title, info_elem(@object.send(field)), note)
    end

    private
    def with_format(title, body, note=nil)
      [before_elem(title, note), body, after_elem].join("\n")
    end

    def before_elem(title, note=nil)
      ['<div class="form-row">',
       %Q(<span class="labvirt-form-prompt">#{_ title}</span>),
       (note ? %Q(<span class="labvirt-form-note">#{_ note}</span>) : ''),
       '<span class="labvirt-form-input">'
      ].join("\n")
    end

    def after_elem
      '</span></div>'
    end

    def info_elem(info)
      %Q(<span class="labvirt-form-input">#{_ info.to_s}</span>)
    end

    def label_for_field(model, field)
#      [model.class.to_s, field.to_s.humanize].join('|')
      field.to_s.humanize
    end

    def table_from_field(field)
      return nil unless field =~ /_id$/
      tablename = field.gsub(/_id$/, '')
      return nil unless 
        ActiveRecord::Base.connection.tables.include? tablename.pluralize
      begin 
        model = tablename.camelcase.constantize
      rescue
        return nil
      end

      model
    end
  end

  def labvirt_form_for(name, object=nil, options=nil, &proc)
    form_for(name, object,
             (options||{}).merge(:builder => LabvirtFormBuilder), &proc)
  end
end

