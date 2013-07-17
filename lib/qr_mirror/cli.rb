module QRMirror

  class CLI < Thor

    desc 'start', 'Start the application.'
    method_option :config, :aliases => '-c', :default => './config.yml', :type => :string
    def start
      cfg_path = File.expand_path(options[:config])
      raise "Could not find config at specified path: #{cfg_path}" unless File.exists?(cfg_path)
      Initializer.start(cfg_path)
    end

  end

end