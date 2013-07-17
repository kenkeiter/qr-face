module QRMirror

  class FaceServer < EventMachine::Connection
    include EventMachine::HttpServer

    def self.capture_source=(cap)
      @@camera = cap
    end

    def post_init
      super
      no_environment_strings
    end

    def random_filename(length = 10, extension = '.jpg')
      charset = %w{ 2 3 4 6 7 9 A C D E F G H J K M N P Q R T V W X Y Z}
      (0...length).map{ charset.to_a[rand(charset.size)] }.join + extension
    end

    def not_found
      response = EventMachine::DelegatedHttpResponse.new(self)
      response.status = 404
      response.content_type 'text/html'
      response.content = 'Not Found'
      response.send_response
    end

    def s3_uri(filename)
      "http://#{QRMirror.config['amazon_ec2']['bucket_name']}.s3.amazonaws.com/#{filename}"
    end

    def new_capture
      filename = random_filename
      
      do_upload = proc do
        $stdout.write "Creating item..."
        item = Happening::S3::Item.new(
          QRMirror.config['amazon_ec2']['bucket_name'], 
          filename, 
          :aws_access_key_id => QRMirror.config['amazon_ec2']['key_id'], 
          :aws_secret_access_key => QRMirror.config['amazon_ec2']['secret_key'], 
          :permissions => 'public-read')
        item.put(@@camera.capture_buffer[0], :headers => {'Content-Type' => 'image/jpeg'}) do
          puts "Uploaded image to: #{s3_uri(filename)}"
        end
      end

      EventMachine.defer(do_upload)

      response = EventMachine::DelegatedHttpResponse.new(self)
      response.status = 200
      response.content_type 'application/json'
      response.content = [Time.now, s3_uri(filename)].to_json
      response.send_response
    end

    def static_file(path)
      base_config_path = File.dirname(QRMirror.config[:config_path])
      static_base = File.expand_path(QRMirror.config['server']['static_path'])
      path = File.join(base_config_path, static_base)

      response = EventMachine::DelegatedHttpResponse.new(self)
      response.status = 404
      response.content_type 'text/html'
      response.content = File.read(File.join(static_base, path))
      response.send_response
    end

    def process_http_request
      # old-school (read: crappy) request routing
      return static_file 'capture.html' if @http_request_uri =~ /^\/$/
      return new_capture if @http_request_uri =~ /^\/photo.json$/
      return not_found
    end
  end

end