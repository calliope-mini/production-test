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
    Radio02TX,
    Radio02RX,
    Radio40TX,
    Radio40RX,
    Radio80TX,
    Radio80RX
} RadioState;

int state = OFF;
int operation = 0;

void onButtonA(MicroBitEvent event) {
    (void) event;

    ++state;
    operation = 0;
    switch (state) {
        case Radio02TX:
            uBit.display.scrollAsync("TX02");
            break;
        case Radio02RX:
            uBit.display.scrollAsync("RX02");
            break;
        case Radio40TX:
            uBit.display.scrollAsync("TX40");
            break;
        case Radio40RX:
            uBit.display.scrollAsync("RX40");
            break;
        case Radio80TX:
            uBit.display.scrollAsync("TX80");
            break;
        case Radio80RX:
            uBit.display.scrollAsync("RX80");
            break;
        default:
            state = Radio02TX;
            uBit.display.scrollAsync("TX00");
            break;
    }
}

void onButtonB(MicroBitEvent event) {
    (void) event;
    operation = 1;
    tx(OFF);
    rx(OFF);
    switch (state) {
        case Radio02TX:
            uBit.display.scrollAsync("START TX 2402");
            tx(2);
            break;
        case Radio02RX:
            uBit.display.scrollAsync("START RX 2402");
            rx(2);
            break;
        case Radio40TX:
            uBit.display.scrollAsync("START TX 2440");
            tx(40);
            break;
        case Radio40RX:
            uBit.display.scrollAsync("START RX 2440");
            rx(40);
            break;
        case Radio80TX:
            uBit.display.scrollAsync("START TX 2480");
            tx(80);
            break;
        case Radio80RX:
            uBit.display.scrollAsync("START RX 2480");
            rx(80);
            break;
        default:
            /* do nothing */
            break;
    }
}

const uint8_t LED[32] = {
        0, 1, 2, 3, 4, 5, 7, 9,
        12, 15, 18, 22, 27, 32, 38, 44,
        51, 58, 67, 76, 86, 96, 108, 120,
        134, 148, 163, 180, 197, 216, 235, 255
};

int main() {
    uBit.init();

    uBit.serial.baud(115200);
    uBit.serial.send("Radio Frequency Test\r\n");

    // initialize radio
    init();

    // initialize button listeners
    uBit.messageBus.listen(MICROBIT_ID_BUTTON_A, MICROBIT_BUTTON_EVT_CLICK, onButtonA);
    uBit.messageBus.listen(MICROBIT_ID_BUTTON_B, MICROBIT_BUTTON_EVT_CLICK, onButtonB);

    uBit.rgb.setMaxBrightness(255);
    uBit.display.clear();
    uBit.display.scroll("READY");

    int fade = 1;
    uint8_t onoff = 0;
    int color = 0;
    while (1) {
        if (operation) {
            switch (state) {
                case Radio02TX:
                case Radio40TX:
                case Radio80TX:
                    uBit.rgb.setColour(LED[color], 0, 0, 0);
                    color += fade;
                    if (color <= 0 || color >= 31) fade = -fade;
                    break;
                case Radio02RX:
                case Radio40RX:
                case Radio80RX:
                    uBit.rgb.setColour(0, LED[color], 0, 0);
                    color += fade;
                    if (color <= 0 || color >= 31) fade = -fade;

                    break;
                default:
                    break;
            }
            uBit.sleep(50);
        } else {
            uBit.rgb.setColour(0, 0, 0, 0);
            uBit.display.image.setPixelValue(4, 4, onoff = !onoff);
            uBit.sleep(500);
        }
    }
}
