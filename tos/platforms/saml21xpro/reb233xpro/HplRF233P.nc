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
 * File modified for SamD21XplainedPro platform with REB233XPRO extension 
 * module plugged on EXT1 header.
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 31, 2016
 */
 
#include "spi.h"
module HplRF233P
{
	provides
	{
		interface GpioCapture as IRQ;
		interface Init as PlatformInit;
	}

	uses
	{
		interface GeneralIO as PortCLKM;
		interface GeneralIO as PortIRQ;
		interface GpioInterrupt as IRQInt ;
		interface LocalTime<TRadio>;
		interface SpiConfig;
	}
}

implementation
{
	command error_t PlatformInit.init()
	{
		call PortCLKM.makeInput();
		call PortCLKM.clr();
		call PortIRQ.makeInput();
		call PortIRQ.clr();

		return SUCCESS;
	}

	const spi_tos_config_t my_spi_config = {
		4000000UL,
		AT86RFX_SPI_SERCOM_MUX_SETTING,
		AT86RFX_SPI_SERCOM_PINMUX_PAD0,
		AT86RFX_SPI_SERCOM_PINMUX_PAD1,
		AT86RFX_SPI_SERCOM_PINMUX_PAD2,
		AT86RFX_SPI_SERCOM_PINMUX_PAD3,
		SPI_TRANSFER_MODE_3
	};

	async event void IRQInt.fired(){
		uint16_t time ;
		atomic{
			time = call LocalTime.get() ;
		}
		signal IRQ.captured(time);
	}

	default async event void IRQ.captured(uint16_t time)
	{
	}

	async command error_t IRQ.captureRisingEdge()
	{
		call IRQInt.enableRisingEdge() ;
		return SUCCESS;
	}

	async command error_t IRQ.captureFallingEdge()
	{
		// falling edge comes when the IRQ_STATUS register of the RF230 is read
		return FAIL;	
	}

	async command void IRQ.disable()
	{
		call IRQInt.disable() ;
	}

	async event const spi_tos_config_t* SpiConfig.getConfig(){
		  return &my_spi_config;
  	}

}
