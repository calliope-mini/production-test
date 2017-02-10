#! /bin/bash
MAINTENANCE=$1
MINI=$2
TESTFW=`dirname $0`/firmware.hex
JLINK=`which JLinkExe`

[ "$MAINTENANCE" == "" ] && MAINTENANCE=/Volumes/MAINTENANCE
[ "$MINI" == "" ] && MINI=/Volumes/MINI

await_mount() {
  WAITSTART=$SECONDS
  MAX=$2
  while [ ! -f "$1/DETAILS.TXT" ]; do 
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
  echo "1. Bootloader flashen"
  while(true); do
    ELAPSED=$((SECONDS-START))
    printf "\r\033[0;31mWARTE\033[0m(${ELAPSED}s)"
     $JLINK -if SWD -device MKL26Z128XXX4 -speed 4000 bootloader.jlink > bootloader.log
    if (grep -q "^O\.K\." bootloader.log); then break; fi
  done
  echo
  printf "\033[0;31m>> Calliope mini hochnehmen! <<\033[0m\n"
  sleep 3
  echo "2. DAPLink Firmware (KL26z) flashen"
  await_mount $MAINTENANCE 20
  if [ "$?" != "0" ]; then continue; fi
  /bin/cp $DAPLINK $MAINTENANCE
  if [ "$?" != "0" ]; then
    echo "FEHLER: Prozedur wiederholen!"; sleep 3
    continue
  else
    printf "\033[0;32mOK\033[0m\n"
  fi
  echo "3. TEST Firmware (NRF51) flashen"
  await_mount $MINI 20 
  if [ "$?" != "0" ]; then continue; fi
  /bin/cp $TESTFW $MINI
  if [ "$?" != "0" ]; then
    echo "FEHLER: Prozedur wiederholen!"; sleep 3
    continue
  else
    printf "\033[0;32mOK\033[0m\n"
  fi
  while [ -d $MINI ]; do echo -n "."; sleep 1; done
  echo
  await_mount $MINI 20
  printf "4. \033[0;31m>> RESET DRÜCKEN! <<\033[0m\n"
  echo "   Pixel Matrix pruefen, RGB LED, Piep abwarten."
  printf "   \033[0;31mDANACH Calliope mini abstecken\033[0m\n"
  while [ -d $MINI ]; do echo -n "."; sleep 1; done
  echo
  echo "DONE"
done
ELAPSED=$((SECONDS-$ALLSTART))
echo "Total: ${ELAPSED}s"
