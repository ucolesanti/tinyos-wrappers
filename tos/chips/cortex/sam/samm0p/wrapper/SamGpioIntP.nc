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
 * Wrapper for Gpio EXTI module.
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */

#include "extint.h"
generic module SamGpioIntP(uint8_t port, uint8_t channel){
	provides interface GpioInterrupt as Channel ;
}
implementation{
	struct extint_chan_conf config_extint_chan = {port,0,EXTINT_PULL_UP,true,false,EXTINT_DETECT_FALLING};

	void extint_detection_callback();

	async command error_t Channel.enableRisingEdge(){
		atomic{
			config_extint_chan.detection_criteria = EXTINT_DETECT_RISING;
			config_extint_chan.gpio_pin_pull = EXTINT_PULL_NONE;
		} 
		extint_chan_set_config(channel, &config_extint_chan);
		extint_register_callback(extint_detection_callback,channel,EXTINT_CALLBACK_TYPE_DETECT);
		extint_chan_enable_callback(channel,EXTINT_CALLBACK_TYPE_DETECT);
		return SUCCESS;
	  }

	  async command error_t Channel.enableFallingEdge(){
		  atomic{
		    config_extint_chan.detection_criteria = EXTINT_DETECT_FALLING;
		  	config_extint_chan.gpio_pin_pull = EXTINT_PULL_UP;
		  } 
		  extint_chan_set_config(channel, &config_extint_chan);
		  extint_register_callback(extint_detection_callback,channel,EXTINT_CALLBACK_TYPE_DETECT);
		  extint_chan_enable_callback(channel,EXTINT_CALLBACK_TYPE_DETECT);
		  return SUCCESS ;
	  }

	  async command error_t Channel.disable(){
		  atomic config_extint_chan.detection_criteria = EXTINT_DETECT_NONE;
			extint_chan_set_config(channel, &config_extint_chan);
			extint_chan_disable_callback(channel,EXTINT_CALLBACK_TYPE_DETECT);
			extint_unregister_callback(extint_detection_callback,channel,EXTINT_CALLBACK_TYPE_DETECT);
			return SUCCESS ;
	  }

	  

  	void extint_detection_callback()
	{
		signal Channel.fired() ;
	}
}
