
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

' address of input buffer pointer
symbol buf_ptr = b11
' address of the first byte of the current packet
symbol packet_ptr = b12

' input buffer start address
symbol BUF_START = $50
' input buffer max length
symbol BUF_END = $60

' initialize buf_ptr and packet_ptr to point to start of buffer
buf_ptr = BUF_START
packet_ptr = BUF_START

'###############################################################################
init:
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

'###############################################################################

debug

main:
' read a byte of data into b0
serin XBEEdatainPIN, BAUD, b0
' store the received byte in the buffer
poke buf_ptr, b0
' increment the buffer pointer
inc buf_ptr
if buf_ptr > BUF_END then
	buf_ptr = BUF_START
endif
' packet received if we got a CR character
if b0 = 13 then gosub packet_rx
goto main

' ###############################################################################
' Process the command that was received
' ###############################################################################
packet_rx:
' look for "a"
b0 = "a"
gosub look_for
if b1 <> "a" then
	return
endif

' look for "C"
b0 = "C"
gosub look_for
if b1 <> "C" then
	return
endif

' look for the first byte of the device ID
b0 = s1
gosub look_for
if b1 <> s1 then
	return
endif

' look for the second byte of the device ID
b0 = s2
gosub look_for
if b1 <> s2 then
	return
endif

gosub get_packet_char
select b1
case "E"
	gosub sendEcho
case "Y"
	gosub displayCapabilities
case "O"
	gosub get_packet_char
	b3 = b1 ' remember the output identifier
#ifdef HAS_RELAY
	if b3=RELAY_STR then gosub controlRelay
#endif
#ifdef HAS_LED
	if b3=LED_STR then gosub controlLed
#endif
endselect
return

'###############################################################################
#ifdef HAS_RELAY
controlRelay:
gosub get_packet_char
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
gosub get_packet_char
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

' ###############################################################################
' increment the packet pointer until either the character in b0 is found,
' or we reach the buffer pointer
' side effects: packet_ptr is incremented
' b1 contains the last char read from the buffer (hopefully the same as
' the char in b0 which we are looking for)
look_for:
do
	gosub get_packet_char
loop until b1=b0 or packet_ptr=buf_ptr
return

' ###############################################################################
' get the next packet char from the buffer, incrementing the packet pointer
' side effects: packet_ptr is incremented
' b1 contains the last char read from the buffer
get_packet_char:
peek packet_ptr, b1
inc packet_ptr
if packet_ptr > BUF_END then
	packet_ptr = BUF_START
endif
return
