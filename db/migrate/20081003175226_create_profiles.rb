class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.string     :name, :null => false
      t.string     :mac_base_addr, :null => false
      t.text       :descr
      t.integer    :ram, :null => false, :default => 256
      t.string     :extra_params
      t.integer    :instances, :null => false, :default => 1
      t.boolean    :active, :null => false, :default => true
      t.timestamps
    end
    create_habtm :profiles, :disk_devs

    add_index :profiles, :name, :unique => true
    add_index :profiles, :mac_base_addr, :unique => true
  end

  def self.down
    drop_habtm :profiles, :disk_devs
    drop_table :profiles
  end
end
