# A #Profile defines a set of functionality a #Laboratory of virtual
# machines can offer. This functionality depends basically on:
# 
# * Which #DiskDev (i.e. hard disk images) are available, and on which order
#   are they presented to the virtual host
# * Which virtual networking hardware (#NetIface) does this profile emulate
# * How many hardware resources are available for the machine (i.e. RAM)
#
# Each #Profile is associated to one #Laboratory (multiple relation
# might come in in the future). 
#
# #DiskDev instances are sorted according to their #position attribute
# - The system will boot from the first available device. Please look
# at the #DiskDev documentation regarding their performance.
#
# === Attributes
#
# [name] A human-readable short description of this profile
#
# [descr] An optional, longer description of this profile
#
# [ram] The RAM size of the machines to be emulated, in MB. Defaults
#       to 256.
#
# [maint_mode] Whether a given profile is considered to be in
#              _maintenance_ mode. This should signal the #Laboratory
#              not to start the virtual hosts for this #Profile in
#              their regular fashion, with many VM #Instances and each
#              of their respective #DiskDev images mounted in
#              _snapshot_ mode, but to start only a single #Instance
#              in regular read/write mode. Of course, other #Profiles
#              can be used normally for this same #Laboratory.
#              
#              While many #Profiles can be set to maintenance mode,
#              only one of them can be running for a given
#              #Laboratory; every other #Profile marked as in
#              maintenance will be kept inactive.
#
# [active] Whether a given profile should be marked as
#          _active_. Inactive profiles will not be booted.
#
# [position] Used to show the preferences among profiles per
#            laboratory - The highest positioned #Profile marked as
#            #active will be booted automatically upon system startup.
#
# [extra_params] Any extra parameters to specify to KVM upon virtual
#                machine instantation

class Profile < ActiveRecord::Base
  has_many :disk_devs, :order => 'position'
  belongs_to :net_iface
  belongs_to :laboratory
  acts_as_list :scope => :laboratory

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_inclusion_of :active, :in => [true, false]
  validates_inclusion_of :maint_mode, :in => [true, false]

  # Can a new #Instance be started on this #Profile?  That basically
  # means: 
  # 
  # - If the current #Profile is in maintenance mode, no other VM
  #   #Instance is running on it, and no other #Profile of the same
  #   #Laboratory is  running in maintenance mode
  #
  # - Otherwise, is the current #Profile active? Does
  #   the #Laboratory to which it belongs allow for one more
  #   #Instance?
  def can_start_instance?
    if maint_mode?
      return false unless Instance.running_for_profile(self).empty? or
        Instance.running_maint_for_laboratory?(laboratory)
    else
      return false if !active? or 
        laboratory.max_instances <= laboratory.active_instances.size
    end
    true
  end

  # Starts a new instance of this #Profile. 
  def start_instance
    Instance.start(self)
  end

  # Stops the #instance of this profile identified by the given
  # #Instance number
  def stop_instance(which)
    inst = Instance.running_for_profile(self).select {|i| i.num == which}
    return nil if inst.empty?
    inst.first.stop
  end

  # Puts the current profile in maintenance mode - That means, shuts
  # down all of its active virtual machines, and launches the
  # maintenance instance.
  #
  # Note that this method induces a two second delay, so the running
  # instances have time to be removed and start_instance does not
  # fail.
  #
  # If this #Profile was already in maintenance mode, no action is
  # performed.
  def start_maintenance
    return true if maint_mode?

    Instance.running_for_profile(self).map {|i| i.stop}
    maint_mode = true
    self.save!
    sleep 2

    self.start_instance
  end

  # Stops the maintenance instance, and sets the current profile as
  # for regular use. If there is a running maintenance instance, stop
  # it as well. Unlike what happens in #start_maintenance, this method
  # will _not_ start any virtual machines, it will only _allow_ them
  # to be started in the regular ways.
  # 
  # Note that, as any #DiskDevs for this #Instance are mounted RW, it
  # is much recommended to properly shut down its operating system
  # from the virtual machine itself.
  #
  # If this #Profile was not in maintenance mode, no action is
  # performed.
  def stop_maintenance
    return true unless maint_mode?

    Instance.running_for_profile(self).map {|i| i.stop}
    maint_mode = false
    self.save!
  end

  # Builds the command line to start a new #Instance of this
  # #Profile. Returns nil if this instance cannot be currently
  # started.
  def start_command
    can_start_instance? or return nil

    kvm = SysConf.value_for('kvm_bin')
    basedir = SysConf.value_for(:pid_dir)

    inst_num = maint_mode? ? 0 : laboratory.next_instance_to_start
    inst_name = laboratory.instance_name(inst_num)
    mac = laboratory.mac_for_instance(inst_num)
    disks = disk_devs.map {|d| d.dev_string }.join(' ')

    pidfile = File.join(basedir,"#{inst_name}.pid")
    socket = File.join(basedir, "#{inst_name}.socket")

    [ "#{kvm} -name #{inst_name} -m #{ram} -localtime -pidfile #{pidfile}",
      "-usb -usbdevice tablet",
      "-net nic,macaddr=#{mac},model=#{net_iface.name}",
      "-net tap,ifname=tap_#{inst_name},script=/etc/kvm/kvm-ifup",
      "-boot c #{disks}",
      "-daemonize -nographic",
      "-monitor unix:#{socket},server,nowait"
      ].join(' ')
  end
end
