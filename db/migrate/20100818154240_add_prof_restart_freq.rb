class Profile < ActiveRecord::Base;end
class AddProfRestartFreq < ActiveRecord::Migration
  def self.up
    add_column :profiles, :restart_freq, :integer, :default => 0, :null => false
    Profile.find(:all).map {|p| p.restart_freq = 0; p.save!}
  end

  def self.down
    remove_column :profiles, :restart_freq
  end
end
