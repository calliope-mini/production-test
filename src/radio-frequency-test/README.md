# radio frequency test

Code that turns on the radio for CE/FCC/TELEC measurements.

How to use:

1. Connect Calliope mini to USB
2. copy radio-frequency-test.hex to MINI drive
3. Wait for `READY` message on Calliope mini display

The bottom right display LED will blink when ready.

You can now use the Button `A` to select the test scenario.
With Button `B` the scenario is started.

Select the test scenario:

- Transmit 2.402GHz (`TX02`)
- Receive 2.402Ghz (`RX02`)
- Transmit 2.440GHz (`TX40`)
- Receive 2.440Ghz (`RX40`)
- Transmit 2.480GHz (`TX40`)
- Receive 2.480Ghz (`RX40`)

Press Button `B` to start. A message will scroll on the Calliope mini
display, for example: `START TX 2402`. If you selected a transmition
the RGB LED will pulse red. For receiving scenario the RGB LED will
pulse green.

Pressing Button `A` again will always stop the scenario.