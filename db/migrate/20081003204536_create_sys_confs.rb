class CreateSysConfs < ActiveRecord::Migration
  def self.up
    create_table :sys_confs do |t|
      t.string :key, :null => false, :unique => true
      t.string :descr
      t.string :value
      t.timestamps
    end

    add_index :sys_confs, :key, :unique => true
  end

  def self.down
    drop_table :sys_confs
  end
end
