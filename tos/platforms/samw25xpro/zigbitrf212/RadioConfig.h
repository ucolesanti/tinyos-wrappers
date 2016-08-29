/*
 * Copyright (c) 2007, Vanderbilt University
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
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
 *
 * Author: Miklos Maroti
 */

#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#include <Timer.h>
#include <RF212DriverLayer.h>
//#include "TimerConfig.h"
//#include <util/crc16.h>


/* The number of microseconds a sending mote will wait for an acknowledgement */
#ifdef DEFAULT_RADIO_RF212
	#ifndef SOFTWAREACK_TIMEOUT_PLUS
	#define SOFTWAREACK_TIMEOUT_PLUS	3000
	#endif
#else
	#ifndef SOFTWAREACK_TIMEOUT
	#define SOFTWAREACK_TIMEOUT	1000
	#endif
#endif

//RF212 Part
#ifndef RF212_PHY_MODE
	/*
	 *  American (915Mhz) compatible data rates
	 */ 
	
// 	#define RF212_PHY_MODE RF212_DATA_MODE_BPSK_40 
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_250 
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_500 
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_1000

	/*
	 *  European (868Mhz) compatible data rates
	 */ 

 	#define RF212_PHY_MODE RF212_DATA_MODE_BPSK_20
//	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_RC_100
//	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_RC_200
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_RC_400
	
	/*
	 *  Chinese (780Mhz) compatible data rates
	 */ 
	
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_250 
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_500 
// 	#define RF212_PHY_MODE RF212_DATA_MODE_OQPSK_SIN_1000
#endif
enum
{
	/**
	 * This is the value of the TRX_CTRL_0 register
	 * which configures the output pin currents and the CLKM clock
	 */
	RF212_TRX_CTRL_0_VALUE = 0,
	
	/**
	 * This is the value of the TRX_CTRL_2 register which configures the 
	 * data rate and modulation type. Use the constants from RF212DriverLayer.h
	 */
	
	RF212_TRX_CTRL_2_VALUE = RF212_PHY_MODE,


	/**
	 * This is the default value of the CCA_MODE field in the PHY_CC_CCA register
	 * which is used to configure the default mode of the clear channel assesment
	 */
	RF212_CCA_MODE_VALUE = RF212_CCA_MODE_3,

	/**
	 * This is the value of the CCA_THRES register that controls the
	 * energy levels used for clear channel assesment
	 */
	RF212_CCA_THRES_VALUE = 0x77,
};

#ifndef RF212_GC_TX_OFFS
#define RF212_GC_TX_OFFS 3 //recommended modes by the datasheet Table 7-16 BPSK: 3, QPSK: 2
#endif

/* This is the default value of the TX_PWR field of the PHY_TX_PWR register. */
#ifndef RF212_DEF_RFPOWER
#define RF212_DEF_RFPOWER	0xE8
#endif

/* This is the default value of the CHANNEL field of the PHY_CC_CCA register. */
#ifndef RF212_DEF_CHANNEL
#define RF212_DEF_CHANNEL	0
#endif

/**
 * This sets the number of neighbors the radio stack stores information (like sequence number)
 */
#define RF212_NEIGHBORHOOD_SIZE 5

/**
 * This is the timer type of the radio alarm interface
 */
typedef T32khz TRadio;
typedef uint32_t tradio_size;

/**
 * The number of radio alarm ticks per one microsecond (0.9216). 
 * We use integers and no parentheses just to make deputy happy.
 * Ok, further hacks were required for deputy, I removed 00 from the
 * beginning and end to ba able to handle longer wait periods.
 */
//#define RADIO_ALARM_MICROSEC	(73728UL / MHZ / 32) * (1 << MICA_DIVIDE_ONE_FOR_32KHZ_LOG2) / 10000UL
#define RADIO_ALARM_MICROSEC 0.031250 //TODO: need to check the correct value! ndUgo
/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 */
//#define RADIO_ALARM_MILLI_EXP	(5 + MICA_DIVIDE_ONE_FOR_32KHZ_LOG2)
#define RADIO_ALARM_MILLI_EXP 5 // 32khz clock



#endif//__RADIOCONFIG_H__
