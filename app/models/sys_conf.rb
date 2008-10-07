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
class SysConf < ActiveRecord::Base
  validates_presence_of :key
  validates_uniqueness_of :key

  # Shorthand for find_by_key(key).value
  def self.value_for(key)
    item = self.find_by_key(key.to_s)
    item.value if item
  end
end
