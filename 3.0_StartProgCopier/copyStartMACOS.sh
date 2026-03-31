#!/bin/bash

APPLICATION_FW="miniV3_start.hex"
COUNT=0

# Colors
MAG='\x1b[35;49;1m'
RED='\x1b[39;41;1m'
DEF='\x1b[39;49m'
GRE='\x1b[32;49m'

OS=$(uname)

###############################################
# Cross‑platform mount function
###############################################
await_mount() {
  LABEL="$1"
  MAX="$2"
  WAITSTART=$SECONDS

  printf "${MAG}Wait max ${MAX}s for $LABEL drive${DEF}\n"

  if [[ "$OS" == "Darwin" ]]; then
    # macOS
    while true; do
      DEVICE=$(diskutil list | grep "$LABEL" | awk '{print $NF}')
      WAITELAPSED=$(($SECONDS - $WAITSTART))

      if [ -n "$DEVICE" ]; then
        DISK=$(diskutil info "$DEVICE" | awk -F': *' '/Device Node/ {print $2}')
        break
      fi

      printf "\r${MAG}Waiting for appearance [$LABEL] (${WAITELAPSED}s/${MAX}s)${DEF}"
      if [ "$WAITELAPSED" -gt "$MAX" ]; then return 1; fi
      sleep 1
    done

    diskutil mount "$DISK" >/dev/null 2>&1
    if [ $? -ne 0 ]; then return 1; fi

    MOUNT=$(diskutil info "$DISK" | awk -F': *' '/Mount Point/ {print $2}')
    printf "${MAG}\nMounted [$LABEL] in $(($SECONDS - $WAITSTART))s${DEF}\n"
    return 0

  else
    # Linux
    until (blkid -L "$LABEL" >/dev/null 2>&1); do
      WAITELAPSED=$(($SECONDS - $WAITSTART))
      printf "\r${MAG}Wait appearance${DEF} [$LABEL] (${WAITELAPSED}s/${MAX}s)"
      if [ "$WAITELAPSED" -gt "$MAX" ]; then return 1; fi
      sleep 1
    done

    DEVICE=$(blkid -L "$LABEL")
    until (udisksctl mount -b "$DEVICE" >/dev/null 2>&1); do
      WAITELAPSED=$(($SECONDS - $WAITSTART))
      printf "\r${MAG}Wait for mounting${DEF} [$LABEL] (${WAITELAPSED}s/${MAX}s)"
      if [ "$WAITELAPSED" -gt "$MAX" ]; then return 1; fi
      sleep 1
    done

    MOUNT=$(lsblk -o MOUNTPOINT -nr "$DEVICE")
    printf "${MAG}\nMounted [$LABEL] in $(($SECONDS - $WAITSTART))s${DEF}\n"
    return 0
  fi
}

###############################################
# Cross‑platform eject function
###############################################
eject_device() {
  if [[ "$OS" == "Darwin" ]]; then
    diskutil unmount "$DISK" >/dev/null 2>&1
    diskutil eject "$DISK" >/dev/null 2>&1
  else
    udisksctl unmount -b "$DEVICE" >/dev/null 2>&1
    udisksctl power-off -b "$DEVICE" >/dev/null 2>&1
  fi
}

###############################################
# Main loop
###############################################
while true; do
  while true; do
    VTref=0
    FLASHED=0
    RECOVERED=0
    printf "${MAG}START${DEF}\n"
    START=$SECONDS

    # Wait for MINI drive
    await_mount "MINI" 20
    if [ "$?" != "0" ]; then
      printf "${RED}\nMounting failed${DEF}\n"
      break
    fi

    printf "${MAG}Start flashing NRF52833${DEF}\n"

    # Copy firmware
    cp "$APPLICATION_FW" "$MOUNT"
    if [[ $? = 0 ]]; then
      printf "${GRE}NRF52833: flashed${DEF}\n"
      printf "${GRE}SUCCESS: Programming done in $(($SECONDS - $START)) seconds.${DEF}\n"
      eject_device
    else
      printf "${RED}NRF52833: Flashing failed${DEF}\n"
      break
    fi

    # Logging
    DATETIME=$(date "+%Y.%m.%d %H:%M:%S")
    COUNT=$((COUNT+1))
    echo "$DATETIME $COUNT" >> prodprog.log


    break
  done
done
