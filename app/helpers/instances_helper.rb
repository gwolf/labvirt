module InstancesHelper
  def stop_link_for(instance, lab)
    link_for _('Stop'), 'stop', instance, lab
  end

  def reset_link_for(instance, lab)
    link_for _('Reset'), 'reset', instance, lab
  end

  protected
  def link_for(label, action, instance, lab, show_warn=true)
    inst_warn = _('Warning: This will cause data loss if this instance ' +
                  'is in use. Are you sure?')
    link_to label, {:action => action, :lab_id => lab.id, 
      :inst_num => instance.num}, {:confirm => show_warn ? inst_warn : nil}
  end
end
