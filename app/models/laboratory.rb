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
# [instances] The maximum number of virtual machine instances to allow
#             to be started in this laboratory
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

  validates_presence_of :instances
  validates_numericality_of :instances, :greater_than => 0

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

  # Returns the #Instance ID the next #Instance to be started should
  # be assigned; returns nil if no further instances can be currently
  # started for this #Laboratory
  def next_instance_to_start
    active = active_instances
    return nil if active.size >= instances

    # Assign the lowest available number
    1.upto(instances) {|num| return num unless active.include?(num)}
    nil
  end
end
