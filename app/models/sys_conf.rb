# #SysConf stores the basic system configuration
# information. Configuration entries are refered to by their key.
#
# === Attributes
#
# [key] The key to a given configuration entry
#
# [descr] An optional description on what the entry means
#
# [value] The configuration value
#
# === Basic entries
#
# The following entries are expected to exist --- If they do not exist
# in the database, querying for a #SysConf value via the #value_for
# method will return its default value. If the default values is not
# usable (i.e. inexisting directories, lack of permissions, etc.),
# suitable errors should be raised.
#
# [pid_dir] The directory where the PID files for each of the running
#           hosts will be created. Defaults to /var/run/labvirt
#
# [kvm_bin] The filename (including full path) for kvm. Defaults to
#           /usr/bin/kvm.
#
# [disk_dev_path] The directory where #DiskDev images will be
#                 stored. Defaults to /var/lib/vhosts/
class SysConf < ActiveRecord::Base
  validates_presence_of :key
  validates_uniqueness_of :key

  SysConfDefaults = { 'pid_dir' => '/var/run/labvirt',
    'kvm_bin' => '/usr/bin/kvm',
    'disk_dev_path' => '/var/lib/vhosts/'
  }

  # This is the preferred way to query for a configuration entry, as
  # it will take into account the default values. It hands back only
  # the string with the value (not the full #SysConf object). This
  # method is basically shorthand for #find_by_key(key).value
  def self.value_for(key)
    key = key.to_s
    item = self.find_by_key(key) or return SysConfDefaults[key]
    item.value
  end

  # Hands back an alphabetically sorted list of all of the defined
  # configuration keys
  def self.keys
    (self.find(:all).map {|sc| sc.key} + SysConfDefaults.keys).
      sort {|a,b| a.to_s<=>b.to_s}

  end
end
