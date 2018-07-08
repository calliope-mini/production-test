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
  DEVICE=$(blkid -L "$1" 2>/dev/null)
  # wait until the device appears
  until (blkid -L "$1" 1>/dev/null 2>/dev/null); do 
    WAITELAPSED=$(($SECONDS-$WAITSTART))
    printf "\r\033[0;31mWARTE\033[0m [$1] (${WAITELAPSED}s/${MAX}s)"
    if [ "$WAITELAPSED" -gt "$2" ]; then echo; return 1; fi
  done
  DEVICE=$(blkid -L "$1")
  # wait for the device to mount
  until (udisksctl mount -b $DEVICE 1>/dev/null 2>/dev/null); do
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
    echo "$DATETIME $COUNT $ELAPSED" >> test_firmware.log
    COUNT=$((COUNT+1))
  fi
  START=$SECONDS
  await_mount $MAINTENANCE 10
  if [ "$?" == "0" ]; then 
    DEVICE=$(blkid -L $MAINTENANCE 2>/dev/null)
    MOUNT=$(lsblk -o MOUNTPOINT -nr $DEVICE 2>/dev/null)
    touch $MOUNT/start_if.act
  fi
  printf "1. TEST Firmware (NRF51) flashen\n"
  printf "   \033[0;31mCalliope aufnehmen!\033[0m\n"
  await_mount $MINI 20 
  DEVICE=$(blkid -L $MINI 2>/dev/null)
  MOUNT=$(lsblk -o MOUNTPOINT -nr $DEVICE 2>/dev/null)
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
  printf "3. Pixel Matrix pruefen, RGB LED, Piep abwarten.\n"
  printf "   \033[0;31mDANACH Calliope mini abstecken!\033[0m\n"
  await_mount $MINI 20
  DEVICE=$(blkid -L $MINI 2>/dev/null)
  MOUNT=$(lsblk -o MOUNTPOINT -nr $DEVICE 2>/dev/null)
  while [ -d $MOUNT ]; do echo -n "."; sleep 1; done
  echo
  echo "DONE"
done
ELAPSED=$((SECONDS-$ALLSTART))
echo "Total: ${ELAPSED}s"
