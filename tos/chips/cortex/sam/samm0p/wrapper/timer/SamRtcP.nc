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
 * Wrapper for the Low power RTC module. The code is inspired by AtmegaAlarmP and
 * AtmegaCounterP modules in atm128rfa1/timer folder written by Miklos Maroti.
 *
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */

#include "rtc_count_interrupt.h"
#include "rtc_count.h"
module SamRtcP{
	provides interface Counter<TMilli, uint32_t>;
	provides interface Alarm<TMilli, uint32_t>;
	provides interface Init ;
}
implementation{
	struct rtc_module rtc_instance;

	void rtc_overflow_callback(void);
	void rtc_compare0_callback(void);


	command error_t Init.init(){
		struct rtc_count_config config_rtc_count;
		rtc_count_get_config_defaults(&config_rtc_count);

			config_rtc_count.prescaler           = RTC_COUNT_PRESCALER_DIV_32;
			config_rtc_count.mode                = RTC_COUNT_MODE_32BIT;

			config_rtc_count.continuously_update = false;

		rtc_count_init(&rtc_instance, RTC, &config_rtc_count);
		rtc_count_enable(&rtc_instance);
		rtc_count_register_callback(&rtc_instance, rtc_overflow_callback, RTC_COUNT_CALLBACK_OVERFLOW);
		rtc_count_register_callback(&rtc_instance, rtc_compare0_callback, RTC_COUNT_CALLBACK_COMPARE_0);
		rtc_count_enable_callback(&rtc_instance, RTC_COUNT_CALLBACK_OVERFLOW);
		return SUCCESS ;
	}

	async command uint32_t Counter.get()
	{
		return rtc_count_get_count(&rtc_instance);
	}

	default async event void Counter.overflow() { }


	void rtc_overflow_callback(){
		//TODO: don't know if I need to reset here...
		signal Counter.overflow();
	}


	async command bool Counter.isOverflowPending()
	{
		return rtc_instance.hw->MODE0.INTFLAG.bit.OVF ;
	}

	async command void Counter.clearOverflow()
	{
		rtc_instance.hw->MODE0.INTFLAG.reg = RTC_MODE0_INTFLAG_OVF ;
	}

	default async event void Alarm.fired() { }

	// called in atomic context
	void rtc_compare0_callback(){
		rtc_count_disable_callback(&rtc_instance, RTC_COUNT_CALLBACK_COMPARE_0);
		signal Alarm.fired();
	}

	async command void Alarm.stop()
	{
		rtc_count_disable_callback(&rtc_instance, RTC_COUNT_CALLBACK_COMPARE_0);
	}

	async command bool Alarm.isRunning()
	{
		return rtc_instance.hw->MODE0.INTENSET.bit.OVF ;
	}

	// callers make sure that time is always in the future
	void setAlarm(uint32_t time)
	{
		rtc_count_set_compare(&rtc_instance,time,RTC_COUNT_COMPARE_0);
		rtc_count_clear_compare_match(&rtc_instance,RTC_COUNT_COMPARE_0);
		rtc_count_enable_callback(&rtc_instance, RTC_COUNT_CALLBACK_COMPARE_0);
	}

	async command void Alarm.startAt(uint32_t nt0, uint32_t ndt)
	{
		atomic
		{
			// current time + time needed to set alarm
			uint32_t n = rtc_count_get_count(&rtc_instance) + 1; // 1 is mindt

			// if alarm is set in the future, where n-nt0 is the time passed since nt0
			if( (uint32_t)(n - nt0) < ndt )
				n = nt0 + ndt;

			setAlarm(n);

		}
	}

	async command void Alarm.start(uint32_t ndt)
	{
		atomic
		{
			uint32_t n = rtc_count_get_count(&rtc_instance);

			// calculate the next alarm
			n += (1 > ndt) ? 1 : ndt; // 1 is mindt

			setAlarm(n);

		}
	}

	async command uint32_t Alarm.getNow()
	{
		return rtc_count_get_count(&rtc_instance);
	}

	async command uint32_t Alarm.getAlarm()
	{
		uint32_t value = 0;
		rtc_count_get_compare(&rtc_instance,&value,RTC_COUNT_COMPARE_0);
		return value;
	}

}

