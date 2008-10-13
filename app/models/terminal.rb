# A #Terminal is a computer that will connect to each of the instances
# of our #Laboratory and be used. We think of a #Terminal as a thin
# client - A machine able only to set up networking and ask the server
# (via network, of course) for the command line for the virtual host
# it will become a server for.
#
# In practice, a #Terminal should probably belong to a #Laboratory -
# However, we are not implementing that relation still, because there
# is simply no point in making the relation - Each of the machines in
# a #Laboratory defines only its MAC base address; implementing the
# relation between MAC and IP addresses (probably via DHCP) is outside
# the scope of this program - at least, for the time being.
#
# === Attributes
#
# [ipaddr] The IP address this terminal has. This will act as the key
#          for which configuration it should be served.
#
# [serveraddr] The IP address of the server it should connect to
class Terminal < ActiveRecord::Base
  belongs_to :term_class

  # The server address is not validated - we can often get here
  # symbolic hostnames instead of IP addresses
  validates_presence_of :ipaddr
  validates_presence_of :serveraddr
  validates_presence_of :term_class_id
  validates_uniqueness_of :ipaddr
  validates_format_of :ipaddr, :with => /\A(?:(?:25[0-5]|2[0-4][0-9]|01?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|01?[0-9][0-9]?)\Z/
  validates_associated :term_class

  # Builds the command line to be called based on the #path to run
  # and #client_params methods (both coming from the #TermClass).
  def client_command_line(options={})
    "#{term_class.path} #{client_params(options)}"
  end

  # Builds the client parameters, based on the received options. Each
  # of the options is replaced where its corresponding template
  # appears on the #TermClass.params definition. As an example, if
  # #TermClass.params is:
  #
  #   -u %USER% -p %PASSWD% -h %HOST%
  #
  # and this method is invoked with:
  #
  #   term.client_params(:user => 'john', :passwd => 'pr1vat3', 
  #                      :host => '127.0.0.1')
  #
  # the result will be:
  #
  #   -u john -p pr1vat3 -h 127.0.0.1
  def client_params(options={})
    cmd = term_class.params
    options.keys.each do |k|
      tmpl = "%#{k.to_s.upcase}%"
      cmd.gsub! /#{tmpl}/, options[k]
    end
    cmd
  end
end