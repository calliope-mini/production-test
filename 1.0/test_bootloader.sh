#! /bin/bash
TESTFW=`dirname $0`/firmware.hex
JLINK=`which JLinkExe`


COUNT=1
ALLSTART=$SECONDS
START=$SECONDS
while(true); do
  clear
  ELAPSED=$((SECONDS-$START))
  if [ "$ELAPSED" -gt "1" ]; then
    echo "Letzter Test: ${ELAPSED}s"
    DATETIME=`date "+%Y.%m.%d %H:%M:%S"`
    echo "$DATETIME $COUNT $ELAPSED" >> test_bootloader.log
    COUNT=$((COUNT+1))
  fi
  START=$SECONDS
  echo "Bootloader & Interface flashen"
  while(true); do
    ELAPSED=$((SECONDS-START))
    printf "\r\033[0;31mWARTE\033[0m(${ELAPSED}s)"
    $JLINK -if SWD -device MKL26Z128XXX4 -speed 4000 bootloader.jlink > bootloader.log
    FLASHED=$(grep "^O\.K\." bootloader.log | wc -l)
    if [ "$FLASHED" == "2" ]; then break; fi
  done
  printf "\033[0;32mOK\033[0m\n"
done
ELAPSED=$((SECONDS-$ALLSTART))
echo "Total: ${ELAPSED}s"
