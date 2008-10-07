# #NetIface is a simple catalog, representing each of the supported
# network adapter types for a given #Profile. Currently, the values
# are e1000, i82551, i82557b, i82559er, ne2k_isa, ne2k_pci, pcnet,
# rtl8139 and virtio.
#
# Using virtio is much recommended performance-wise - as long as your
# operating system supports it. You should probably install your OS
# using a well-known real card emulation (i.e. rtl8139, or ne2k_pci),
# install the needed drivers, and change the definition to use virtio
# when going into production.
class NetIface < ActiveRecord::Base
  has_many :profiles
  acts_as_catalog
end
