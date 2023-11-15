#! /bin/bash

APPLICATION_FW="mini3_startprogram.hex"
COUNT=0

# Change USB Firmware in flash.jlink
MAG='\x1b[35;49;1m'
RED='\x1b[39;41;1m'
DEF='\x1b[39;49m'
GRE='\x1b[32;49m'
await_mount() {
  WAITSTART=$SECONDS
  MAX=$2
  DEVICE=$(blkid -L "$1" 2>/dev/null)
  # wait until the device appears
  until (blkid -L "$1" 1>/dev/null 2>/dev/null); do 
    WAITELAPSED=$(($SECONDS-$WAITSTART))
    printf "\r\x1b[35;49;1mWait for device${DEF} [$1] (${WAITELAPSED}s/${MAX}s)"
    if [ "$WAITELAPSED" -gt "$2" ]; then echo; return 1; fi
  done
  DEVICE=$(blkid -L "$1")
  # wait for the device to mount
  until (udisksctl mount -b $DEVICE 1>/dev/null 2>/dev/null); do
    WAITELAPSED=$(($SECONDS-$WAITSTART))
    printf "\r\x1b[35;49;1mWait for device${DEF} [$1] (${WAITELAPSED}s/${MAX}s)"
    if [ "$WAITELAPSED" -gt "$2" ]; then echo; return 1; fi
  done
  printf "\n"
  return 0
}
# LEDs on Header on GPIO 21 and 7, https://simonprickett.dev/controlling-raspberry-pi-gpio-pins-from-bash-scripts-traffic-lights/
IF_DONE_LED=21
APP_DONE_LED=7

# Utility function to export a pin if not already exported
exportPin()
{
  if [ ! -e /sys/class/gpio/gpio$1 ]; then
    echo "$1" > /sys/class/gpio/export
  fi
}

# Utility function to set a pin as an output
setOutput()
{
  echo "out" > /sys/class/gpio/gpio$1/direction
}

# Utility function to change state of a light
setLightState()
{
  echo $2 > /sys/class/gpio/gpio$1/value
}
exportPin $IF_DONE_LED
exportPin $APP_DONE_LED
setOutput $IF_DONE_LED
setOutput $APP_DONE_LED

sudo chmod 666 /sys/class/leds/ACT/brightness # make internal ACT led accessible



while true; do # First loop for always on
    while true; do # Second loop to jump to when program fails
        echo 0 > /sys/class/leds/ACT/brightness; # turns off green ACT LED
        VTref=0
        FLASHED=0
        RECOVERED=0
        
        while true; do
            printf "${MAG}START${DEF}\n";
            START=$SECONDS
            setLightState $APP_DONE_LED 0
            setLightState $IF_DONE_LED 0
            
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
        if (( "$FLASHED" > 1 )); then printf "${GRE}NRF52820: flashed${DEF}\n"; setLightState $IF_DONE_LED 1; else printf "${RED}NRF52820: flashing failed ${DEF}\n"; sleep 1; break; fi; # If flashing fails start anew
        
        # Flash Application Firmware / Testprogram
	await_mount "MINI" 20 # Wait for device
        if [ "$?" == "0" ]; then 
	    DEVICE=$(blkid -L "MINI" 2>/dev/null)
	    MOUNT=$(lsblk -o MOUNTPOINT -nr $DEVICE 2>/dev/null)
	else 
	    printf "${RED}Mounting failed ${DEF}\n";
	    break;
        fi
	printf "${MAG}Start flashing NRF52833${DEF}\n";
        cp $APPLICATION_FW $MOUNT; # copy application firmware to mini
        if [[ $? = 0 ]];
        then
            printf "${GRE}NRF52833: flashed ${DEF}\n";
            printf "${GRE}SUCCESS: Programming done in $(($SECONDS - $START)) seconds. ${DEF}\n";
            echo 1 > /sys/class/leds/ACT/brightness; setLightState $APP_DONE_LED 1; # turns on APPLED and green ACT LED
	    sudo eject $DEVICE
            
        else
            printf "${RED}NRF52833: Flashing failed ${DEF}\n"; break; break;
        fi;
        
        # Minimal logging of date time and count
        DATETIME=`date "+%Y.%m.%d %H:%M:%S"`
        COUNT=$((COUNT+1))
        echo "$DATETIME $COUNT $ELAPSED" >> prodprog.log
        
        # Wait for mini disconnection
        while true; do
            JLinkExe -NoGui 1 -CommandFile on.jlink >on.log
            VTstring=$(grep "VTref" on.log); # Get VTRef full string
            VTref=${VTstring:6:1};
            if ((VTref>1)); then printf "${MAG}Test and disconnect minis${DEF}\n"; else break; fi; # Check if VTRef is below 1V
        done;
        
        break; # Everything successful, start anew
        
        
    done;
done;
