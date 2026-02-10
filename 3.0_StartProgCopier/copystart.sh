
#! /bin/bash

APPLICATION_FW="miniV3_start.hex"
COUNT=0

# Change USB Firmware in flash.jlink
MAG='\x1b[35;49;1m'
RED='\x1b[39;41;1m'
DEF='\x1b[39;49m'
GRE='\x1b[32;49m'
await_mount() {
  WAITSTART=$SECONDS
  MAX=$2
  printf "${MAG}Wait max ${MAX}s for $1${DEF} drive\n";
  DEVICE=$(blkid -L "$1" 2>/dev/null)
  # wait until the device appears
  until (blkid -L "$1" 1>/dev/null 2>/dev/null); do 
    WAITELAPSED=$(($SECONDS-$WAITSTART))
    printf "\r\x1b[35;49;1mWait appearance${DEF} [$1] (${WAITELAPSED}s/${MAX}s)"
    if [ "$WAITELAPSED" -gt "$2" ]; then return 1; fi
  done
  DEVICE=$(blkid -L "$1")
  # wait for the device to mount
  until (udisksctl mount -b $DEVICE 1>/dev/null 2>/dev/null); do
    WAITELAPSED=$(($SECONDS-$WAITSTART))
    printf "\r\x1b[35;49;1mWait for mounting${DEF} [$1] (${WAITELAPSED}s/${MAX}s)"
    if [ "$WAITELAPSED" -gt "$2" ]; then return 1; fi
  done
  printf "${MAG}\nMounted [$1] in $(($SECONDS-$WAITSTART))s ${DEF}\n"
  return 0
}

while true; do # First loop for always on
    while true; do # Second loop to jump to when program fails
        VTref=0
        FLASHED=0
        RECOVERED=0
        printf "${MAG}START${DEF}\n";
        START=$SECONDS



# Flash Application Firmware / Testprogram
	await_mount "MINI" 20 # Wait for device
        if [ "$?" == "0" ]; then 
	    DEVICE=$(blkid -L "MINI" 2>/dev/null)
	    MOUNT=$(lsblk -o MOUNTPOINT -nr $DEVICE 2>/dev/null)
	else 
	    printf "${RED}\nMounting failed ${DEF}\n";
	    break;
        fi
	printf "${MAG}Start flashing NRF52833${DEF}\n";
        cp $APPLICATION_FW $MOUNT; # copy application firmware to mini
        if [[ $? = 0 ]];
        then
            printf "${GRE}NRF52833: flashed ${DEF}\n";
            printf "${GRE}SUCCESS: Programming done in $(($SECONDS - $START)) seconds. ${DEF}\n";
	    udisksctl unmount -b $DEVICE
	    udisksctl power-off -b $DEVICE
	    # sudo eject $DEVICE
            
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
            if ((VTref>1)); then printf "${MAG}Test and disconnect minis${DEF}\n"; sleep 1; else break; fi; # Check if VTRef is below 1V
        done;
        
        break; # Everything successful, start anew
        
        
    done;
done;