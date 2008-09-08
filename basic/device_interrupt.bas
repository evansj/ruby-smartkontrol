' ###############################################################################
' #### interrupt driven comms using hsersetup
' ####
' #### The interrupt routine sets has_packet when a packet is available
' ###############################################################################

#picaxe 28x1
'#com /dev/tty.usbserial-devboard

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

symbol has_packet = b11
symbol last_char = b10
symbol BAUD=T4800_4 'set baud rate to match XBEE
symbol XBEEdataoutPIN=4
symbol XBEEdatainPIN=7
#ifdef HAS_RELAY
  symbol RELAY_STR=RELAY+48 'relay pin number as an ASCII char
#endif
#ifdef HAS_LED
  symbol LED_STR=LED+48 'LED pin number as an ASCII char
#endif

setfreq m4
gosub XBEEwake
pause 200
serout XBEEdataoutPIN,BAUD,("aA",s1,s2,"STARTED",CR)
pause 100

' initialize ptr to point to start of scratchpad area
ptr = 0

' start serial port listener
hsersetup BAUD, %11
setintflags %00100000,%00100000

'###############################################################################

main:
if has_packet=1 then
	has_packet=0
	gosub packet_rx
endif
pause 10
goto main

' ###############################################################################
' Process the command that was received
' ###############################################################################
packet_rx:
' look for "a"
do
	b0 = @ptrinc
loop while b0 <> "a" and ptr <> hserptr
if b0 <> "a" then finished_packet

' look for "C"
b0 = @ptrinc
if b1 <> "C" then finished_packet

' look for the first byte of the device ID
b0 = @ptrinc
if b1 <> s1 then finished_packet

' look for the second byte of the device ID
b0 = @ptrinc
if b1 <> s2 then finished_packet

select @ptrinc
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
b0=RELAY
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
b0=LED
gosub showOutputStatus
return
#endif

'###############################################################################
' input: b0 is the output port that we are reporting on
'        b1 is the status
showOutputStatus:
b0 = b0 + 48 ' convert port to ASCII
serout XBEEdataoutPIN,BAUD,("aR",s1,s2,"O",b0,b1,CR)
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
get last_char, hserptr
if last_char=13 then
	has_packet = 1
endif
return