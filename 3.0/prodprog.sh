#! /bin/bash

APPLICATION_FW="microbit-prodtest_mockup.hex"
# Change USB Firmware in flash.jlink
MAG='\x1b[35;49;1m'
RED='\x1b[39;41;1m'
DEF='\x1b[39;49m'
GRE='\x1b[32;49m'

while true; do # First loop for always on
while true; do # Second loop to jump to when program fails
echo 0 > /sys/class/leds/led0/brightness; # turns off green ACT LED
VTref=0
FLASHED=0
RECOVERED=0

while true; do 
printf "${MAG}START${DEF}\n"; 
START=$SECONDS

# Check if target voltage (VTref) is >= than 2V
JLinkExe -NoGui 1 -CommandFile on.jlink >on.log
VTstring=$(grep "VTref" on.log); # Get VTRef full string
VTref=${VTstring:6:1};
if ((VTref>1)); then printf "${GRE}VTref = $VTref V :Target voltage present ${DEF}\n"; break; else printf "${RED}Target voltage not present${DEF}\n"; sleep 1; fi;
done;

# Recover device / Unlock Access Port Protection (APP)
printf "${MAG}Try recover${DEF}\n"
JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile recover.jlink > recover.log
ReadAPfull=$(grep "Read AP register 3" recover.log);
RECOVERED=$(echo ${ReadAPfull:32:32} | grep "0x00000001" -wc); # Check if the second read is "0x00000001", 
if (( "$RECOVERED" > 0 )); then printf "${GRE}recovered NRF52820${DEF}\n"; else printf "${RED}recovering failed ${DEF}\n"; sleep 1; break; fi; # If unlocking fails start anew

# Flash USB Firmware / DAPLink
JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile flash.jlink > flash.log;
FLASHED=$(grep "^O.K." flash.log -wc);
if (( "$FLASHED" > 1 )); then printf "${GRE}flashed NRF52820${DEF}\n"; else printf "${RED}flashing failed ${DEF}\n"; sleep 1; break; fi; # If flashing fails start anew

# Flash Application Firmware / Testprogram
DEVICE=$(blkid -L "MINI" 2>/dev/null) # get the device name e.g. /dev/sda 
MOUNT=$(lsblk -o MOUNTPOINT -nr $DEVICE 2>/dev/null) # get the corresponding mountpoint e.g. /media/USER/MINI
printf "${MAG}wait for 6 seconds until device is ready${DEF}\n";
sleep 6;
if [ -d "$MOUNT" ]; # Check if device is connected
then
printf "${MAG}mini is connected, start flashing NRF52833${DEF}\n"; 
else
printf "${RED}mini is not found${DEF}\n";
break # If mini is not found, start anew
fi;

cp $APPLICATION_FW $MOUNT; # Flash application firmware
if [[ $? = 0 ]]; then
printf "${GRE}SUCCESS: done in $(($SECONDS - $START)) seconds. ${DEF}\n";
printf "${MAG}DISCONNECT THE MINI${DEF}\n"
sleep 5;
# Here testing needs to be implemented
echo 1 > /sys/class/leds/led0/brightness; # turns on green ACT LED
break; # Everything successful, start anew
else printf "${RED}Flashing of NRF52833 failed ${DEF}\n"; break; break;
fi; 

done;
done;
