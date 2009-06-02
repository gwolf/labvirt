module InstancesHelper
  def stop_link_for(instance, lab)
    link_for _('Stop'), 'stop', instance, lab
  end

  def reset_link_for(instance, lab)
    link_for _('Reset'), 'reset', instance, lab
  end

  def profiles_per_lab(prof)
    res = ['<dl>']
    prof.partition {|p| p.laboratory_id}.each do |lab|
      next if lab.empty?
      l = Laboratory.find(lab[0].laboratory_id)
      res << _('<dt>Laboratory: %s</dt>') % link_to(l.name, laboratory_url(l))
      res << '<dd>%s</dd>' % startable_profiles(lab)
    end
    res << '</dl>'
  end

  def startable_profiles(profs)
    ['<ul>',
     profs.map {|p| _('<li>%s: %s • %s</li>') % 
       [link_to(p.name, profile_url(p)), p.descr, 
        link_to(_('Start instance'), :action => 'start_instance', 
                :profile_id => profs)]}, 
     '</ul>'].join("\n")
  end

  protected
  def link_for(label, action, instance, lab, show_warn=true)
    inst_warn = _('Warning: This will cause data loss if this instance ' +
                  'is in use. Are you sure?')
    link_to label, {:action => action, :lab_id => lab.id, 
      :inst_num => instance.num}, {:confirm => show_warn ? inst_warn : nil}
  end
end
