# Authorized system users are represented by the #Sysuser class. 
#
# === Attributes
#
# [name] The user's full name
#
# [login] The login that the user will present to the system
#
# [admin] A boolean value indicating whether this user is an
#         administrative or a regular user.
#
# [pw_salt] An autogenerated random string that, mixed with the user's
#           password, is used to generate the passwd attribute. This
#           attribute does not need to be directly accessed from the
#           outside.
# 
# [passwd] A MD5 digest of the concatenation of the #pw_salt and the
#          user's password; this attribute does not need to be
#          directly accessed from the outside - To query whether a
#          password is correct, use the #ck_login method, and to
#          change the password, use #passwd=
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
