#!/usr/bin/ruby
require 'gtk2'
require 'open-uri'
require 'optparse'
require 'singleton'

class TerminalLauncher
  VERSION = 0.01

  def initialize
    window = AppWindow.instance

    if ! TermConfig.for(:gui_at_startup)
      begin
        TerminalControl.launch
      rescue => err
        StatusArea.instance.set(:error, err)
      end
    end

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
      @opts = {:server_url => 'http://132.248.72.73:3030/terminals/config',
        :gui_at_startup => false,
        :title => 'Administrador de terminal gráfica'
      }

      OptionParser.new do |opts|
        opts.on('-v', '--version', 
                'Prints the current program version and exits'
                ) { puts "#{$0} Version #{VERSION}"; exit 0}
        opts.on('-uURL', '--url URL',
                'Specifies the configuration URL'
                 ) { |@opts[:server_url]| }
        opts.on('-t', '--title [TITLE]',
                'Sets a custom program title label'
                ) { |@opts[:title]| }
        opts.on('-g', '--gui-at-startup', 
                'Launches the GUI interface at startup, instead of ',
                'launching the terminal'
                ) { |@opts[:gui_at_startup]| }
        opts.on_tail('-h', '--help', 'Show this message') {puts opts; exit 0}
      end.parse!
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
      # about it still.. Just put the exception in a place we can
      # show it to the user.
      cmd = self.get_cmd
      system(cmd)
      if $?.exited? and $?.exitstatus.to_i != 0
        raise RuntimeError, ['Error ejecutando el siguiente comando:', cmd,
                             [$?.pid, $?.exited?, $?.exitstatus].join('-')
                             ].join("\n")
      end
    end

    # Retrieves the command line from the server
    def self.get_cmd
      url = TermConfig.for :server_url
      server = open(url) or 
        raise IOError, "Error al solicitar la configuración en #{url}"
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
        begin
          TerminalControl.launch
        rescue => err
          status.set(:error, err)
        end
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
      self.version = VERSION.to_s
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
      actions = Gtk::MenuItem.new('_Acciones')
      contents = Gtk::Menu.new
      actions.set_submenu(contents)

      launch_item = Gtk::ImageMenuItem.new(Gtk::Stock::CONNECT)
      launch_item.signal_connect('activate') do
        begin        
          TerminalControl.launch
        rescue => err
          StatusArea.instance.set(:error, err)
        end
      end

      info_item = Gtk::ImageMenuItem.new(Gtk::Stock::INFO)
      info_item.signal_connect('activate') do
        status = :info
        begin
          res = TerminalControl.get_cmd
        rescue => err
          status = :err
          res = err
        end
        StatusArea.instance.set(status, 
                                ['URL del servidor de configuración:', 
                                 TermConfig.for(:server_url), '',
                                 'Información recibida:', res].join("\n"))
      end

      quit_item = Gtk::ImageMenuItem.new(Gtk::Stock::QUIT)
      quit_item.signal_connect('activate') {Gtk.main_quit}

      [launch_item, info_item, quit_item].each {|i| contents.append(i)}

      actions
    end

    def help_menu
      help = Gtk::MenuItem.new('Ay_uda')
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
    def initialize(msg=nil)
      super
      @label = Gtk::Label.new('')
      @label.wrap = true
      @label.justify=Gtk::JUSTIFY_CENTER
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
      ### TO DO: Status defines an icon
      #    statuses = {:ready => Gtk::Stock::Algo,
      #      :error => Gtk::Stock::DIALOG_ERROR,
      #      :ok => Gtk::Stock::Otro}
      @label.text = msg.to_s
    end
  end
end

TerminalLauncher.new

