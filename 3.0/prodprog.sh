#! /bin/bash

MINIPATH='/media/hugo/MINI'
MAG='\x1b[35;49;1m'
RED='\x1b[39;41;1m'
DEF='\x1b[39;49m'
GRE='\x1b[32;49m'

while true; do
START=$SECONDS
printf "${MAG}START{DEF}\n"; 
#echo 0 > /sys/class/leds/led0/brightness; # turns off green ACT LED
VTref=0
FLASHED=0
RECOVERED=0

# Check if target voltage (VTref) is >= than 2V
while true; do 
JLinkExe -NoGui 1 -CommandFile on.jlink >on.log
VTstring=$(grep "VTref" on.log); # Get VTRef full string
VTref=${VTstring:6:1};
if ((VTref>1)); then printf "${GRE}VTref = $VTref V :Target voltage present ${DEF}\n"; break; else printf "${RED}VTref = $VTref :target voltage not present${DEF}\n"; sleep 1; fi;
done;

START=$SECONDS

# Recover device
while true; do
printf "${MAG}try recover${DEF}\n"
JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile erase.jlink > recover.log
ReadAPfull=$(grep "Read AP register 3" recover.log);
RECOVERED=$(echo ${ReadAPfull:32:32} | grep "0x00000001" -wc); # Check if one read is "0x00000001", 
if (( "$RECOVERED" > 0 )); then printf "${GRE}recovered NRF52820${DEF}\n"; break; else printf "${RED}recovering failed ${DEF}\n"; break; break; fi;
done;


# Flash USB Firmware / DAPLink
while true; do
JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile flash.jlink > flash.log;
FLASHED=$(grep "^O.K." flash.log -wc);
if (( "$FLASHED" > 0 )); then printf "${GRE}flashed NRF52820${DEF}\n"; break; else printf "${RED}flashing failed ${DEF}\n"; break; break; fi;
done

# Flash Application Firmware / Testprogram
while true; do
printf "${MAG}wait for 6 seconds until device is ready${DEF}\n"; 
sleep 6;
if [ -d "$MINIPATH" ]; # Check if device is connected
then
printf "${MAG}mini is connected, start flashing NRF52833${DEF}\n"; 
else
printf "${RED}mini is not found${DEF}\n";
break # break flash application firmware loop
fi;

cp microbit-prodtest_mockup.hex $MINIPATH; 
if [[ $? = 0 ]]; then
printf "${GRE}DONE in $(($SECONDS - $START)) seconds. ${DEF}\n";
printf "${MAG} DISCONNECT ${DEF}\n"
sleep 6;
#echo 1 > /sys/class/leds/led0/brightness; # turns on green ACT LED
break; # leaves flash device loop
else printf "${RED}Flashing of NRF52833 failed ${DEF}\n"; break; break;
fi;
done; 

done
