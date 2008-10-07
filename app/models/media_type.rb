# #MediaType is a simple catalog, representing the type of media
# handled by each of your #DiskDev instances. Currently, the values
# are cdrom and disk (disk meaning hard disk).
class MediaType < ActiveRecord::Base
  has_many :disk_devs
  acts_as_catalog
end
