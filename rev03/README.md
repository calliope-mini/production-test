# Calliope mini rev. 0.3 Test Procedure

1. Connect USB
2. Put in test device
3. Take off test device
4. wait for initial bootloader flash and DAPlink flash
5. wait for test firmware flash
6. check led matrix, accel, rgb led, triple beep
7. disconnect

Takes approx. 40s per device.

The test code is found here: [CalliopeTestBoard.cpp](https://github.com/calliope-mini/calliope-playground/blob/master/source/CalliopeTestBoard.cpp)
