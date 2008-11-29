#!/usr/bin/ruby
require 'gtk2'
require 'open-uri'
require 'optparse'
require 'singleton'

Version=0.01

# = terminal_launcher
#
# This is the main Terminal Launcher application - This program should
# be run at Labvirt terminals. It will query the server for the
# configuration it should use, and launch the fitting
# terminal. 
#
# The usual behaviour is the terminal gets launched as soon as the
# program is loaded, not even showing our interface to the user
# beforehand; this can be overriden by the <tt>--gui-at-startup</tt>
# (or <tt>-g</tt> for short) command line.
#
# == Usage scenario
#
# Terminals controlled by this program will often have it as an action
# performed automatically upon bootup, just after the X server has
# been brought up. One of the simplest ways to achieve it on a stock
# distribution is to configure your login manager (i.e. gdm) to
# automatically log in as a specific user, using this user's .xsession
# script. Please check further below on how to achieve this.
#
# The .xsession script is the traditional way of specifying a set of
# actions a user will perform at session startup (that is, outside of
# modern desktop environments, as Gnome or KDE, which manage this in a
# different way). 
#
# Assuming terminal_launcher is installed in /usr/bin, and that your
# Labvirt configuration server is at
# http://192.168.0.1/terminals/config, create a .xsession file in the
# user's home directory, consisting of only the following line:
#
#    /usr/bin/terminal_launcher -u http://192.168.0.1/terminals/config
#
# Mark this script as executable - From a terminal in this user's
# session:
#
#    $ chmod 755 .xsession
#
# That's all there is to it. Now, modify your login manager: In gdm,
# choose 'Actions' -> 'Configure the login manager'. Provide your root
# password. In the 'General' tab, activate 'Default session', and
# specify 'Run Xclient script'. 
# 
# Before leaving the gdm configuration, we can ask it to just step out
# of the picture, getting your terminal logged in automatically. To do
# this, go to the 'Security' tab, and select 'Enable Automatic
# Login'. Choose the desired system user, and you are set. Click
# 'Close'. Next time this computer boots, gdm will just step away and
# bring up your terminal.
#
# == Command-line parameters
#
# terminal_launcher can be invoked with the following command-line
# switches:
#
# [-v, --version] Prints the current program version and exits
#
# [-u, --url URL] Specifies the configuration URL. This is a mandatory
#                 argument. Most probably, this URL will be
#                 </tt>http://<em>your-server</em>/terminals/config,
#                 which is the location where Labvirt serves the
#                 terminal configuration parameters.
#
# [-t, --title TITLE] Sets a custom program title label to show to
#                      users; defaults to "Graphic Terminal
#                      Administrator"
#
# [-g, --gui-at-startup] Launches the GUI interface at startup,
#                         instead of launching the terminal
#
# [--hide-shutdown] Hides the system shutdown action. Defaults to
#                   showing it.
#
# [--shutdown-cmd CMD] Specifies the command for shutdown. This option
#                      overrides --hide-shutdown - If bothare set,
#                      --hide-shutdown is innefective. Defaults to
#                      '/usr/bin/sudo /sbin/halt'
#
# [-h, --help ] Prints a summary of the command-line options.
#
# == TO DO
#
# - Incorporate gettext so that every message is I18Nized Monitor the
# - launched terminal, wait for it, or report if it died successfully
#   too fast
# - Provide a GUIstic way to enter the config URL
# - Do some sanity checks (i.e. that a real program name is requested). 
#   Maybe only launch known/approved programs? (that can surely hurt...)
# - Add an action to spawn a xterm?
class TerminalLauncher
  def initialize
    window = AppWindow.instance

    TerminalControl.launch if ! TermConfig.for(:gui_at_startup)

    window.show_all
    Gtk.main
  end

  private
  # Handles the terminal configuration parameters - Has the default
  # settings. Includes the parsing for the command-line specified
  # options.
  class TermConfig
    include Singleton
    # Defines the default parameters, and parses the command
    # line. Does not need to be explicitly called - The first call to
    # #TermConfig.for will call it
    def self.parse_opts
      @opts = {:server_url => nil,
        :gui_at_startup => false,
        :title => 'Graphic Terminal Administrator',
        :shutdown_cmd => '/usr/bin/sudo /sbin/halt',
        :hide_shutdown => false
      }

      OptionParser.new do |opts|
        opts.on('-v', '--version', 
                'Prints the current program version and exits'
                ) { puts "#{File.basename($0)} Version #{Version}"; exit 0}
        opts.on('-uURL', '--url URL',
                'Specifies the configuration URL. This is a mandatory',
                'argument. Most probably, this URL will be',
                '</tt>http://<em>your-server</em>/terminals/config,',
                'which is the location where Labvirt serves the',
                'terminal configuration parameters.') { |@opts[:server_url]| }
        opts.on('-t', '--title [TITLE]',
                'Sets a custom program title label to show to',
                'users; defaults to "Graphic Terminal Administrator'
                ) { |@opts[:title]| }
        opts.on('-g', '--gui-at-startup', 
                'Launches the GUI interface at startup, instead of ',
                'launching the terminal'
                ) { |@opts[:gui_at_startup]| }
        opts.on('--hide-shutdown', 'Hides the system shutdown action.',
                'Defaults to showing it.'
                ) { |@opts[:hide_shutdown]| }
        opts.on('--shutdown-cmd CMD', 'Specifies the command for',
                'shutdown. This option overrides --hide-shutdown - If both',
                'are set, --hide-shutdown is innefective. Defaults to ',
                "'/usr/bin/sudo /sbin/halt'"
                ) { |@opts[:shutdown_cmd]| @opts[:hide_shutdown]=false }
        opts.on_tail('-h', '--help', 'Prints a summary of the command-line options'
                     ) {puts opts; exit 0}
      end.parse!
      if TermConfig.for(:server_url).nil?
        warn "#{$0}: You must specify the server URL, with -u or --url"
        exit 1 
      end
    end

    # Retrieves a configuration entry. Receives the corresponding key.
    def self.for(what)
      self.parse_opts if @opts.nil?
      @opts.has_key?(what) or raise NameError, "Invalid key #{what}"
      @opts[what]
    end
  end

  # Controls the terminal to be launched
  class TerminalControl
    include Singleton
    # Launches the terminal, with the server-supplied command
    def self.launch
      # This might cause all kinds of exceptions - Don't think much
      # about it, just report them to the user.
      cmd = self.get_cmd
      begin
        system(cmd)
        if $?.exited? and $?.exitstatus.to_i != 0
          begin
            raise RuntimeError, ['Error running requested command:', cmd,
                                 [$?.pid, $?.exited?, $?.exitstatus].join('-')
                                ].join("\n")
            StatusArea.instance.set(:ok, "The terminal was started successfully")
          rescue => err
            StatusArea.instance.set(:error, err)
          end
        end
      end
    end

    # Retrieves the command line from the server
    def self.get_cmd
      url = TermConfig.for :server_url
      server = open(url) or 
        raise IOError, "Error requesting the configuration at #{url}"
      server.read
    end
  end

  # Handles the application window, as well as the basic interface events
  class AppWindow < Gtk::Window
    include Singleton
    def initialize
      super(TermConfig.for(:title))
      set_size_request(640, 480)
      box = Gtk::VBox.new(nil, 10)
      self.add(box)

      buttonbox = Gtk::HButtonBox.new
      menu = AppMenu.instance
      status = StatusArea.instance

      launch_btn = Gtk::Button.new(Gtk::Stock::CONNECT)
      launch_btn.signal_connect('clicked') do
        TerminalControl.launch
      end

      quit_btn = Gtk::Button.new(Gtk::Stock::QUIT)
      quit_btn.signal_connect('clicked') {Gtk.main_quit}

      buttonbox.pack_start(launch_btn)
      buttonbox.pack_start(quit_btn)

      box.pack_start(menu,false,true,0)
      box.pack_start(TitleLabel.instance)
      box.pack_start(status)
      box.pack_start(buttonbox)
    end
  end

  # Shows the 'about' information window
  class AboutWindow < Gtk::AboutDialog
    def initialize
      super
      self.copyright = 'Instituto de Invesitgaciones Económicas UNAM'
      self.authors = ['Gunnar Wolf <gwolf@gwolf.org>']
      self.program_name = "Labvirt - #{TermConfig.for(:title)}"
      self.version = Version.to_s
      self.website = 'http://www.github.com/gwolf/labvirt'
      signal_connect('response') {destroy}

      show
    end
  end

  # Represents the system menu
  class AppMenu < Gtk::MenuBar
    include Singleton
    def initialize
      super
      append(actions_menu)
      append(help_menu)
      show_all
    end

    def actions_menu
      actions = Gtk::MenuItem.new('_Actions')
      contents = Gtk::Menu.new
      actions.set_submenu(contents)

      launch_item = Gtk::ImageMenuItem.new(Gtk::Stock::CONNECT)
      launch_item.signal_connect('activate') do
        TerminalControl.launch
      end

      info_item = Gtk::ImageMenuItem.new(Gtk::Stock::INFO)
      info_item.signal_connect('activate') do
        status = :ok
        begin
          res = TerminalControl.get_cmd
        rescue => err
          status = :error
          res = err
        end
        StatusArea.instance.set(status, 
                                ['Configuration server URL:', 
                                 TermConfig.for(:server_url), '',
                                 'Received information:', res].join("\n"))
      end

      halt_item = Gtk::ImageMenuItem.new('_Shut down the computer')
      halt_item.image=Gtk::Image.new(Gtk::Stock::DISCONNECT, Gtk::IconSize::MENU)
      halt_item.signal_connect('activate') {
        system(TermConfig.for(:shutdown_cmd))
      }

      quit_item = Gtk::ImageMenuItem.new(Gtk::Stock::QUIT)
      quit_item.signal_connect('activate') {Gtk.main_quit}

      [launch_item, info_item, quit_item].each {|i| contents.append(i)}
      contents.append(halt_item) unless TermConfig.for(:hide_shutdown)

      actions
    end

    def help_menu
      help = Gtk::MenuItem.new('_Help')
      contents = Gtk::Menu.new
      help.set_submenu(contents)
      
      about_item = Gtk::ImageMenuItem.new(Gtk::Stock::ABOUT)
      contents.append(about_item)
      about_item.signal_connect('activate') {AboutWindow.new}

      help
    end
  end

  # The label showing the program name
  class TitleLabel < Gtk::Label
    include Singleton
    def initialize
      super
      set_markup("<big><b>#{TermConfig.for(:title)}</b></big>")
      justify=Gtk::JUSTIFY_CENTER
    end
  end

  # An updatable status area, to be shown in the main area of the
  # #AppWindow
  class StatusArea < Gtk::HBox
    include Singleton
    Statuses = {:ready => nil,#Gtk::Stock::MEDIA_STOP,
      :error => Gtk::Stock::DIALOG_ERROR,
      :ok => Gtk::Stock::YES}
    def initialize(msg=nil)
      super
      @image = Gtk::Image.new(Statuses[:ready], Gtk::IconSize::LARGE_TOOLBAR)
      @label = Gtk::Label.new('')
      @label.wrap = true
      @label.justify=Gtk::JUSTIFY_CENTER
      pack_start(@image)
      pack_start(@label)
      
      set(:ready, msg)
    end

    # Changes the currently displayed status. Accepts a status
    # identifier (that will show the relevant icon) and an optional
    # message string.
    # 
    # Accepted status identifiers are :ready, :error, :ok. If any
    # other value is specified, no icon will be shown.
    def set(status, msg=nil)
      status = :ready unless Statuses.include? status
      @image.stock = Statuses[status]
      @label.text = msg.to_s
    end
  end
end

# Were we called directly? Launch the interface!
TerminalLauncher.new if __FILE__ == $0

