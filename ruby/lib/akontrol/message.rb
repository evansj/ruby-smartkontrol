module Akontrol
  class Message
    FORMAT = /a.{4,}\r/
    
    class Command < Message
    end
  
    class Reply < Message
    end
  
    class Alert < Message
    end
    
    class Capability < Message
    end

    TYPES = {'C' => Command, 'R' => Reply, 'A' => Alert, 'Y' => Capability}
    attr_accessor :id, :type, :command, :payload

    # return a message object if the message is valid, or nil otherwise
    def self.parse(message_string)
      # puts "Parsing message '#{message_string}'"
      # extract the command type, device id, command, and payload
      if message_string =~ /a(.)(..)(.)(.*)\r/
        message = TYPES[$~[1]].new
        message.type = $~[1]
        message.id = $~[2]
        message.command = $~[3]
        message.payload = $~[4]
        message
      end
    end
    
    def self.build(type, id, command, *payload)
      message = TYPES[type].new
      message.type = type
      message.id = id
      message.command = command
      message.payload = payload.map{|a|a.to_s}.join
      message
    end
    
    def to_s
      # "a#{type}#{id}#{command}#{payload}".ljust(12, '-')
      "a#{type}#{id}#{command}#{payload}\r"
    end
  end
end