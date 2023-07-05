#! /bin/bash
MINIPATH='/media/hugo/MINI'
MAG='\x1b[35;49;1m'
RED='\x1b[39;41;1m'
DEF='\x1b[39;49m'
GRE='\x1b[32;49m'

while true
do
START=$SECONDS
echo 0 > /sys/class/leds/led0/brightness; # turns off green ACT LED
JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile erase.jlink && printf "${MAG}recovered NRF52820${DEF}\n";
JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile flash.jlink && printf "${MAG}flashed DAPLINK${DEF}\n";
printf "${MAG}wait for 6 seconds until device is ready${DEF}\n"; 
sleep 6;
if [ -d "$MINIPATH" ]; # Check if device is connected
then
printf "${MAG}start flashing NRF52833${DEF}\n"; 
cp microbit-prodtest_mockup.hex $MINIPATH && printf "${GRE}DONE in $(($SECONDS - $START)) seconds. ${DEF}\n" && echo 1 > /sys/class/leds/led0/brightness; # turns on green ACT LED
break
else
printf "${RED}FAILED${DEF}\n"
fi
done