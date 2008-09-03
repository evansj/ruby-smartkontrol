module Akontrol
  class Message
    class Command < Message
    end
  
    class Reply < Message
    end
  
    class Alert < Message
    end

    TYPES = {'C' => Command, 'R' => Reply, 'A' => Alert}
    attr_accessor :id, :command, :payload

    # return a message object if the message is valid, or nil otherwise
    def self.parse(message_string)
      # extract the command type, device id, command, and payload
      if message_string =~ /a(.)(..)(.)(.{7})/
        message = TYPES[$~[1]].new
        message.id = $~[2]
        message.command = $~[3]
        message.payload = $~[4]
        message
      end
    end
  end
end