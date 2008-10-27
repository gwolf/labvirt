class Sysuser < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :passwd
  validates_presence_of :login
  validates_uniqueness_of :login

  def self.ck_login(given_login, given_passwd)
    sysuser = self.find_by_login(given_login)
    return false if sysuser.blank? or
      sysuser.passwd != Digest::MD5.hexdigest(sysuser.pw_salt + given_passwd)

    sysuser
  end

  def passwd= plain
    # Don't accept empty passwords!
    return nil if plain.blank? or /^\s*$/.match(plain)
    self.pw_salt = gen_salt
    self['passwd'] = Digest::MD5.hexdigest(pw_salt + plain)
  end

  private
  def pw_salt
    self[:pw_salt]
  end

  def gen_salt
    low = 48
    high = 126
    Array.new(8).map {(rand(high-low) + low).chr}.join
  end
end
