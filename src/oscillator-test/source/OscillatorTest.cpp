/**
 * Oszillator test.
 *
 * Creates a timer to output a signal for a given time.
 *
 * @copyright (c) Calliope gGmbH.
 *
 * Licensed under the Apache Software License 2.0 (ASL 2.0)
 * Portions (c) Copyright British Broadcasting Corporation under MIT License.
 *
 * @author Matthias L. Jugel <leo@calliope.cc>
 */


#include "mbed.h"
#include <nrf_gpio.h>


int main(void) {
    PwmOut pwm(p1);
    pwm.period_ms(100);
    pwm.write(0.50f);  // 50% duty cycle
    while (true) {
        // https://devzone.nordicsemi.com/index.php/how-do-you-put-the-nrf51822-chip-to-sleep#reply-1589
        __WFE();
        __SEV();
        __WFE();
    }
}