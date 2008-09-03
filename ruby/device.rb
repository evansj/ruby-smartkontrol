class Device
  attr_reader :id
  attr_accessor :controller
  
  RELAY = 5
  LED = 1
  
  def initialize(id)
    @id = id
  end

  def ping
    @controller.send command("E")
  end
  
  def get_capabilities
    @controller.send command("Y")
  end
  
  def relay=(val)
    output(RELAY, val)
  end

  def led=(val)
    output(LED, val)
  end
  
  def output(port, bool)
    @controller.send command("O", port.to_s, (bool ? 1 : 0))
  end
  
  private
  
  def command(name, *args)
    pad("aC" + @id + name + args.map{|a|a.to_s}.join)
  end
  
  def pad(message)
    (message + '------------')[0..11]
  end
end