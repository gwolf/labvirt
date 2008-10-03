class DiskDev < ActiveRecord::Base
  has_and_belongs_to_many :profiles
  belongs_to :disk_type
  belongs_to :media_type

  validates_presence_of :name
  validates_uniqueness_of :name

  def dev_string(drivenum,opts)
    '-drive index=%d,media=%s,if=%s%s,file=%s' % 
      [drivenum, media_type.name, disk_type.name, extra_params(opts), path]
  end

  protected
  def extra_params(opts)
    res = opts
    # SCSI and virtio devices require adding explicitly 'boot=on'
    res << ',boot=on' if media_type.name =~ /^(scsi|virtio)$/
    res
  end
end
