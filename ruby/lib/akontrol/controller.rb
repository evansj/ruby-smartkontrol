require "serialport.so"

module Akontrol
  class Controller
    DEFAULT_PORT_OPTIONS = {:baud => 115200, :data_bits => 8, :stop_bits => 1, :parity => SerialPort::NONE}
  
    attr_reader :serialport
    attr_reader :devices
  
    def initialize(port, options={})
      opts = DEFAULT_PORT_OPTIONS.merge(options)
      @serialport = SerialPort.new(port, opts[:baud], opts[:data_bits], opts[:stop_bits], opts[:parity])
      throw IOError.new( "Couldn't connect") unless @serialport
      @serialport.read_timeout = 500

      # this will hold a hash of devices, by device id
      @devices = {}
      # this will hold the incoming messages
      @message = ""
    end
  
    def add_device(device)
      device.controller = self
      @devices[device.id] = device
    end
  
    def send(message)
      @serialport.print message.to_s
      get_message
    end
  
    def close
      @serialport.close if @serialport
    end
  
    def get_message(timeout=0.5)
      start = Time.now
      while Time.now - start < timeout do
        c = @serialport.getc
        @message << c if c
        if has_message
          process_message
          start = Time.now
        end
      end
    end

    private
  
    def has_message
      # see if we have a valid message somewhere in the buffer
      @message =~ Message::FORMAT
    end
  
    def process_message
      if offset = @message =~ Message::FORMAT
        # remove the message chars from the message buffer
        @message[0..(offset+11)] = ''

        message = Message.parse($~[0])

        # pass on the message to the appropriate device object
        device = @devices[message.id]
        device.process_message(message) if device
      end
    end
  
    def read_and_print(timeout=0.5)
      start = Time.now
      while Time.now - start < timeout do
        c = @serialport.getc
        printf("%c", c) if c
      end
    end
  
  end
end