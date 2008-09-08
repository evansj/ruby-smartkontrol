' ###############################################################################
' #### interrupt driven comms using hsersetup
' ####
' #### The interrupt routine sets has_packet when a packet is available
' ###############################################################################

#picaxe 28x1
'#com /dev/tty.usbserial-000012FD

'###############################################################################
config:

' The sensor code of this module
symbol s1="S"
symbol s2="1"

' comment these out if necessary
#define HAS_RELAY
#define HAS_LED

#ifdef HAS_RELAY
  ' Which pin is the relay connected to?
  symbol RELAY=5
#endif

#ifdef HAS_LED
  ' Which pin is the LED connected to?
  symbol LED=1
#endif

'###############################################################################
symbol reserved_for_flags=b0
symbol has_packet = bit0
symbol last_char = b10
symbol packet_start = b11
symbol packet_end = b12
symbol BAUD=T4800_4 'set baud rate to match XBEE
symbol XBEEdataoutPIN=4
symbol XBEEdatainPIN=7
#ifdef HAS_RELAY
  symbol RELAY_STR=RELAY+48 'relay pin number as an ASCII char
#endif
#ifdef HAS_LED
  symbol LED_STR=LED+48 'LED pin number as an ASCII char
  symbol led_flag = b13
#endif

setfreq m4
gosub XBEEwake
pause 200
serout XBEEdataoutPIN,BAUD,("aA",s1,s2,"STARTED",CR)
' sertxd ("aA",s1,s2,"STARTED",13,10)
pause 100

' initialize ptr to point to start of scratchpad area
ptr = 0
packet_start = 0
packet_end = 0

' start serial port listener
hsersetup B4800_4, %11
setintflags %00100000,%00100000

'###############################################################################

main:
' sertxd (".")
debug
if has_packet=%1 then
	has_packet=%0
	gosub packet_rx
endif
pause 500
select led_flag
case 0
	led_flag=1
	high portc LED
case 1
	led_flag=0
	low portc LED
endselect
goto main

' ###############################################################################
' Process the command that was received
' ###############################################################################
packet_rx:
' disable interrupts because we want to use ptr
setintflags off
ptr = packet_start
' look for "a"
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
	b3 = @ptrinc
#ifdef HAS_RELAY
	if b3=RELAY_STR then gosub controlRelay
#endif
#ifdef HAS_LED
	if b3=LED_STR then gosub controlLed
#endif
endselect
finished_packet:
packet_start = packet_end
setintflags %00100000,%00100000
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
b2=RELAY
gosub showOutputStatus
return
#endif

'###############################################################################
#ifdef HAS_LED
controlLed:
b1 = @ptrinc
select b1
	case "0"
		low portc LED
	case "1"
		high portc LED
endselect
b2=LED
gosub showOutputStatus
return
#endif

'###############################################################################
' input: b2 is the output port that we are reporting on
'        b1 is the status
showOutputStatus:
b2 = b2 + 48 ' convert port to ASCII
serout XBEEdataoutPIN,BAUD,("aR",s1,s2,"O",b2,b1,CR)
return
'###############################################################################
XBEEwake:
high 6 'take XBEE SLEEP pin high
high 4 'take XBEE DATA pin high
high 7 'take XBEE RESET pin high
return
'###############################################################################
XBEEsleep:
low 6 'take XBEE SLEEP pin low
low 4 'take XBEE DATA pin low
low 7 'take XBEE RESET pin low
return
'###############################################################################
displayCapabilities:
'Echo
serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"E",CR)
'Capabilities
serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"Y",CR)
#ifdef HAS_RELAY
	'Relay Output On
	serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"O",RELAY_STR,"0",CR)
	'Relay Output Off
	serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"O",RELAY_STR,"1",CR)
#endif
#ifdef HAS_LED
	'LED Output On
	serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"O",LED_STR,"0",CR)
	'LED Output Off
	serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"O",LED_STR,"1",CR)
#endif
return

' ###############################################################################
sendEcho:
serout XBEEdataoutPIN,BAUD,("aR",s1,s2,"HERE",CR)
return

interrupt:
' reset the flag
hserinflag = 0
' re-enable the interrupt
setintflags %00100000,%00100000

' has a packet arrived?
' start looking from packet_end, the last place we checked
ptr=packet_end
do while ptr != hserptr
	last_char = @ptrinc
	if last_char=13 then
		has_packet = %1
		exit ' terminate the do loop
	endif
loop
packet_end=ptr ' remember where we got up to

'sertxd("last char is ",#last_char,13,10) 
'sertxd("char at ptr is ",#@ptr,13,10) 

debug
return