class NetIface < ActiveRecord::Base
  has_many :profiles
  acts_as_catalog
end
