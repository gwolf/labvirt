class Instance
  include GetText
  class InvalidInstance < Exception #:nodoc:
  end

  attr_reader :id, :laboratory, :pid

  # Gives a hash of all currently running virtual machines, grouped
  # (keyed) by their #Laboratory ID. 
  #
  # Any files found in the PID directory (specified by #SysConf's
  # +pid_dir+ entry) not recognized or not belonging to any existing
  # laboratory will be ignored.
  def self.all_running(quiet=nil)
    laboratories = Laboratory.find(:all)
    pids = []
    laboratories.each { |l| pids[l.id] = [] }

    Dir.open(SysConf.value_for(:pid_dir)).each do |file|
      next unless file =~ /^(.*)_(\d+)\.pid/
      lab_name = $1
      instance = $2
      next unless lab = laboratories.select {|p| p.name == lab_name}[0]

      pids[lab.id] << self.new(lab, instance)
    end

    pids
  end

  # Returns the list of #VMInstances currently running for a given
  # #Laboratory. 
  def self.running_for_laboratory(lab)
    # Accept being called either with an instantiated laboratory or with
    # its ID
    lab = lab.id if lab.is_a? Laboratory

    self.all_running[lab]    
  end

  # Initializing an #Instance means verifying the PID file it
  # represents exists and retreiving the PID. To initialize it,
  # provide a #Laboratory and an #Instance ID.
  # 
  # An #Instance will be initialized even if the PID it refers to is
  # no longer running - Use #running? / #clean_pid if needed.
  def initialize(lab, id)
    lab = Laboratory.find_by_id(lab) if lab.is_a? Fixnum
    @laboratory = lab
    @id = id

    get_pid
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
  # Note that KVM is expected to clean up the environment after being
  # killed with SIGTERM - This includes removing its PID file, so we
  # do not verify its remotion.
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
  # After the process is killed, we sleep for a second and remove any
  # visible traces of it (i.e. its PID file)
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
  def clean_pid
    ck_valid
    File.unlink(pidfile) if File.exists?(pidfile)
  end

  private
  # Gets this #Instance's Process ID (PID) from its PIDfile
  def get_pid
    ck_valid
    file = pidfile
    raise InvalidInstance, _("Instance %s for %s is not running or did not " +
                             "register its PID ") % 
      [@id, @laboratory.name] unless File.exists? file
    @pid = File.read(file).chomp.to_i
  end

  # Gets the full path for this #Instance's expected PIDfile
  def pidfile
    ck_valid
    File.join(SysConf.value_for(:pid_dir), 
              '%s_%d.pid' % [@laboratory.name, @id])
  end

  # If an #Instance is not valid, this method will raise an
  # InvalidInstance exception
  def ck_valid
    # Don't check on @pid, as it is only filled after some methods are
    # invoked
    raise InvalidInstance, _('This instance is no longer valid') if @id.nil? or
      @laboratory.nil?
  end

  # Marks this #Instance as invalid - Cleans up its PIDfile and
  # empties its attributes
  def invalidate
    ck_valid
    clean_pid
    @id = @laboratory = @pid = nil
  end
end
