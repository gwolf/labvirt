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
      [ 'VNC', '/usr/bin/vncviewer', '-PreferredEncoding hextile %HOST%']
    ].each { |ct| ClientType.new(:name => ct[0], 
                                 :path => ct[1],
                                 :base_params => ct[2]).save! }

    create_table :terminals do |t|
      t.string :ipaddr, :null => false
      t.string :serveraddr, :null => false
      t.timestamps
    end
    add_reference :terminals, :term_classes, :null => false
    add_index :terminals, :ipaddr, :unique => true
  end

  def self.down
    drop_table :terminals
    drop_table :term_classes
  end
end
