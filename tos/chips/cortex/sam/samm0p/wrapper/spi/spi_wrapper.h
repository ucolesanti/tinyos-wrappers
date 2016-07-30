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
 * This file defines the struct holding the spi configuration parameters.
 * It also provides the default configuration for the SPI module. 
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */

#ifndef SPI_WRAPPER_H_
#define SPI_WRAPPER_H_
#include "spi.h"

typedef struct spi_tos_config{
	uint32_t baud;// baudrate
	enum spi_signal_mux_setting muxSetting;// mux
	uint32_t pad0;// pad0
	uint32_t pad1;// pad1
	uint32_t pad2;// pad2
	uint32_t pad3;// pad3
	enum spi_transfer_mode transfer_mode;
}spi_tos_config_t;


const spi_tos_config_t spi_tos_config_default = {
	100000UL,
	SPI_SIGNAL_MUX_SETTING_D,
	PINMUX_DEFAULT,
	PINMUX_DEFAULT,
	PINMUX_DEFAULT,
	PINMUX_DEFAULT,
	SPI_TRANSFER_MODE_0
};

#endif /* SPI_WRAPPER_H_ */
