#! /bin/bash
MAINTENANCE=$1
MINI=$2
TESTFW=`dirname $0`/firmware.hex
JLINK=`which JLinkExe`

[ "$MAINTENANCE" == "" ] && MAINTENANCE=MAINTENANCE
[ "$MINI" == "" ] && MINI=MINI

await_mount() {
  WAITSTART=$SECONDS
  MAX=$2
  DEVICE=$(blkid -L "$1")
  # if the device already exists, unmount
  if [ "$DEVICE" != "" ]; then udisksctl unmount -b $DEVICE; fi
  # wait until the device appears
  until (blkid -L "$1" 2>&1 >/dev/null); do 
    WAITELAPSED=$(($SECONDS-$WAITSTART))
    printf "\r\033[0;31mWARTE\033[0m [$1] (${WAITELAPSED}s/${MAX}s)"
    if [ "$WAITELAPSED" -gt "$2" ]; then echo; return 1; fi
  done
  DEVICE=$(blkid -L "$1")
  # wait for the device to mount
  until (udisksctl mount -b $DEVICE 2>&1 >/dev/null); do
    WAITELAPSED=$(($SECONDS-$WAITSTART))
    printf "\r\033[0;31mWARTE\033[0m [$1] (${WAITELAPSED}s/${MAX}s)"
    if [ "$WAITELAPSED" -gt "$2" ]; then echo; return 1; fi
  done
  echo
  return 0
}

COUNT=1
ALLSTART=$SECONDS
START=$SECONDS
while(true); do
  clear
  ELAPSED=$((SECONDS-$START))
  if [ "$ELAPSED" -gt "1" ]; then
    echo "Letzter Test: ${ELAPSED}s"
    DATETIME=`date "+%Y.%m.%d %H:%M:%S"`
    echo "$DATETIME $COUNT $ELAPSED" >> testprocedure.log
    COUNT=$((COUNT+1))
  fi
  START=$SECONDS
  printf "\033[0;31mCalliope mini anstecken und einlegen!\033[0m\n"
  while [ -d "$MINI" -o -d "$MAINTENANCE" ]; do sleep 1; printf "."; done
  echo
  echo "1. Bootloader & Interface flashen"
  while(true); do
    ELAPSED=$((SECONDS-START))
    printf "\r\033[0;31mWARTE\033[0m(${ELAPSED}s)"
    $JLINK -if SWD -device MKL26Z128XXX4 -speed 4000 bootloader.jlink > bootloader.log
    FLASHED=$(grep "^O\.K\." bootloader.log | wc -l)
    if [ "$FLASHED" == "2" ]; then break; fi
  done
  echo
  await_mount $MAINTENANCE 20
  DEVICE=$(blkid -L $MAINTENANCE)
  MOUNT=$(lsblk -o MOUNTPOINT -nr $DEVICE)
  if [ "$?" == "0" ]; then touch $MOUNT/start_if.act; fi
  printf "2. TEST Firmware (NRF51) flashen\n"
  printf "   \033[0;31mCalliope aufnehmen!\033[0m\n"
  await_mount $MINI 20 
  DEVICE=$(blkid -L $MINI)
  MOUNT=$(lsblk -o MOUNTPOINT -nr $DEVICE)
  if [ "$?" != "0" ]; then continue; fi
  /bin/cp $TESTFW $MOUNT/
  if [ "$?" != "0" ]; then
    echo "FEHLER: Prozedur wiederholen!"; sleep 3
    continue
  else
    printf "\033[0;32mOK\033[0m\n"
  fi
  while [ -d $MOUNT ]; do echo -n "."; sleep 1; done
  echo
  await_mount $MINI 20
  DEVICE=$(blkid -L $MINI)
  MOUNT=$(lsblk -o MOUNTPOINT -nr $DEVICE)
  printf "3. Pixel Matrix pruefen, RGB LED, Piep abwarten.\n"
  printf "   \033[0;31mDANACH Calliope mini abstecken!\033[0m\n"
  while [ -d $MOUNT ]; do echo -n "."; sleep 1; done
  echo
  echo "DONE"
done
ELAPSED=$((SECONDS-$ALLSTART))
echo "Total: ${ELAPSED}s"
