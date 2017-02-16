/**
 * Calliope Radio Frequency Test.
 *
 * The code allows to select BT channels 00 and 78 to send on
 * the frequencies 2400MHz and 2478MHz for continuuous testing.
 *
 * With Button A you select the channel and RX or TX mode.
 * With Button B you start the test.
 *
 * @copyright (c) Calliope gGmbH.
 *
 * Licensed under the Apache Software License 2.0 (ASL 2.0)
 * Portions (c) Copyright British Broadcasting Corporation under MIT License.
 *
 * @author Matthias L. Jugel <leo@calliope.cc>
 */

#include "MicroBit.h"
#include "nrf.h"
#include "nrf51.h"
#include "nrf51_deprecated.h"

MicroBit uBit;

/**
 * Initialize the clock, so we can use the radio
 */
static void init(void) {
    NRF_RNG->TASKS_START = 1;
    NRF_CLOCK->EVENTS_HFCLKSTARTED = 0;
    NRF_CLOCK->TASKS_HFCLKSTART = 1;
    while (NRF_CLOCK->EVENTS_HFCLKSTARTED == 0) {
        // Do nothing.
    }
}

/**
 * Disable radio.
 */
void off(void) {
    NRF_RADIO->SHORTS = 0;
    NRF_RADIO->EVENTS_DISABLED = 0;
    NRF_RADIO->TEST = 0;
    NRF_RADIO->TASKS_DISABLE = 1;
    while (NRF_RADIO->EVENTS_DISABLED == 0) {
        // Do nothing.
    }
    NRF_RADIO->EVENTS_DISABLED = 0;
}

/**
 * Enable transmission on a specific frequency with full power.
 *
 * @param frequency the frequency (channel) to send on
 */
void tx(uint8_t frequency) {
    off();

    NRF_RADIO->SHORTS = RADIO_SHORTS_READY_START_Msk;
    NRF_RADIO->TXPOWER = (RADIO_TXPOWER_TXPOWER_Neg30dBm << RADIO_TXPOWER_TXPOWER_Pos);
    NRF_RADIO->MODE = (RADIO_MODE_MODE_Nrf_2Mbit << RADIO_MODE_MODE_Pos);
    NRF_RADIO->FREQUENCY = frequency;
    NRF_RADIO->TEST = (RADIO_TEST_CONST_CARRIER_Enabled << RADIO_TEST_CONST_CARRIER_Pos) |
                      (RADIO_TEST_PLL_LOCK_Enabled << RADIO_TEST_PLL_LOCK_Pos);
    NRF_RADIO->TASKS_TXEN = 1;
}

/**
 * Enable reception on a specific frequency.
 */
void rx(uint8_t frequency) {
    off();

    NRF_RADIO->SHORTS = RADIO_SHORTS_READY_START_Msk;
    NRF_RADIO->FREQUENCY = frequency;
    NRF_RADIO->TASKS_RXEN = 1;
}

typedef enum {
    OFF,
    Radio00TX,
    Radio00RX,
    Radio78TX,
    Radio78RX
} RadioState;

RadioState state = OFF;

void onButtonA(MicroBitEvent event) {
    (void) event;
    switch (state) {
        case Radio00TX:
            state = Radio00RX;
            uBit.display.scroll("RX00");
            break;
        case Radio00RX:
            state = Radio78TX;
            uBit.display.scroll("TX78");
            rx(0);
            break;
        case Radio78TX:
            state = Radio78RX;
            uBit.display.scroll("RX78");
            tx(78);
            break;
        default:
            state = Radio00TX;
            uBit.display.scroll("TX00");
            break;
    }
}

void onButtonB(MicroBitEvent event) {
    (void) event;
    switch (state) {
        case Radio00TX:
            uBit.rgb.setColour(55,0,0,0);
            uBit.display.scrollAsync("START TX00");
            tx(2);
            break;
        case Radio00RX:
            uBit.rgb.setColour(0,55,0,0);
            uBit.display.scrollAsync("START RX00");
            rx(2);
            break;
        case Radio78TX:
            uBit.rgb.setColour(255,0,0,0);
            uBit.display.scrollAsync("START TX78");
            tx(80);
            break;
        case Radio78RX:
            uBit.rgb.setColour(0,255,0,0);
            uBit.display.scrollAsync("START RX78");
            rx(80);
            break;
        default:
            /* do nothing */
            break;
    }
}

int main() {
    uBit.init();

    uBit.serial.baud(115200);
    uBit.serial.send("Radio Frequency Test\r\n");

    // initialize radio
    init();

    // initialize button listeners
    uBit.messageBus.listen(MICROBIT_ID_BUTTON_A, MICROBIT_BUTTON_EVT_CLICK, onButtonA);
    uBit.messageBus.listen(MICROBIT_ID_BUTTON_B, MICROBIT_BUTTON_EVT_CLICK, onButtonB);


    uBit.display.clear();
    uBit.display.scroll("READY");

    while (1) uBit.sleep(1000);
}
