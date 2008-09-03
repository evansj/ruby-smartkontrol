module Akontrol
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
  
    def process_message(message)
      puts "Received message #{message}"
    end
  
    private
  
    # build a Message object for the requested command
    def command(name, *args)
      Message.build("C", @id, name, *args)
    end
  end
end