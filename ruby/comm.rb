#!/usr/bin/env ruby

require 'controller'
require 'device'

# uses Ruby-SerialPort from http://ruby-serialport.rubyforge.org

port = "/dev/tty.usbserial-A5001pJU"

puts "connecting to serial port #{port}"
controller = Controller.new(port)
device = Device.new("S1")
controller.add_device device
while true do
  puts "\npinging #{device.id}"
  device.ping
  sleep 0.2
  
  puts "\nturning relay on"
  device.relay = true
  sleep 0.2
  
  puts "\nturning relay off"
  device.relay = false
  sleep 0.2

  puts "\nturning LED on"
  device.led = true
  sleep 0.2
  
  puts "\nturning LED off"
  device.led = false
  sleep 0.2
end

controller.close


