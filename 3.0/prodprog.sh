#! /bin/bash

APPLICATION_FW="microbit-prodtest_mockup.hex"
COUNT=0

# Change USB Firmware in flash.jlink
MAG='\x1b[35;49;1m'
RED='\x1b[39;41;1m'
DEF='\x1b[39;49m'
GRE='\x1b[32;49m'

if [[ "$USER" == "pi" ]]; then sudo chmod 666 /sys/class/leds/ACT/brightness; fi # make internal ACT led accessible


while true; do # First loop for always on
while true; do # Second loop to jump to when program fails
if [[ "$USER" == "pi" ]]; then echo 0 > /sys/class/leds/ACT/brightness; fi # turns off green ACT LED
VTref=0
FLASHED=0
RECOVERED=0

while true; do 
printf "${MAG}START${DEF}\n"; 
START=$SECONDS

# Check if target voltage (VTref) is >= than 2V
JLinkExe -NoGui 1 -CommandFile on.jlink >on.log
VTstring=$(grep "VTref" on.log); # Get VTRef full string
VTref=${VTstring:6:1}; # Extract first digit of VTRef
if ((VTref>1)); then printf "${GRE}Target Voltage present${DEF}\n"; break; else printf "${RED}Target Voltage not present: Insert minis${DEF}\n"; sleep 1; fi; # Check if target voltage is over 1V
done;

# Recover device / Unlock Access Port Protection (APP)
JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile recover.jlink > recover.log
ReadAPfull=$(grep "Read AP register 3" recover.log);
RECOVERED=$(echo ${ReadAPfull:32:32} | grep "0x00000001" -wc); # Check if the second read is "0x00000001", 
if (( "$RECOVERED" > 0 )); then printf "${GRE}NRF52820: recovered${DEF}\n"; else printf "${RED}NRF52820: recovering failed ${DEF}\n"; sleep 1; break; fi; # If unlocking fails start anew

# Flash USB Firmware / DAPLink
JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile flash.jlink > flash.log;
FLASHED=$(grep "^O.K." flash.log -wc);
if (( "$FLASHED" > 1 )); then printf "${GRE}NRF52820: flashed${DEF}\n"; else printf "${RED}NRF52820: flashing failed ${DEF}\n"; sleep 1; break; fi; # If flashing fails start anew

# Flash Application Firmware / Testprogram
printf "${MAG}Wait 6 seconds until MINI device is ready${DEF}\n";
sleep 6;
DEVICE=$(blkid -L "MINI" 2>/dev/null) # get the device name e.g. /dev/sda 
MOUNT=$(lsblk -o MOUNTPOINT -nr $DEVICE 2>/dev/null) # get the corresponding mountpoint e.g. /media/USER/MINI
if [ -d "$MOUNT" ]; # Check if device is connected
then
printf "${MAG}mini is connected, start flashing NRF52833${DEF}\n"; 
else
printf "${RED}MINI device was not found${DEF}\n";
break # If mini is not found, start anew
fi;

cp $APPLICATION_FW $MOUNT; # copy application firmware to mini
if [[ $? = 0 ]];
then 
printf "${GRE}NRF52833: flashed ${DEF}\n";
printf "${GRE}SUCCESS: Programming done in $(($SECONDS - $START)) seconds. ${DEF}\n";
if [[ "$USER" == "pi" ]]; then echo 1 > /sys/class/leds/ACT/brightness; fi;# turns on green ACT LED
else 
printf "${RED}NRF52833: Flashing failed ${DEF}\n"; break; break;
fi; 

# Minimal logging of date time and count
DATETIME=`date "+%Y.%m.%d %H:%M:%S"`
COUNT=$((COUNT+1))
echo "$DATETIME $COUNT $ELAPSED" >> prodprog.log

# Here testing needs to be implemented
# Wait for mini disconnection
while true; do
JLinkExe -NoGui 1 -CommandFile on.jlink >on.log
VTstring=$(grep "VTref" on.log); # Get VTRef full string
VTref=${VTstring:6:1};
if ((VTref>1)); then printf "${MAG}Test and disconnect minis${DEF}\n"; sleep 1; else break; fi; # Check if VTRef is below 1V
done;

break; # Everything successful, start anew


done;
done;
