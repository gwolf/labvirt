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
  has_many :term_params

  # The server address is not validated - we can often get here
  # symbolic hostnames instead of IP addresses
  validates_presence_of :ipaddr
  validates_presence_of :serveraddr
  validates_presence_of :term_class_id
  validates_uniqueness_of :ipaddr
  validates_format_of :ipaddr, :with => /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\Z/
  validates_associated :term_class

  # Builds the command line to be called based on the #path to run
  # and #client_params methods (both coming from the #TermClass).
  def client_command_line(options={})
    "#{term_class.path} #{client_params(options)}"
  end

  # Builds the parameters for the client command line, substituting
  # where pertinent the values from #client_param_hash.
  #
  # Each of the options is replaced where its corresponding template
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
    params = client_param_hash(options)
    cmd = term_class.params || ''

    params.keys.each do |k|
      tmpl = "%#{k.to_s.upcase}%"
      # Elements are explicitly converted into strings - You will get
      # exceptions otherwise
      cmd.gsub! /#{tmpl}/, params[k].to_s
    end
    cmd
  end

  # Builds the substitution hash from the terminal's #serveraddr (as
  # HOST), term_params (replacing their corresponding uppercase key)
  # and the options received when calling this method. As an example,
  # if this terminal's #serveraddr is '127.0.0.1' and the two
  # following #TermParams are specified:
  #
  #   {:name => 'user', :value => 'foo'}
  #   {:name => 'passwd', :value => 'pr1vat3'}
  #
  # calling #client_param_hash with no options will return:
  #
  #   term.client_param_hash
  #   => { 'USER' => 'foo', 'PASSWD => 'pr1vat3', 'HOST' => '127.0.0.1' }
  # 
  # Any options specified when calling this method will be added, or
  # will override the value. On the same #Terminal,
  #
  #   term.client_param_hash(:host => 'some.where.org')
  #   => { 'USER' => 'foo', 'PASSWD => 'pr1vat3', 'HOST' => 'some.where.org' }
  def client_param_hash(options={})
    params = { 'HOST' => serveraddr }
    term_params.each {|tp| params[tp.name.to_s.upcase] = tp.value}
    options.keys.each do |opt|
      params[opt.to_s.upcase] = options[opt] 
    end

    params
  end

  # Returns the #TermParam this terminal has defined for the given
  # name. Returns nil if no matching #TermParam exists
  def term_param(name)
    term_params.select {|t| t.name == name}[0]
  end

  # Gets the list of parameters needed by this terminal's current
  # #TermClass - This means, all the parameters specified in the
  # #TermClass' #params
  def needed_params
    param_str = String.new(term_class.params)
    res = []
    while param_str.sub! /%([^%\s]+)%/, '' do
      res << $1
    end
    res.sort
  end

  def missing_params; needed_params - client_param_hash.keys; end
  def params_complete?; missing_params.empty?; end
end
