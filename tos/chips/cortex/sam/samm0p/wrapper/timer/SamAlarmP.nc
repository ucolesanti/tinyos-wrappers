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
 * Wrapper for Alarm modules. The code is inspired by AtmegaAlarmP and
 * AtmegaCounterP modules in atm128rfa1/timer folder written by Miklos Maroti.
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */

#include "tc_interrupt.h"
#include "tc.h"
generic module SamAlarmP(uint32_t dev, typedef precision_tag, typedef size_tag@integer(),uint8_t mindt,uint8_t gen, uint16_t div){
	provides interface Alarm<precision_tag,size_tag>;
	provides interface Counter<precision_tag,size_tag>;
	provides interface Init ;
}
implementation{
	struct tc_module tc_instance ;

	void callback_overflow(struct tc_module *const module_inst);
	void callback_compareMatch(struct tc_module *const module_inst);

	command error_t Init.init(){
		struct tc_config config_tc;

		tc_get_config_defaults(&config_tc);

		config_tc.counter_size    = TC_COUNTER_SIZE_16BIT;

		config_tc.clock_source = gen;
		config_tc.clock_prescaler = div;
		config_tc.run_in_standby = true ; // TODO: remove as soon as the alarm supports the dynamic switch of this feature. ndUgo

		while(tc_init(&tc_instance, (Tc*) dev, &config_tc) != STATUS_OK){

		}

		tc_enable(&tc_instance);
		tc_register_callback(&tc_instance,callback_overflow,TC_CALLBACK_OVERFLOW);
		tc_register_callback(&tc_instance,callback_compareMatch,TC_CALLBACK_CC_CHANNEL0);
		
		tc_enable_callback(&tc_instance, TC_CALLBACK_OVERFLOW);

		return SUCCESS;
	}

	async command size_tag Counter.get()
		{
			return (size_tag) tc_get_count_value(&tc_instance);
		}

		default async event void Counter.overflow() { }


		void callback_overflow(struct tc_module *const module_inst){
			//TODO: don't know if I need to reset here...
			signal Counter.overflow();
		}

		async command bool Counter.isOverflowPending()
		{
			atomic return tc_instance.hw->COUNT16.INTFLAG.bit.OVF ;
		}

		async command void Counter.clearOverflow()
		{
			tc_instance.hw->COUNT16.INTFLAG.reg = TC_INTFLAG_OVF ;
		}

		default async event void Alarm.fired() { }

		// called in atomic context
		void callback_compareMatch(struct tc_module *const module_inst){
			tc_disable_callback(&tc_instance, TC_CALLBACK_CC_CHANNEL0);
			signal Alarm.fired();
		}



		async command void Alarm.stop()
		{
			tc_disable_callback(&tc_instance, TC_CALLBACK_CC_CHANNEL0);
		}

		async command bool Alarm.isRunning()
		{
			return tc_instance.hw->COUNT16.INTENSET.bit.OVF ;
		}

		// callers make sure that time is always in the future
		void setAlarm(size_tag time)
		{
			tc_set_compare_value(&tc_instance,TC_COMPARE_CAPTURE_CHANNEL_0,time);
			tc_clear_status(&tc_instance,TC_STATUS_CHANNEL_0_MATCH);
			tc_enable_callback(&tc_instance, TC_CALLBACK_CC_CHANNEL0);
		}

		async command void Alarm.startAt(size_tag nt0, size_tag ndt)
		{
			atomic
			{
				// current time + time needed to set alarm
				size_tag n = tc_get_count_value(&tc_instance) + mindt;
				// if alarm is set in the future, where n-nt0 is the time passed since nt0
				if( (size_tag)(n - nt0) < ndt )
					n = nt0 + ndt;

				setAlarm(n);


			}
		}

		async command void Alarm.start(size_tag ndt)
		{
			atomic
			{
				size_tag n = tc_get_count_value(&tc_instance);

				// calculate the next alarm
				n += (mindt > ndt) ? mindt : ndt;

				setAlarm(n);

			}
		}

		async command size_tag Alarm.getNow()
		{
			return tc_get_count_value(&tc_instance);
		}

		async command size_tag Alarm.getAlarm()
		{
			return (size_tag) tc_get_capture_value(&tc_instance,TC_COMPARE_CAPTURE_CHANNEL_0);
		}

}

