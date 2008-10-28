class TermParam < ActiveRecord::Base
  belongs_to :terminal

  validates_presence_of :name
  validates_presence_of :terminal_id
  validates_associated :terminal
  validates_uniqueness_of :name, :scope => :terminal_id
end
