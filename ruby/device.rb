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
  
  def relay=(val)
    @controller.send command("O", RELAY, (val ? 1 : 0))
  end

  def led=(val)
    @controller.send command("O", LED, (val ? 1 : 0))
  end
  
  private
  
  def command(name, *args)
    pad("aC" + @id + name + args.map{|a|a.to_s}.join)
  end
  
  def pad(message)
    (message + '------------')[0..11]
  end
end