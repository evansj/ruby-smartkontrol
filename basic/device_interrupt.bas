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
symbol packet_end = b12
symbol packet_ptr = b13
symbol BUFFER_END = 127 ' how many scratch memory bytes are there?
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

hserout 0,("aA",s1,s2,"STARTED",CR)
pause 100

' initialize packet pointers to 0
packet_start = 0
packet_end = 0

' enable the interrupt handler
setintflags %00100000,%00100000

'###############################################################################

main:
'brief blink of the led
high portc LED
pause 5
low portc LED

if has_packet = 1 then gosub packet_rx
pause 10000 ' 10 second pause
goto main

' ###############################################################################
' Process the command that was received
' ###############################################################################
packet_rx:
has_packet=0
ptr = packet_start
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
packet_start = packet_end
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
hserout 0,("aR",s1,s2,"O",RELAY_STR,b1,CR)
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
	hserout 0,("aY",s1,s2,"O",RELAY_STR,"0",CR)
	'Relay Output Off
	hserout 0,("aY",s1,s2,"O",RELAY_STR,"1",CR)
#endif
return

' ###############################################################################
sendEcho:
hserout 0,("aR",s1,s2,"HERE",CR)
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
	' start looking from packet_end, which is the last place we checked
	packet_ptr = packet_end
	do while packet_ptr != hserptr
		get packet_ptr, last_char
		inc packet_ptr
		if packet_ptr > BUFFER_END then
			packet_ptr = 0
		endif
		if last_char=13 then
			has_packet=1
			exit ' terminate the do loop
		endif
	loop
	packet_end = packet_ptr ' remember where we got up to

return
