class CreateTerminals < ActiveRecord::Migration
  def self.up
    create_table :term_classes do |t|
      t.string :name, :null => false
      t.string :path, :null => false
      t.string :params
      t.timestamps
    end
    [ [ 'Local RDP, with local disks/sound', '/usr/bin/rdesktop',
        '-a 16 -f -xl -r sound:local -r disk:usb=/media/usb ' <<
        '-r disk:cdrom=/media/cdrom -u %USER% -p %PASSWD% %HOST%'
      ],
      [ 'VNC', '/usr/bin/vncviewer', '-PreferredEncoding hextile %HOST%:%PORT']
    ].each { |tc| TermClass.new(:name => tc[0], 
                                 :path => tc[1],
                                 :params => tc[2]).save! }

    create_table :terminals do |t|
      t.string :termid, :null => false
      t.string :serveraddr, :null => false
      t.timestamps
    end
    add_reference(:terminals, :term_classes, :null => false, 
                  :default => TermClass.find(:first, :order => 'id').id)
    add_index :terminals, :termid, :unique => true

    create_table :term_params do |t|
      t.string :name, :null => false
      t.string :value
    end
    add_reference(:term_params, :terminals)
    add_index :term_params, :terminal_id
  end

  def self.down
    drop_table :terminals
    drop_table :term_classes
  end
end
