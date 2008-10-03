class Profile < ActiveRecord::Base
  has_and_belongs_to_many :disk_devs

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 10
  validates_format_of(:name, :with => /^[\w\d\_]+$/,
                      :message => ('Must be exclusively alphanumeric ' +
                                   'characters. Underscore is allowed'))

  validates_presence_of :mac_base_addr
  validates_uniqueness_of :mac_base_addr
  validates_format_of(:mac_base_addr, :with => /^([0-9a-f]{2}([:-])){5}00$/i,
                      :message => _('Has to be a valid MAC address, ' +
                                    'with 00 as its last byte'))

  validates_presence_of :instances
  validates_numericality_of :instances, :greater_than => 0
  validates_presence_of :active
end
