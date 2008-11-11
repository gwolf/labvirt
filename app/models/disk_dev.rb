# A #DiskDev (disk device) references a virtual hard disk image on
# your host system. Each #DiskDev belongs to a #Profile, under which
# it will be made available - No provisions are (yet) made to allow
# for more than one #Profile per #DiskDev.
#
# Note that #DiskDevs are ordered in each #Profile according to their
# #position. the devices will be filled in in order (no "holes" are
# left - i.e. IDE disks will be filled in the following order: Primary
# master, primary slave, secondary master, secondary slave). Remember
# that each #DiskDev specifies its MediaType and DiskType; it is
# recommended that, should you emulate an IDE bus, the most intensive
# devices be set as master devices - This might involve i.e. creating
# a dummy primary slave disk.
# 
# Note that, unless the #Profile is specified to be acting in
# maintenance mode, its #DiskDev instances will be used in _snapshot_
# mode.
#
# #DiskDev images are expected to be found in the systemwide disk
# device full filename - This name is set through the +disk_dev_path+
# entry of #SysConf. Note that this model assumes the directory exists
# and has proper permissions set (i.e. rwx for the currently running
# user). If this pathname does not exist or is not properly set,
# expect exceptions to be raised (often, Errno::ENOENT, Errno::EPERM
# or similar).
#
# A #DiskDev will also be related to its #DiskType and #MediaType.
#
# === Attributes
#
# [name] A human-readable name describing this image
#
# [filename] The filename for this #DiskDev, located in the systemwide
#            +disk_dev_path+ directory (see #SysConf). The filename
#            must be limited to alphanumeric characters (a-z, A-Z,
#            0-9, underscore, hyphen and period).
#
# [disk_type] The #DiskType this #DiskDev should be (usually IDE)
#
# [media_type] The #MediaType this #DiskDev should be (usually Disk,
#              might also be CD-Rom)
class DiskDev < ActiveRecord::Base
  acts_as_list :scope => :profile
  belongs_to :profile
  belongs_to :disk_type
  belongs_to :media_type

  validates_presence_of :filename
  validates_format_of :filename, :with => /^[a-zA-Z0-9\-_\.]+$/
  validates_presence_of :name
  validates_uniqueness_of :name

  # Gets the list of known DiskDev entries which are not associated to
  # any profile
  def self.orphan
    self.find(:all, :conditions => ['profile_id IS NULL'])
  end

  # Produces the device string to be given to KVM to refer to this
  # disk device. Any extra options passed will be appended to the
  # generated string.
  def dev_string(opts='')
    '-drive index=%d,media=%s,if=%s%s,file=%s' % 
      [position, media_type.name, disk_type.name, extra_params(opts), filepath]
  end

  # Can we use this disk image for a regular VM instance (i.e. not a
  # "maintenance mode" one)? This means: Does this disk device exist?
  # Is it readable by our user?
  def available_for_vm?
    File.exists?(filepath) and File.readable?(filepath)
  end

  # Can we use this disk image for a maintnance-mode VM instance? This
  # means: Is this file available for regular use? (see
  # #available_for_vm?)? Is it writable by our user?
  def available_for_maintenance?
    available_for_vm? and File.writable?(filepath)
  end

  # Copies an existing DiskDev - This means, copy an existing DiskDev
  # image (i.e. file) to a new one, and create a new entry for it in
  # the DB. Returns the newly created object.
  #
  # In case the file cannot be copied, a new object will not be
  # created, and a suitable exception will be raised (or rather, we
  # will not catch it - Be prepared to handle the exceptions that
  # #File.copy would generate). If the specified filepath already
  # exists, an #Errno::EEXIST exception is raised.
  # 
  # If a new name is provided as a second parameter, it will be set to
  # the copied DiskDev; otherwise, the string " (1)" will be appended
  # to the original name. If this name also exists, the number will be
  # increased until a free one is found. If the name was explicitly
  # specified and it is already taken, an ActiveRecord::RecordInvalid
  # exception will be raised.
  def copy(newfile, newname=nil)
    cloned = nil

    newpath = File.join(Sysconf.value_for(:disk_dev_path), newfile)

    self.transaction do
      begin
        raise Errno::EEXIST, newpath if File.exists?(newpath)
        # File.copy raises exceptions when it fails - Add the explicit
        # raise only as a catch-all
        FileUtils::copy(filepath, newpath) or raise Errno::ENOENT

        cloned = self.clone
        cloned.filename = newfile
        cloned.name = gen_name_for_copy(newname)
        cloned.save!

      rescue => err
        # Remove the created file - Unless, of course, it was not
        # created by us, and propagate the exception to the caller
        File.unlink(newpath) unless err.is_a? Errno::EEXIST
        raise err
      end
    end

    cloned
  end

  # The disk size of an image. Note that this is the space it actually
  # uses in the host's HD. - Some images (i.e. using the QCow format)
  # will be allocated requiring much less space than what they report
  # to the guest systems (and grow only on demand); the actual file
  # assigned space is reported. On the other hand (and, yes, this is
  # counter-intuitive - but we are using OS-provided information!),
  # sparse files are reported with their full space assignation, not
  # counting out their empty areas.
  def size
    File.size(filepath)
  end

  # Full pathname to this image's file (i.e. including the systemwide
  # path).
  def filepath
    File.join(SysConf.value_for(:disk_dev_path), filename)
  end

  private
  # Appends optional (or detected) parameters (usually to the device
  # string generated by #dev_string)
  def extra_params(opts='')
    res = opts
    # SCSI and virtio devices require adding explicitly 'boot=on'
    res << ',boot=on' if media_type.name =~ /^(scsi|virtio)$/
    # Activate snapshot mode unless we are in maintenance mode
    res << ',snapshot=on' if profile.maint_mode?
    res
  end

  # Generates the name for copying an image file. If a newname is
  # received, it is returned back. Otherwise, a number (starting at 1,
  # until we find a free number) will be appended to the name we are
  # copying from.
  def gen_name_for_copy(newname=nil)
    return newname if newname
    copy_num = 1

    while !newname or self.class.find_by_name(newname)
      newname = "#{name} (#{copy_num})"
      copy_num += 1
    end

    newname
  end
end
