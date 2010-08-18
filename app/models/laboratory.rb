class NoMoreAvailableInstances < Exception #:nodoc
end
class NoProfileAvailable < Exception #:nodoc
end
# A #Laboratory defines a series of virtual machines on which given
# #Profile instances can be created. The #Profile list for each
# #Laboratory can be ordered, so the highest-ranking profile will be
# booted by default.
#
# === Attributes
#
# [name]  Each laboratory has a unique short name #name - This will be
#         used to identify (towards KVM) each of the virtual
#         hosts. Thus, the name should be up to 10 characters long, and
#         not include whitespaces nor punctuation. Alphanumeric
#         characters (and underscore) are allowed. 
#
# [descr] An optional long description (#descr) can be supplied as
#         well, meant for humans to read
#
# [max_instances] The maximum number of virtual machine instances to
#                 allow to be started in this laboratory
#
# [start_instances] The number of instances to (attempt to) start at
#                   system initialization. Instances automatically
#                   started will belong to the #Profile that (at that
#                   time) is returned as #default_profile for this
#                   laboratory.
#
# [mac_base_addr] The starting physical network address - It must be a
#                 valid MAC address in its usual representation - six
#                 bytes in hexadecimal notation, separated by colons
#                 (:). The only added restriction is that the last
#                 octet should be 00 - i.e. 00:18:8b:09:d1:00 And why
#                 00? Because that will be the _base_ address for the
#                 whole laboratory; the first virtual machine instance
#                 will be 01, the next one 02, and so on. Of course,
#                 make sure the assigned numbers do not clash with any
#                 of your other machines' -real or virtual
#                 addresses. You can refer to MAC address lists as
#                 http://standards.ieee.org/regauth/oui/oui.txt
#                 (authoritative) or
#                 http://www.ciphertechs.com/tools/mac.address.list.html
#                 (easier to read) for further details.
# 
class Laboratory < ActiveRecord::Base

  has_many :profiles, :order => 'position'

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 10
  validates_format_of(:name, :with => /^[\w\d\_]+$/,
                      :message => _('Must be exclusively alphanumeric ' +
                                    'characters. Underscores are allowed'))

  validates_presence_of :max_instances
  validates_numericality_of :max_instances, :greater_than => 0
  validates_presence_of :start_instances
  validates_numericality_of :start_instances, :greater_than_or_equal_to => 0

  validates_presence_of :mac_base_addr
  validates_uniqueness_of :mac_base_addr
  validates_format_of(:mac_base_addr, :with => /^([0-9a-f]{2}([:-])){5}00$/i,
                      :message => _('Has to be a valid MAC address, ' +
                                    'with 00 as its last byte'))

  # Returns the list of profiles that can be currently used for this
  # laboratory.
  def active_profiles
    profiles.select {|p| p.active?}
  end

  # Returns the list of currently active instances for this laboratory
  def active_instances
    Instance.running_for_laboratory(self)
  end

  # Which is the default profile to start if a new #Instance of this
  # laboratory is requested? It will be the first profile (sorted
  # according to its position) belonging to this laboratory which is
  # not currently in maintenance mode.
  #
  # If the #Laboratory is running at its full capacity (this means, if
  # the number of #active_instances is the same as #max_instances),
  # this will return nil.
  def default_profile
    active_profiles.select {|prof| prof.can_start_instance?}.first
  end

  # Returns the #Instance ID the next #Instance to be started should
  # be assigned; If no further instances can be currently started for
  # this #Laboratory, raises a #NoMoreAvailableInstances exception
  def next_instance_to_start
    active = active_instances.map {|inst| inst.num.to_i}
    if active.size >= max_instances
      raise NoMoreAvailableInstances, 
      _('Laboratory %s (%d) has reached its maximum number of instances (%d)') %
        [name, id, max_instances]
    end

    # Assign the lowest available number
    1.upto(max_instances) {|num| return num unless active.include?(num)}

    raise NoMoreAvailableInstances, _('Cannot assign a new instance number')
  end

  # Generates the MAC address for a given instance number (or for the
  # next available instance, if not specified)
  def mac_for_instance(num=nil)
    num = next_instance_to_start if num.nil?
    num = num.to_i if num.is_a?(String) and num =~ /^\d+$/
    if !num.is_a? Fixnum or num < 0 or num > 255 
      raise TypeError, _('Argument must be an integer between 0 and 255')
    end
    offset = sprintf('%02x', num)
    mac = mac_base_addr.gsub(/00$/, offset)

    mac
  end

  # Generates the instance namefor a given instance number (or for the
  # next available instance, if not specified)
  def instance_name(num=nil)
    num = next_instance_to_start if num.nil?
    sprintf '%s_%03d' % [name, num]
  end

  # Starts a new instance with the #default_profile
  def start_instance
    prof = default_profile or
      raise NoProfileAvailable, 'No default profile available'
    prof.start_instance
  end
end
