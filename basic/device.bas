
#picaxe 28x1
#com /dev/tty.usbserial-devboard

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
init:
symbol SER_TIMEOUT=2000
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
serout XBEEdataoutPIN,BAUD,("aA",s1,s2,"STARTED-")
pause 100
'###############################################################################
main:
' wait for a command targeting this sensor
serin [SER_TIMEOUT, main], XBEEdatainPIN, BAUD, ("aC",s1,s2),b1,b2,b3,b4,b5,b6,b7,b8

'Process the command that was received
if b1="E" then gosub sendEcho
if b1="Y" then gosub displayCapabilities
#ifdef HAS_RELAY
  if b1="O" AND b2=RELAY_STR then gosub controlRelay
#endif
#ifdef HAS_LED
  if b1="O" AND b2=LED_STR then gosub controlLed
#endif

goto main

'###############################################################################
#ifdef HAS_RELAY
controlRelay:
select case b3
	case "0"
		low RELAY
	case "1"
		high RELAY
endselect
gosub showOutputStatus
return
#endif
'###############################################################################
#ifdef HAS_LED
controlLed:
select case b3
	case "0"
		low portc LED
	case "1"
		high portc LED
endselect
gosub showOutputStatus
return
#endif
'###############################################################################
showOutputStatus:
serout XBEEdataoutPIN,BAUD,("aR",s1,s2,b1,b2,b3,b4,b5,b6,b7,b8)
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
serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"E-------")
'Capabilities
serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"Y-------")
#ifdef HAS_RELAY
	'Relay Output On
	serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"O",RELAY_STR,"0-----")
	'Relay Output Off
	serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"O",RELAY_STR,"1-----")
#endif
#ifdef HAS_LED
	'LED Output On
	serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"O",LED_STR,"0-----")
	'LED Output Off
	serout XBEEdataoutPIN,BAUD,("aY",s1,s2,"O",LED_STR,"1-----")
#endif
return
'###############################################################################
sendEcho:
serout XBEEdataoutPIN,BAUD,("aR",s1,s2,"HERE----")
return
