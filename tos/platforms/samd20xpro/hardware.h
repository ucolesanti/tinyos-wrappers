/*									
 * Copyright (c) 2015-2016 Ugo Maria Colesanti.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of its 
 *   contributors  may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 /*
 * @author Ugo Maria Colesanti
 * @date   Jul 31, 2016
 */

#ifndef HARDWARE_H
#define HARDWARE_H

#include "samd20.h"
#include "board.h"
// From module: PORT - GPIO Pin Control
#include <port.h>

 // From module: RTC - Real Time Counter in Count Mode (Callback APIs)
#include <rtc_count.h>
#include <rtc_count_interrupt.h>
#include <rtc_tamper.h>

 #include "conf_extint.h"

#include "cortexm0hardware.h"

enum{
	SAMM0_PWR_IDLE0 = 0,
	SAMM0_PWR_IDLE2 = 1,
	SAMM0_PWR_STDBY = 2,
};

typedef uint8_t mcu_power_t @combine("mcombine");

/* Combine function.  */
mcu_power_t mcombine(mcu_power_t m1, mcu_power_t m2) @safe() {
  return (m1 < m2)? m1: m2;
}

////// PORT DEFINE
#define PIN_PA0 PIN_PA00
#define PIN_PA1 PIN_PA01
#define PIN_PA2 PIN_PA02
#define PIN_PA3 PIN_PA03
#define PIN_PA4 PIN_PA04
#define PIN_PA5 PIN_PA05
#define PIN_PA6 PIN_PA06
#define PIN_PA7 PIN_PA07
#define PIN_PA8 PIN_PA08
#define PIN_PA9 PIN_PA09

#define PIN_PB0 PIN_PB00
#define PIN_PB1 PIN_PB01
#define PIN_PB2 PIN_PB02
#define PIN_PB3 PIN_PB03
#define PIN_PB4 PIN_PB04
#define PIN_PB5 PIN_PB05
#define PIN_PB6 PIN_PB06
#define PIN_PB7 PIN_PB07
#define PIN_PB8 PIN_PB08
#define PIN_PB9 PIN_PB09

#define PIN_PC0 PIN_PC00
#define PIN_PC1 PIN_PC01
#define PIN_PC2 PIN_PC02
#define PIN_PC3 PIN_PC03
#define PIN_PC4 PIN_PC04
#define PIN_PC5 PIN_PC05
#define PIN_PC6 PIN_PC06
#define PIN_PC7 PIN_PC07
#define PIN_PC8 PIN_PC08
#define PIN_PC9 PIN_PC09

 /*
 * conf_pins.h
 *
 *  Created on: Jul 29, 2015
 *      Author: obren
 */


#define HPL_PIN_PA0	0
#define HPL_PIN_PA1	1
#define HPL_PIN_PA2	2
#define HPL_PIN_PA3	3
#define HPL_PIN_PA4	4
#define HPL_PIN_PA5	5
#define HPL_PIN_PA6	6
#define HPL_PIN_PA7	7
#define HPL_PIN_PA8	8
#define HPL_PIN_PA9	9
#define HPL_PIN_PA10	10
#define HPL_PIN_PA11	11
#define HPL_PIN_PA12	12
#define HPL_PIN_PA13	13
#define HPL_PIN_PA14	14
#define HPL_PIN_PA15	15
#define HPL_PIN_PA16	16
#define HPL_PIN_PA17	17
#define HPL_PIN_PA18	18
#define HPL_PIN_PA19	19
#define HPL_PIN_PA20	20
#define HPL_PIN_PA21	21
#define HPL_PIN_PA22	22
#define HPL_PIN_PA23	23
#define HPL_PIN_PA24	24
#define HPL_PIN_PA25	25
#define HPL_PIN_PA26	26
#define HPL_PIN_PA27	27
#define HPL_PIN_PA28	28
#define HPL_PIN_PA29	29
#define HPL_PIN_PA30	30
#define HPL_PIN_PA31	31
#define HPL_PIN_PB0	32
#define HPL_PIN_PB1	33
#define HPL_PIN_PB2	34
#define HPL_PIN_PB3	35
#define HPL_PIN_PB4	36
#define HPL_PIN_PB5	37
#define HPL_PIN_PB6	38
#define HPL_PIN_PB7	39
#define HPL_PIN_PB8	40
#define HPL_PIN_PB9	41
#define HPL_PIN_PB10	42
#define HPL_PIN_PB11	43
#define HPL_PIN_PB12	44
#define HPL_PIN_PB13	45
#define HPL_PIN_PB14	46
#define HPL_PIN_PB15	47
#define HPL_PIN_PB16	48
#define HPL_PIN_PB17	49
#define HPL_PIN_PB18	50
#define HPL_PIN_PB19	51
#define HPL_PIN_PB20	52
#define HPL_PIN_PB21	53
#define HPL_PIN_PB22	54
#define HPL_PIN_PB23	55
#define HPL_PIN_PB24	56
#define HPL_PIN_PB25	57
#define HPL_PIN_PB26	58
#define HPL_PIN_PB27	59
#define HPL_PIN_PB28	60
#define HPL_PIN_PB29	61
#define HPL_PIN_PB30	62
#define HPL_PIN_PB31	63
#define HPL_PIN_PC0	64
#define HPL_PIN_PC1	65
#define HPL_PIN_PC2	66
#define HPL_PIN_PC3	67
#define HPL_PIN_PC4	68
#define HPL_PIN_PC5	69
#define HPL_PIN_PC6	70
#define HPL_PIN_PC7	71
#define HPL_PIN_PC8	72
#define HPL_PIN_PC9	73
#define HPL_PIN_PC10	74
#define HPL_PIN_PC11	75
#define HPL_PIN_PC12	76
#define HPL_PIN_PC13	77
#define HPL_PIN_PC14	78
#define HPL_PIN_PC15	79
#define HPL_PIN_PC16	80
#define HPL_PIN_PC17	81
#define HPL_PIN_PC18	82
#define HPL_PIN_PC19	83
#define HPL_PIN_PC20	84
#define HPL_PIN_PC21	85
#define HPL_PIN_PC22	86
#define HPL_PIN_PC23	87
#define HPL_PIN_PC24	88
#define HPL_PIN_PC25	89
#define HPL_PIN_PC26	90
#define HPL_PIN_PC27	91
#define HPL_PIN_PC28	92
#define HPL_PIN_PC29	93
#define HPL_PIN_PC30	94
#define HPL_PIN_PC31	95



#endif // HARDWARE_H
