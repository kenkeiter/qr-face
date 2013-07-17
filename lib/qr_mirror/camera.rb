module QRMirror

  class FrameFIFOBuffer < Array

    alias_method :array_push, :push
    alias_method :array_element, :[]

    def initialize(size)
      @positions = size
      super(size)
    end

    def push(element)
      shift if length == @positions
      array_push element
    end

    def <<(element)
      push(element)
    end

    def [](offset = 0)
      return self.array_element(-1 + offset)
    end

    def snapshot
      buffer_clone = []
      self.each do |frame|
        next if frame.nil?
        buffer_clone << frame.dup unless frame.nil?
      end
      buffer_clone
    end

  end

  class Camera

    def initialize(mjpeg_url, username, password)
      @url = mjpeg_url
      @username, @password = username, password
      @fps = 0
    end

    def capture(buffer_length = 30)
      raise 'Camera#capture called outside EM loop.' unless EventMachine.reactor_running?
      @buffer = FrameFIFOBuffer.new(buffer_length)
      begin
        http = EventMachine::HttpRequest.new(@url).get(:head => {'authorization' => [@username, @password]})

        http.stream do |chunk|
          # Handle the beginning of a new content boundary
          if chunk =~ /Content-Length:\w*\s*([0-9]*)/i
            @frame_length = chunk.match(/Content-Length:\w*\s*([0-9]*)/i)[1].to_i
            @curr_frame = "" # begin a new frame
            next # ignore this chunk
          end

          # Handle content boundary by completing frame.
          if chunk == "\r\n" or @curr_frame.length >= @frame_length
            @buffer << @curr_frame unless @curr_frame.nil?
            next
          end

          # Append the content if everything else is okay.
          @curr_frame += chunk
        end

      rescue => e
        raise e
      end
    end

    def capture_buffer
      @buffer.snapshot
    end

  end

end