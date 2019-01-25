# Safety test related files

Connect Calliope mini using a USB Cable. Download the firmware hex file you want and copy it onto the `MINI` drive that is mounted.
To ensure it's working, press the white RESET button.

## bt-pairing-test.hex

This is a simple program which allows pairing with a mobile phone to test BT radio

## radiotest.hex

This is a radio test program from the [nRF54 SDK](https://developer.nordicsemi.com/). 
It is controlled via the serial console (USB, 115200, 8N1). After flashing, connect to
the serial console and press `h` and Enter for help.

## radio-frequency-test.hex 
 
- After successful flashing, the display should scroll "READY".
- Use the button `A` to select the transmission/reception frequency: `TX02`, `RX02`, `TX40`, `RX40`, `TX80`, and `RX80`
- Activate the transmission/reception mode using button `B`. 

At the start of the mode the display scrolls `START ?X 24??` (i.e. `START TX 2402`) and the RGB LED 
will pulse red for *sending* and green for *receiving* mode.

## calliope-stress.hex

This little program enables the motor PWM, the LED matrix as well as the RGB LED and
then runs in a tight loop to put the MCU at 100% duty. It will regularly print the
temperature from the internal sensor on the serial console (USB, 115200, 8N1).

In parallel it enables the BT temperature and the BT button service. If you pair the
device and use a Bluetooth app, you can read out the temperature on a phone.

> *Attention!* This puts the RGB LED to its full brightness. The normal brightness when
> using the RGB LED from the [DAL](https://github.com/calliope-mini/microbit-dal) is only
> about 15% of what the RGB LED is capable of.
 
