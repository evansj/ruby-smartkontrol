module Akontrol
  class Message
    FORMAT = { :variable => /a(.)(..)(.)(.*)\r/,
               :fixed    => /a(.)(..)(.)(.{7})/ }.freeze
               
    attr_accessor :format, :id, :type, :command, :payload

    def initialize(format, type, id, command, payload=nil)
      throw ArgumentError.new("format must be :variable or :fixed (not #{format.inspect})") unless FORMAT.include?(format)
      @format, @type, @id, @command, @payload = format, type, id, command, payload
    end

    def self.parse(format, message_string)
      if message_string =~ FORMAT[format]
        new(format, $~[1], $~[2], $~[3], $~[4])
      end
    end
    
    def self.build(format, type, id, command, *payload)
      new(format, type, id, command, payload.map{|a|a.to_s}.join)
    end
    
    def to_s
      case @format
      when :variable
        "a#{type}#{id}#{command}#{payload}\r"
      when :fixed
        "a#{type}#{id}#{command}#{payload}".ljust(12, '-')
      end
    end
    
  end

end