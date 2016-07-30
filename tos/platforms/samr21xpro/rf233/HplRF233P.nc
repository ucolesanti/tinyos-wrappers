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
 * File modified for SamR21XplainedPro platform.
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */
#include "spi.h"
module HplRF233P
{
	provides
	{
		interface GpioCapture as IRQ;
		interface Init as PlatformInit;

//		interface SamM0pSercomSpiConfigure ;
	}

	uses
	{
//		interface HplAtm128Capture<uint16_t> as Capture;
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
//		call Capture.stop();

		return SUCCESS;
	}

	const spi_tos_config_t my_spi_config = {
		4000000UL,
		RF_SPI_SERCOM_MUX_SETTING,
		RF_SPI_SERCOM_PINMUX_PAD0,
		PINMUX_UNUSED,
		RF_SPI_SERCOM_PINMUX_PAD2,
		RF_SPI_SERCOM_PINMUX_PAD3,
		SPI_TRANSFER_MODE_3
	};

//	SERCOM_SPI_CTRLA_Type sercom4_spi_ctrla_local_config = {
//			{
//				SWRST : 0,
//				ENABLE : 0,
//				MODE : 3,
//				RUNSTDBY : 1,
//				IBON : 0,
//				DOPO : 1,
//				DIPO : 0,
//				FORM : 0,
//				CPHA : 0,
//				CPOL : 0,
//				DORD : 0
//			}
//		};
//
//		SERCOM_SPI_CTRLB_Type sercom4_spi_ctrlb_local_config = {
//			{
//				CHSIZE : 0,
//				PLOADEN : 0,
//				SSDE : 0,
//				MSSEN : 0,
//				AMODE : 0,
//				RXEN : 1
//			}
//		};


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

//	async command SERCOM_SPI_CTRLA_Type* SamM0pSercomSpiConfigure.getSpiCtrlAConfig() {
//			return &sercom4_spi_ctrla_local_config;
//	}
//
//	async command SERCOM_SPI_CTRLB_Type* SamM0pSercomSpiConfigure.getSpiCtrlBConfig() {
//		return &sercom4_spi_ctrlb_local_config;
//	}
}
