require "serialport.so"

class Controller
  DEFAULT_PORT_OPTIONS = {:baud => 115200, :data_bits => 8, :stop_bits => 1, :parity => SerialPort::NONE}
  
  attr_reader :serialport
  attr_reader :devices
  
  def initialize(port, options={})
    opts = DEFAULT_PORT_OPTIONS.merge(options)
    @serialport = SerialPort.new(port, opts[:baud], opts[:data_bits], opts[:stop_bits], opts[:parity])
    throw IOError.new( "Couldn't connect") unless @serialport
    @serialport.read_timeout = 500
    @devices = []
  end
  
  def add_device(device)
    device.controller = self
    @devices << device
  end
  
  def send(message)
    @serialport.print message
    read_and_print
  end
  
  def close
    @serialport.close if @serialport
  end
  
  private
  
  def read_and_print(timeout=0.5)
    start = Time.now
    while Time.now - start < timeout do
      c = @serialport.getc
      printf("%c", c) if c
    end
  end
  
end