class InstancesController < ApplicationController
  def list
    # We get the data from Instance#all_running with the lab_id as the
    # key - Replace it for the full Laboratory object
    instances = Instance.all_running
    @active = {}
    instances.keys.each do |lab_id|
      @active[Laboratory.find(lab_id)] = instances[lab_id]
    end
    (@prof_start_ok, @prof_no_start) = Profile.find(:all).partition {|p| p.can_start_instance?}
  end

  def start_instance
    begin
      p = Profile.find(params[:profile_id])
      p.start_instance
      flash[:notice] = _('A new instance was successfully started for profile %s') % p.name
    end
    redirect_to :action => 'list'
  end

  def stop_instance
    begin
      (lab_id, inst_num) = params[:lab_id], params[:inst_num]
      Instance.new(lab_id, inst_num).kill
    rescue Instance::InvalidInstance => err
      flash[:error] = [_('Error stopping requested instance (%s-%s): ')%[lab_id, inst_num],
                       err]
    end
    redirect_to :action => 'list'
  end
end
