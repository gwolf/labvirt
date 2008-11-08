# An #Instance represents a running virtual machine. This class is
# _not_ based on ActiveRecord::Base, as its information is not stored
# in the database, but on the filesystem - This is because its most
# important attribute (the PID) is generated directly by KVM as a
# file.
#
# === Attributes
#
# All of an #Instance's attributes are _read-only_, as this is
# basically an informative class
#
# [laboratory] Which laboratory does this #Instance belong to? It is
#              set at instantiation time (either directly with #new or
#              derived from the profile with #start).
#
# [num] The instance number within its laboratory. The
#       laboratory-instance pair is unique (no two instances may exist
#       with those values equal).
#
# [pid] The process ID for the running instance. This value is taken
#       from the PID file; if it cannot be retreived, the instance
#       will not be instantiated.
#
# [profile] The profile this instance is running under. This value
#           might be undefined, i.e. if we initialized an already
#           running instance and it lacks the needed information.
class Instance
  include GetText
  class InvalidInstance < Exception #:nodoc:
  end
  class CannotStartInstance < Exception #:nodoc:
  end

  attr_reader :num, :laboratory, :pid, :profile

  # Gives a hash of all currently running virtual machines, grouped
  # (keyed) by their #Laboratory ID. 
  #
  # Any files found in the PID/profile directory (specified by
  # #SysConf's +pid_dir+ entry) not recognized or not belonging to any
  # existing laboratory will be ignored.
  def self.all_running(quiet=nil)
    laboratories = Laboratory.find(:all)
    instances = []
    laboratories.each { |l| instances[l.id] = [] }

    Dir.open(SysConf.value_for(:pid_dir)).each do |file|
      next unless file =~ /^(.*)_(\d+)\.pid/
      lab_name = $1
      instance = $2
      next unless lab = laboratories.select {|p| p.name == lab_name}[0]

      instances[lab.id] << self.new(lab, instance)
    end

    instances
  end

  # Returns the list of #Instances currently running for a given
  # #Laboratory. 
  def self.running_for_laboratory(lab)
    # Accept being called either with an instantiated laboratory or with
    # its ID
    lab = lab.id if lab.is_a? Laboratory

    self.all_running[lab]    
  end

  # Returns the list of #Instances currently running for a given
  # #Profile.
  def self.running_for_profile(prof)
    # Accept being called either with an instantiated profile or with
    # its ID
    prof = Profile.find(prof) if prof.is_a? Fixnum

    self.running_for_laboratory[prof.laboratory].select {|i| i.profile == prof}
  end
  

  # Starts a new instance running with the given profile. Returns the
  # instance object.
  def self.start(profile)
    cmd = profile.start_command
    #####
  end
  
  # Initializing an #Instance means verifying the PID file it
  # represents exists and retreiving the PID. To initialize it,
  # provide a #Laboratory and an #Instance ID.
  # 
  # An #Instance will be initialized even if the PID it refers to is
  # no longer running - Use #running? / #clean_files if needed.
  def initialize(lab, num)
    lab = Laboratory.find_by_id(lab) if lab.is_a? Fixnum
    @laboratory = lab
    @num = num

    get_pid_and_profile
  end

  # Stops a given VM #Instance. Note that stopping the machine is
  # equivalent to pulling its plug - It is killed "on the spot". If
  # your machine has any media mounted with write access
  # (i.e. specially if it is running under its #Profile's maintenance
  # mode), you should better shut it down cleanly.
  #
  # Processes are stopped with SIGTERM (15). If for some reason they
  # refuse to die, #kill will stop them with SIGKILL (9).
  # 
  # Once KVM is killed, this #Instance becomes useless (as it refers
  # to a no longer existing process) and invalidates itself
  # (i.e. becomes a useless, empty object)
  def stop
    ck_valid
    Process.kill 15, @pid if running?

    invalidate
  end

  # Forcibly kills a given VM #Instance in a violent way - Sends it a
  # SIGKILL (9), which prevents KVM from performing any cleanup and
  # might lead to unavailable resources.
  #
  # Once KVM is killed, this #Instance becomes useless (as it refers
  # to a no longer existing process) and invalidates itself
  # (i.e. becomes a useless, empty object)
  def kill
    ck_valid
    Process.kill 9, @pid if running?

    invalidate
  end

  # Returns true if this #Instance's PID is (or appears to be) running. 
  # 
  # We check only for the process' existence and command name,
  # verifying only if the cmdline includes the 'kvm' string. Be aware
  # that this check is _not_ foolproof!
  def running?
    ck_valid
    Dir.open('/proc').each do |pid| 
      return if pid.chomp == @pid.to_s and 
        File.read("/proc/#{@pid}/cmdline") =~ /kvm/
    end
    false
  end

  # Removes the process' PIDfile
  def clean_files
    ck_valid
    File.unlink(pid_file) if File.exists?(pid_file)
    File.unlink(prof_file) if File.exists?(prof_file)
  end

  private
  # Gets this #Instance's Process ID (PID) and current profile from
  # its PIDfile
  def get_pid_and_profile
    ck_valid
    
    # The PID file is required - If it is not found, it means we
    # cannot get any information for this instance. Bail out.
    raise InvalidInstance, _("Instance %s for %s is not running or did not " +
                             "register its PID ") % 
      [@num, @laboratory.name] unless File.exists? pid_file
    @pid = File.read(pid_file).chomp.to_i

    # However, the profile file is merely informational. We can safely
    # ignore it if it does not exist or is not readable
    begin
      @profile = Profile.find_by_id(File.read(proc_file).chomp.to_i)
    rescue Errno::ENOENT, Errno::EACCES
      @profile = nil
    end
  end

  # Gets the full path for this #Instance's expected PIDfile
  def pid_file
    base_info_file + '.pid'
  end
  
  # Gets the full path for this #Instance's expected profile file
  def prof_file
    base_info_file + '.profile'
  end
  
  # Generates the base filename for the files we will use to store our
  # state
  def base_info_file
    ck_valid
    File.join(SysConf.value_for(:pid_dir), '%s_%d' % @laboratory.nme, @num)
  end
  
  # If an #Instance is not valid, this method will raise an
  # InvalidInstance exception
  def ck_valid
    # Don't check on @pid, as it is only filled after some methods are
    # invoked
    raise InvalidInstance, _('This instance is no longer valid') if
      @num.nil? or @laboratory.nil?
  end

  # Marks this #Instance as invalid - Cleans up its PIDfile and
  # empties its attributes
  def invalidate
    ck_valid
    clean_files
    @num = @laboratory = @pid = @profile = nil
  end
end
