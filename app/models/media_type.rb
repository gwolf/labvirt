class MediaType < ActiveRecord::Base
  has_many :disk_devs
  acts_as_catalog
end
