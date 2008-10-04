class Profile < ActiveRecord::Base
  has_many :disk_devs, :order => 'position'
  belongs_to :net_iface
  belongs_to :laboratory
  acts_as_list, :scope => :laboratory

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_presence_of :active
end
