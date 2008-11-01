# #TermParam holds any terminal-specific configuration parameters
# which cannot be derived from either the #Terminal nor its #TermClass.
#
# The #TermParams will be usually indirectly queried by calling the
# Terminal#client_params method
#
# === Attributes
#
# [name] The attribute name (key). Keys must be unique for each
#        terminal (meaning, no two #TermParam entries with the same
#        name will be accepted for a single terminal)
#
# [value] The value for this terminal parameter
class TermParam < ActiveRecord::Base
  belongs_to :terminal

  validates_presence_of :name
  validates_presence_of :terminal_id
  validates_associated :terminal
  validates_uniqueness_of :name, :scope => :terminal_id
end
