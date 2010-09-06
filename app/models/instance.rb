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
    instances = {}
    laboratories.each { |l| instances[l.id] = [] }

    Dir.open(SysConf.value_for(:pid_dir)).each do |file|
      next unless file =~ /^(.*)_(\d+)\.pid/
      lab_name = $1
      inst_num = $2
      next unless lab = laboratories.select {|p| p.name == lab_name}[0]
      next unless instance = self.new(lab, inst_num)
      next unless instance.running?
      
      instances[lab.id] << instance
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

  # Returns true if there is a running #Instance for this #Laboratory
  # in maintenance mode (#num == 0)
  def self.running_maint_for_laboratory?(lab)
    ! self.running_for_laboratory(lab).select {|i| i.maint?}.empty?
  end

  # Returns the list of #Instances currently running for a given
  # #Profile.
  def self.running_for_profile(prof)
    # Accept being called either with an instantiated profile or with
    # its ID
    prof = Profile.find(prof) if prof.is_a? Fixnum

    self.running_for_laboratory(prof.laboratory).select {|i| i.profile == prof}
  end

  # Starts a new instance running with the given profile. Returns the
  # instance object. If the instance was not successfully started, an
  # Instance::InvalidInstance exception will be raised.
  def self.start(prof)
    # Accept being called either with an instantiated profile or with
    # its ID
    prof = Profile.find(prof) if prof.is_a? Fixnum
    lab = prof.laboratory
    inst_num = lab.next_instance_to_start
    cmd = prof.start_command
    system(cmd)

    # The KVM invocation garbles up the terminal - Make it sane again
    system('stty sane 2>/dev/null')

    instance = self.new(lab, inst_num)
    File.open(instance.prof_file, 'w') {|f| f.write prof.id}
    instance
  end
  
  # Initializing an #Instance means verifying the PID file it
  # represents exists and retreiving the PID. To initialize it,
  # provide a #Laboratory and an #Instance ID.
  # 
  # Initializing an instance which is not running (i.e. the VM was
  # forcibly shut down) will raise an Instance::InvalidInstance
  # exception.
  def initialize(lab, num)
    lab = Laboratory.find_by_id(lab) unless lab.is_a? Laboratory
    @laboratory = lab
    @num = num.to_i

    get_pid_and_profile
  end

  # Sends a powerdown ACPI signal to a given VM #Instance. This is the
  # preferred way to shut down a VM, as the signal will be received by
  # its operating system and allow for a clean shutdown. The down side
  # is that the OS might choose to ignore it, or it might take some
  # time. 
  #
  # If a #power_down is not enough for your needs, you might want to
  # perform a #stop. 
  def power_down
    send_to_vm('system_powerdown')
  end

  # Sends a reset signal to a given VM #Instance. This is equivalent
  # to pushing the machine's "reset" button - It is performed "on the
  # spot". If your machine has any media mounted with write access
  # (i.e. specially if it is running under its #Profile's maintenance
  # mode), you should better shut it down cleanly.
  #
  # For VMs which are mounted in snapshot mode, this is _not_ the same
  # as stopping and restarting it. Calling this method is equivalent
  # to resetting the machine _in the exact state it is_.
  def reset
    send_to_vm('system_reset')
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
  # (i.e. cleans the PID files and becomes a useless, empty object)
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
  # (i.e. cleans the PID files and  becomes a useless, empty object)
  def kill
    ck_valid
    Process.kill 9, @pid if running?

    invalidate
  end

  # Shows the command line used to start this instance (from
  # /proc/<pid>/cmdline), if it is available to us. If it is not
  # readable, returns nil.
  def cmdline
    begin
      # The arguments are separated by nulls (\000) - Substitute it
      # with spaces, which is way more human.
      File.read("/proc/#{@pid}/cmdline").gsub /\000/, ' '
    rescue Errno::ENOENT
      nil
    end
  end

  # Returns true if this #Instance's PID is (or appears to be) running. 
  # 
  # We check only for the process' existence and command name,
  # verifying only if the cmdline includes the basename of the string
  # in the :kvm_bin #SysConf entry (that is, quite probably 'kvm'). Be
  # aware that this check is _not_ foolproof!
  def running?
    ck_valid
    kvm = File.basename(SysConf.value_for :kvm_bin)
    cmdline =~ /#{kvm}/
  end

  # Returns true if this #Instance is in maintenance mode - That is,
  # if its #num is 0. Keep in mind that only a single #Profile for
  # each #Laboratory can be running in maintenance mode at a given
  # time.
  def maint?
    ck_valid
    return true if @num.to_i == 0
    false
  end

  # Removes the process' PIDfile
  def clean_files
    ck_valid
    File.unlink(pid_file) if File.exists?(pid_file)
    File.unlink(prof_file) if File.exists?(prof_file)
    File.unlink(socket_file) if File.exists?(socket_file)
  end

  # Gets the full path for this #Instance's expected PIDfile
  def pid_file
    base_info_file + '.pid'
  end
  
  # Gets the full path for this #Instance's expected profile file
  def prof_file
    base_info_file + '.profile'
  end
  
  # Gets the full path for this #Instance's expected socket file
  def socket_file
    base_info_file + '.socket'
  end

  # Process startup time - When was this instance started: Creation
  # time of the inode in the /proc filesystem
  def startup_time
    pid = Instance.running_for_profile(2)[0].pid.to_s
    File.stat(File.join('/proc', pid)).ctime
  end

  # Process age (in seconds): How long has this instance been running
  def age
    Time.now - startup_time
  end

  # Returns true if the instance's age is greater than its profile's
  # restart_freq (indicated in days, with 0 indicating restart is
  # never needed)
  def needs_restart?
    return false if !profile or  profile.restart_freq == 0
    # Age is given in seconds - 86400 seconds to a day
    return age / 86400 > profile.restart_freq
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
      @profile = Profile.find_by_id(File.read(prof_file).to_i)
    rescue Errno::ENOENT, Errno::EACCES
      @profile = nil
    end
  end
  
  # Generates the base filename for the files we will use to store our
  # state
  def base_info_file
    ck_valid
    File.join(SysConf.value_for(:pid_dir), '%s_%03d' % [@laboratory.name, @num])
  end
  
  # If an #Instance is not valid, this method will raise an
  # Instance::InvalidInstance exception
  def ck_valid
    # Don't check on @pid, as it is only filled after some methods are
    # invoked
    raise InvalidInstance, _('This instance is no longer valid') if
      @num.nil? or @laboratory.nil?
  end

  # Marks this #Instance as invalid - Cleans up its PIDfile and
  # empties its attributes
  def invalidate
    clean_files
    @num = @laboratory = @pid = @profile = nil
  end

  # Sends the specified command to the virtual machine console. 
  def send_to_vm(command)
    socket = UNIXSocket.new(socket_file)
    socket.puts(command)
    socket.close
  end
end

# Might come in handy - We might go libvirt!
#
# (2009-01-13 10:23:22) gwolf: mDuff: Ok... I am working on (yes, yet another) control interface... And I'm using straight kvm, for several details that libvirt didn't solve for me. I am querying/controlling my VMs via a socket to the monitor - but there are several things I have not found out how to query (i.e. whether the machine is running or paused)
# (2009-01-13 10:24:03) gwolf: So... Where should I look for this information? I am even gathering some information from /proc/$pid/cmdline (i.e. which HD image it is working from) as I cannot get it from the VM
# (2009-01-13 10:24:17) gwolf: but that's... obviously suboptimal and rigid
# (2009-01-13 10:24:56) onos: mDuff: alright, I converted in qcow2, thank you once again :) have a good day
# (2009-01-13 10:27:34) mDuff: gwolf, ehh... good question. If all control is going through your interface, you can take libvirt's approach and only track VMs started via your interface, right? btw, I'm a little curious about what libvirt isn't doing for you
# (2009-01-13 10:28:42) gwolf: mDuff: I decided against libvirt because it didn't (maybe some months ago.. don't know now - and, at least, via the interfaces I checked) have support for running multiple VMs off a single HD image mounted as a snapshot
# (2009-01-13 10:33:43) mDuff: gwolf, ...err... if you use qemu-img create -b my-snapshot.qcow2 my-working-space-vm1.img, and then define a VM using my-working-space-vm1.img, that'll work just fine
# (2009-01-13 10:33:53) mDuff: gwolf, ...and you can run others under my-working-space-vm2.img etc.
# (2009-01-13 10:33:59) mDuff: gwolf, ...been that way for pretty much ever.
# (2009-01-13 10:34:46) mDuff: gwolf, (well, since I first started using libvirt, over a year ago)
# (2009-01-13 10:35:43) gwolf: mDuff: umh... No, I don't mean VM snapshots, but having disk devices defined such as "-drive index=1,media=disk,if=ide,snapshot=on,file=/home/gwolf/kvm/wxp " - But no, I'm not ruling out my own stupidity :)
# (2009-01-13 10:36:45) mDuff: gwolf, using snapshot=on is entirely equivalent to using qemu-img backend files but unlinking the file after the VM has started -- indeed, that's how it's implemented under-the-hood.
# (2009-01-13 10:37:11) mDuff: gwolf, ...you don't have the commit command as a console builtin in that case, but you can use qemu-img commit with the VM shutdown for equivalent semantics.
# (2009-01-13 10:37:48) onos: mDuff: (sorry to charge again) I don't find how to use savevm. I find a loadvm in the man qemu, but nothing else. and savevm unknown command of course
