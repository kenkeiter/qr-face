module QRMirror

  def config=(cfg)
    @config = cfg
  end

  def config
    @config
  end

  module_function :config=, :config

  class Initializer

    def self.start(config_path)
      config = YAML::load(File.read(config_path))
      config[:config_path] = config_path
      QRMirror.config = config

      EventMachine.run do
        camera = QRMirror::Camera.new(
          config['capture_source']['url'], 
          config['capture_source']['username'], 
          config['capture_source']['password'])
        camera.capture(config['capture_source']['buffer_length'])
        QRMirror::FaceServer.capture_source = camera
        EventMachine.start_server(config['server']['host'], config['server']['port'], QRMirror::FaceServer)
        puts "Started successfully."
      end

    end

  end

end