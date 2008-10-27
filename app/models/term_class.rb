# A #TermClass defines the behaviour of a group of #Terminal
# instances. This behaviour consists basically on how it will connect
# to its server - What command will it run and which arguments it will
# specify.
#
# === Attributes
#
# [name] A description for this terminal class (meant for humans to
#        read)
#
# [path] The pathname of the program for this terminal to run
#
# [params] The parameters to give to the #path, if any. Note that you
#          can set as many substitution places you want, working as a
#          very simplistic template. The substitution will be done by
#          #Terminal's #client_params method - refer to it for further
#          details.
class TermClass < ActiveRecord::Base
  has_many :terminals
  validates_presence_of :name
  validates_presence_of :path
end
