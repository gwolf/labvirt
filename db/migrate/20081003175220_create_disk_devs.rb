class CreateDiskDevs < ActiveRecord::Migration
  def self.up
    create_catalog :disk_types
    create_catalog :media_types

    %W(ide scsi virtio).each {|dt| DiskType.new(:name=>dt).save!}
    %W(disk cdrom).each {|mt| MediaType.new(:name=>mt).save!}

    create_table :disk_devs do |t|
      t.string :name
      t.string :path, :null => false
      t.timestamps
    end
    add_reference :disk_devs, :disk_types,  :null => false, :default => 1
    add_reference :disk_devs, :media_types, :null => false, :default => 1

    add_index :disk_devs, :name, :unique => true
  end

  def self.down
    drop_table :disk_devs
    drop_catalogs :disk_types, :media_types
  end
end
