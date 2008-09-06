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

      # this will hold a hash of devices, by device id
      @devices = {}
      # this will hold the incoming messages
      @message = ""
      
      start_reader
      
    end
  
    def start_poller
      @serialport.read_timeout = 500
    end
  
    def start_reader
      @serialport.read_timeout = 10
      @readerthread = Thread.new {
        begin
          while true
            # puts "reading serial port..."
            c = @serialport.sysread(1)
            if c
              # puts "reader thread got #{c}"
              @message << c 
              if has_message
                process_message
              end
            end
          end
        rescue IOError => e
          # puts "IOError #{e}"
        end
      }
    end
  
    def add_device(device)
      device.controller = self
      @devices[device.id] = device
    end
  
    def send(message)
      msg = message.to_s
      puts "sending #{msg}"
      bytes_written = 0
      while bytes_written < msg.length do
        bytes_written += @serialport.syswrite message.to_s
      end
    end

    def wait_for_reply
      sleep 0.5
    end
  
    def close
      puts "closing..."
      sleep 0.5
      @serialport.close if @serialport
      @readerthread.join
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