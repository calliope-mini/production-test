/**
 * Calliope stress test.
 *
 * This is a simple stress test, which enables the temperatur BT service and then runs in a loop.
 *
 * @copyright (c) Calliope gGmbH.
 *
 * Licensed under the Apache Software License 2.0 (ASL 2.0)
 * Portions (c) Copyright British Broadcasting Corporation under MIT License.
 *
 * @author Matthias L. Jugel <leo@calliope.cc>
 */

#include "MicroBit.h"

MicroBit uBit;
MicroBitImage full(
        "255,255,255,255,255\n255,255,255,255,255\n255,255,255,255,255\n255,255,255,255,255\n255,255,255,255,255\n");

// we use events abd the 'connected' variable to keep track of the status of the Bluetooth connection
void onConnected(MicroBitEvent) {
    uBit.display.print("C");
    uBit.sleep(1000);
    uBit.display.print(full);
}

void onDisconnected(MicroBitEvent) {
    uBit.display.print("D");
    uBit.sleep(1000);
    uBit.display.print(full);

}

int main() {
    uBit.init();
    uBit.serial.baud(115200);
    uBit.serial.send("TEST\r\n");

    uBit.serial.send("display\r\n");
    uBit.display.clear();
    uBit.display.print(full);
    uBit.display.setBrightness(255);

    uBit.messageBus.listen(MICROBIT_ID_BLE, MICROBIT_BLE_EVT_CONNECTED, onConnected);
    uBit.messageBus.listen(MICROBIT_ID_BLE, MICROBIT_BLE_EVT_DISCONNECTED, onDisconnected);

    new MicroBitTemperatureService(*uBit.ble, uBit.thermometer);

    uBit.soundmotor.motorOn(100);
    uBit.rgb.setMaxBrightness(255);
    uBit.rgb.setColour(255, 255, 255, 0);

    int i = 0;
    for (;;) {
        uBit.sleep(1);
        if (++i % 0x100 == 0) {
            printf("MCU: %02dºC\r\n", uBit.thermometer.getTemperature());
        }
    }
}
