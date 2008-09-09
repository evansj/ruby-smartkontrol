' ###############################################################################
' #### interrupt driven comms using hsersetup
' ####
' #### The interrupt routine sets has_packet to 1
' #### when a packet is available
' ###############################################################################

#picaxe 28x1
'#com /dev/tty.usbserial-000012FD

'###############################################################################
config:

' The sensor code of this module
symbol s1="S"
symbol s2="1"

' comment this out if necessary
#define HAS_RELAY

#ifdef HAS_RELAY
  ' Which pin is the relay connected to?
  symbol RELAY=5
#endif

'###############################################################################
symbol last_char = b10
symbol packet_start = b11
symbol packet_calc = b12
symbol packet_end = b13
symbol PACKET_LEN = 12
symbol led_counter = b14
' flash the LED after this many times through the main loop
symbol LED_PERIOD = 100
' how many scratch memory bytes are there?
symbol BUFFER_END = 127
symbol flags_byte = b0
symbol has_packet = bit0

#ifdef HAS_RELAY
  symbol RELAY_STR=RELAY+48 'relay pin number as an ASCII char
#endif

' Which pin is the LED connected to?
symbol LED=1

' XBee pins
symbol XBeeSleepPin = 6
symbol XBeeDataPin = 4
symbol XBeeResetPin = 7

setfreq m4
'configure serial port
hsersetup B4800_4, %01

gosub XBEEwake
pause 200

hserout 0,("aA",s1,s2,"STARTED-")
pause 100

' initialize packet pointers to 0
packet_start = 0
led_counter = LED_PERIOD
' enable the interrupt handler
setintflags %00100000,%00100000

'###############################################################################

main:
dec led_counter
if led_counter = 0 then
	led_counter = LED_PERIOD
	'brief blink of the led
	high portc LED
	pause 5
	low portc LED
endif

if has_packet = 1 then gosub packet_rx
pause 100 ' 0.1 second pause
goto main

' ###############################################################################
' Process the command that was received
' ###############################################################################
packet_rx:
has_packet=0
ptr = packet_start
packet_end = packet_start + PACKET_LEN
if packet_end > BUFFER_END then
	packet_end = packet_end - BUFFER_END - 1
endif
' loop looking for "a"
do
	b1 = @ptrinc
loop while b1 != "a" and ptr != packet_end
if b1 != "a" then finished_packet

' look for "C"
b1 = @ptrinc
if b1 != "C" then finished_packet

' look for the first byte of the device ID
b1 = @ptrinc
if b1 != s1 then finished_packet

' look for the second byte of the device ID
b1 = @ptrinc
if b1 != s2 then finished_packet

b1=@ptrinc
select b1
case "E"
	gosub sendEcho
case "Y"
	gosub displayCapabilities
case "O"
	b2 = @ptrinc
#ifdef HAS_RELAY
	if b2=RELAY_STR then gosub controlRelay
#endif
endselect

finished_packet:
packet_start = packet_start + PACKET_LEN
if packet_start > BUFFER_END then
	packet_start = packet_start - BUFFER_END - 1
endif
return

'###############################################################################
#ifdef HAS_RELAY
controlRelay:
b1 = @ptrinc
select b1
	case "0"
		low RELAY
	case "1"
		high RELAY
endselect
hserout 0,("aR",s1,s2,"O",RELAY_STR,b1,"-----")
return
#endif

'###############################################################################
XBEEwake:
high XBeeSleepPin
high XBeeDataPin
high XBeeResetPin
return

'###############################################################################
XBEEsleep:
low XBeeSleepPin
low XBeeDataPin
low XBeeResetPin
return

'###############################################################################
displayCapabilities:
'Echo
hserout 0,("aY",s1,s2,"E",CR)
#ifdef HAS_RELAY
	'Relay Output On
	hserout 0,("aY",s1,s2,"O",RELAY_STR,"0-----")
	'Relay Output Off
	hserout 0,("aY",s1,s2,"O",RELAY_STR,"1-----")
#endif
return

' ###############################################################################
sendEcho:
hserout 0,("aR",s1,s2,"HERE----")
return

' ###############################################################################
' if this interrupt routine is entered while the main thread is executing a
' pause statement, then on return the next statement after the pause will
' be executed (rather than completing the remaining pause time)
interrupt:
	' reset the flag
	hserinflag = 0
	' re-enable the interrupt handler (won't actually happen until
	' after the interrupt handler returns)
	setintflags %00100000,%00100000
	
	' has a packet arrived?
	if hserptr < packet_start then
		packet_calc = BUFFER_END - packet_start + hserptr + 1
	else
		packet_calc = hserptr - packet_start
	endif
	if packet_calc >= PACKET_LEN then
		has_packet=1
	endif
return
