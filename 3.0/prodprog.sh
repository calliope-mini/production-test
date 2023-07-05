JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile erase.jlink
JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile flashing.jlink
rsync -av --progress --stats dest microbit-prodtest_mockup.hex /media/hugo/MINI/

JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile erase.jlink; 
echo "successfully recovered and erased NRF52820"
JLinkExe -NoGui 1 -device NRF52820_xxAA -Commandfile flash.jlink; 
echo "successfully flashed DAPLINK"
echo "wait for seconds until device is ready
"; 
sleep 6; 
rsync -av --progress --stats dest microbit-prodtest_mockup.hex /media/hugo/MINI/;
echo "SUCCESS";
echo 1 > /sys/class/leds/led0/brightness

