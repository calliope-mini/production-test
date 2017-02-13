# Safety test related files

## bt-pairing-test.hex

This is a simple program which allows pairing with a mobile phone to test BT radio

## radio-test.hex

This is a radio test program from the [nRF54 SDK](https://developer.nordicsemi.com/). 
It is controlled via the serial console (USB, 115200, 8N1). After flashing, connect to
the serial console and press `h` for help.

## calliope-stress.hex

This little program enables the motor PWM, the LED matrix as well as the RGB LED and
then runs in a tight loop to put the MCU at 100% duty. It will regularly print the
temperature from the internal sensor on the serial console (USB, 115200, 8N1).

In parallel it enables the BT temperature and the BT button service. If you pair the
device and use a Bluetooth app, you can read out the temperature on a phone.

> *Attention!* This puts the RGB LED to its full brightness. The normal brightness when
> using the RGB LED from the [DAL](https://github.com/calliope-mini/microbit-dal) is only
> about 15% of what the RGB LED is capable of.
 
