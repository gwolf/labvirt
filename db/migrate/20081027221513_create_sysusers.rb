class CreateSysusers < ActiveRecord::Migration
  def self.up
    create_table :sysusers do |t|
      t.string :name
      t.string :login
      t.string :passwd
      t.string :pw_salt
      t.boolean :admin

      t.timestamps
    end
  end

  def self.down
    drop_table :sysusers
  end
end
