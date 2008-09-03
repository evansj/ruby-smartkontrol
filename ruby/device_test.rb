#!/usr/bin/env ruby

require 'test/unit'
require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'
require 'controller'
require 'device'

# uses Ruby-SerialPort from http://ruby-serialport.rubyforge.org

class DeviceTest < Test::Unit::TestCase
  def setup
    @controller = Controller.new(@@port)
    @device = Device.new(@@device_id)
    @controller.add_device @device
  end
  
  def teardown
    @controller.close if @controller
  end
  
  def test_ping
    puts "\npinging #{@device.id}"
    @device.ping
  end
  
  def test_get_capabilities
    puts "\ngetting capabilities"
    @device.get_capabilities
  end

  def test_relay
    puts "\nturning relay on"
    @device.relay = true

    puts "\nturning relay off"
    @device.relay = false
  end

  def test_led
    puts "\nturning LED on"
    @device.led = true

    puts "\nturning LED off"
    @device.led = false
  end


  def self.port=(port)
    @@port = port
  end
  def self.device_id=(device_id)
    @@device_id = device_id
  end
end

if $0 == __FILE__
  if ARGV.length != 2
    puts "Usage: ruby device_test.rb device_id serialport\n\ne.g. ruby device_test.rb S1 /dev/tty.usbserial-A5001pJU"
    exit 1
  else
    puts "Testing device #{ARGV[0]} with serial port #{ARGV[1]}"
    DeviceTest.device_id = ARGV[0]
    DeviceTest.port = ARGV[1]
  end
end

class DeviceTests
  def self.suite
    suite = Test::Unit::TestSuite.new "Device tests"
    suite << DeviceTest.suite
    return suite
  end
end
Test::Unit::UI::Console::TestRunner.run(DeviceTests)