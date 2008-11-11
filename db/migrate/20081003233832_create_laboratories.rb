class CreateLaboratories < ActiveRecord::Migration
  def self.up
    create_table :laboratories do |t|
      t.string  :name, :null => false
      t.text    :descr
      t.string  :mac_base_addr, :null => false
      t.integer :max_instances, :default => 1, :null => false
      t.integer :start_instances, :default => 0, :null => false

      t.timestamps
    end
    add_index :laboratories, :mac_base_addr, :unique => true

    add_reference :profiles, :laboratories
    add_column :profiles, :position, :integer, :null => false, :default => 1
  end

  def self.down
    if self.is_a? ActiveRecord::ConnectionAdapters::SQLiteAdapter or
        self.is_a? ActiveRecord::ConnectionAdapters::SQLite3Adapter
      raise ActiveRecord::IrreversibleMigration, 
        'SQLite does not allow removing attributes from tables - Cannot ' +
        'migrate down.'
    end

    remove_column :profiles, :position
    remove_reference :profiles, :laboratories
    drop_table :laboratories
  end
end
