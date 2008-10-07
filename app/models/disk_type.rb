# #DiskType is a simple catalog, representing each of the supported
# disk types for a #DiskDev - Currently, the values are ide, scsi and
# virtio. 
#
# Using virtio is much recommended performance-wise - as long as your
# operating system supports it. You should probably install your OS
# using regular IDE emulation, install the needed drivers, and change
# the definition to use virtio when going into production.
class DiskType < ActiveRecord::Base
  has_many :disk_devs
  acts_as_catalog
end
