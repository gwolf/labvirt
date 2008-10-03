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

    add_reference :disk_devs, :profiles
    add_column :disk_devs, :position, :integer, :null => false, :default => 1

    add_index :profiles, :name, :unique => true
    add_index :profiles, :mac_base_addr, :unique => true
    add_index :disk_devs, [:position, :profile_id], :unique => true
  end

  def self.down
    drop_columns :disk_devs, :profile_id, :position
  end
end
