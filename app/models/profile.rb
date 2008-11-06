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
#              not to start the virtual hosts in their regular
#              fashion, with many computer instances and each of their
#              respective #DiskDev images mounted in _snapshot_ mode,
#              but to start only a single instance in regular
#              read/write mode.
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
  class CannotStartInstance < Exception #:nodoc:
  end

  has_many :disk_devs, :order => 'position'
  belongs_to :net_iface
  belongs_to :laboratory
  acts_as_list :scope => :laboratory

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_presence_of :active

  # Can a new #Instance be started on this #Profile?  That basically
  # means: Is the current #Profile active? Is it not in maintenance
  # mode? Does the #Laboratory to which it belongs allow for one more
  # #Instance?
  def can_start_instance?
  end

  # Starts a new instance of this #Profile. If no new instances can be
  # started (see #can_start_instance), raises a CannotStartInstance
  # exception.
  def start_instance
  end

  # Stops the instance of this profile identified by the given ID
  def stop_instance(which)
  end

  # Puts the current profile in maintenance mode - That means, shuts
  # down all of its active virtual machines, and launches the
  # maintenance instance.
  # 
  # If the maintenance instance cannot be started, raises a
  # CannotStartInstance exception.
  def start_maintenance
  end

  # Stops the maintenance instance. If it is not currently running,
  # just returns false (just a NOOP, no exception raised).
  def stop_maintenance
  end
end
