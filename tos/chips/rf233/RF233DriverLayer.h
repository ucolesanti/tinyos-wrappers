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
 * File adapted for AT86RF233 chip.
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */

#ifndef __RF233DRIVERLAYER_H__
#define __RF233DRIVERLAYER_H__

typedef nx_struct rf233_header_t
{
	nxle_uint8_t length;
} rf233_header_t;

typedef struct rf233_metadata_t
{
	uint8_t lqi;
	union
	{
		uint8_t power;
		uint8_t rssi;
	}__attribute__((packed));
} __attribute__((packed)) rf233_metadata_t;

enum rf233_registers_enum
{
	RF233_TRX_STATUS = 0x01,
	RF233_TRX_STATE = 0x02,
	RF233_TRX_CTRL_0 = 0x03,
	RF233_TRX_CTRL_1 = 0x04, // added in rf233
	RF233_PHY_TX_PWR = 0x05,
	RF233_PHY_RSSI = 0x06,
	RF233_PHY_ED_LEVEL = 0x07,
	RF233_PHY_CC_CCA = 0x08,
	RF233_CCA_THRES = 0x09,
	RF233_IRQ_MASK = 0x0E,
	RF233_IRQ_STATUS = 0x0F,
	RF233_VREG_CTRL = 0x10,
	RF233_BATMON = 0x11,
	RF233_XOSC_CTRL = 0x12,
	RF233_PLL_CF = 0x1A,
	RF233_PLL_DCU = 0x1B,
	RF233_PART_NUM = 0x1C,
	RF233_VERSION_NUM = 0x1D,
	RF233_MAN_ID_0 = 0x1E,
	RF233_MAN_ID_1 = 0x1F,
	RF233_SHORT_ADDR_0 = 0x20,
	RF233_SHORT_ADDR_1 = 0x21,
	RF233_PAN_ID_0 = 0x22,
	RF233_PAN_ID_1 = 0x23,
	RF233_IEEE_ADDR_0 = 0x24,
	RF233_IEEE_ADDR_1 = 0x25,
	RF233_IEEE_ADDR_2 = 0x26,
	RF233_IEEE_ADDR_3 = 0x27,
	RF233_IEEE_ADDR_4 = 0x28,
	RF233_IEEE_ADDR_5 = 0x29,
	RF233_IEEE_ADDR_6 = 0x2A,
	RF233_IEEE_ADDR_7 = 0x2B,
	RF233_XAH_CTRL_0 = 0x2C,
	RF233_CSMA_SEED_0 = 0x2D,
	RF233_CSMA_SEED_1 = 0x2E,
};

enum rf233_trx_register_enums
{
	RF233_CCA_DONE = 1 << 7,
	RF233_CCA_STATUS = 1 << 6,
	RF233_TRX_STATUS_MASK = 0x1F,
	RF233_P_ON = 0,
	RF233_BUSY_RX = 1,
	RF233_BUSY_TX = 2,
	RF233_RX_ON = 6,
	RF233_TRX_OFF = 8,
	RF233_PLL_ON = 9,
	RF233_SLEEP = 15,
	RF233_BUSY_RX_AACK = 17,
	RF233_BUSR_TX_ARET = 18,
	RF233_RX_AACK_ON = 22,
	RF233_TX_ARET_ON = 25,
//	RF233_RX_ON_NOCLK = 28, // TODO: move to rx_on state, if CLKM need to be disabled, it has to be done manually in trx_CTRL[2:0] ndUgo
	RF233_AACK_ON_NOCLK = 29,
	RF233_BUSY_RX_AACK_NOCLK = 30,
	RF233_STATE_TRANSITION_IN_PROGRESS = 31,
	RF233_TRAC_STATUS_MASK = 0xE0,
	RF233_TRAC_SUCCESS = 0,
	RF233_TRAC_SUCCESS_DATA_PENDING = 1 << 5,
	RF233_TRAC_CHANNEL_ACCESS_FAILURE = 3 << 5,
	RF233_TRAC_NO_ACK = 5 << 5,
	RF233_TRAC_INVALID = 7 << 5,
	RF233_TRX_CMD_MASK = 0x1F,
	RF233_NOP = 0,
	RF233_TX_START = 2,
	RF233_FORCE_TRX_OFF = 3,
	RF233_FORCE_PLL_ON = 4,
	RF233_PREP_DEEP_SLEEP = 10,

};

enum rf233_phy_register_enums
{
//	RF233_TX_AUTO_CRC_ON = 1 << 7, TODO: it has moved to register TRX_CTRL_1 bit 5
	RF233_TX_PWR_MASK = 0x0F,
	RF233_RSSI_MASK = 0x1F,
	RF233_CCA_REQUEST = 1 << 7,
	RF233_CCA_MODE_0 = 0 << 5,
	RF233_CCA_MODE_1 = 1 << 5,
	RF233_CCA_MODE_2 = 2 << 5,
	RF233_CCA_MODE_3 = 3 << 5,
	RF233_CHANNEL_DEFAULT = 11,
	RF233_CHANNEL_MASK = 0x1F,
	RF233_CCA_CS_THRES_SHIFT = 4,
	RF233_CCA_ED_THRES_SHIFT = 0,
};

enum rf233_irq_register_enums
{
	RF233_IRQ_7_BAT_LOW = 1 << 7,
	RF233_IRQ_6_TRX_UR = 1 << 6,
	RF233_IRQ_4_AWAKE_ED_END = 1 << 4,
	RF233_IRQ_3_TRX_END = 1 << 3,
	RF233_IRQ_2_RX_START = 1 << 2,
	RF233_IRQ_1_PLL_UNLOCK = 1 << 1,
	RF233_IRQ_0_PLL_LOCK = 1 << 0,
};

enum rf233_control0_register_enums
{
	RF233_AVREG_EXT = 1 << 7,
	RF233_AVDD_OK = 1 << 6,
	RF233_DVREG_EXT = 1 << 3,
	RF233_DVDD_OK = 1 << 2,
	RF233_BATMON_OK = 1 << 5,
	RF233_BATMON_VHR = 1 << 4,
	RF233_BATMON_VTH_MASK = 0x0F,
	RF233_XTAL_MODE_OFF = 0 << 4,
	RF233_XTAL_MODE_EXTERNAL = 4 << 4,
	RF233_XTAL_MODE_INTERNAL = 15 << 4,
};

enum rf233_control1_register_enums
{
	RF233_TX_AUTO_CRC_ON = 1 << 5,

};

enum rf233_pll_register_enums
{
	RF233_PLL_CF_START = 1 << 7,
	RF233_PLL_DCU_START = 1 << 7,
};

enum rf233_spi_command_enums
{
	RF233_CMD_REGISTER_READ = 0x80,
	RF233_CMD_REGISTER_WRITE = 0xC0,
	RF233_CMD_REGISTER_MASK = 0x3F,
	RF233_CMD_FRAME_READ = 0x20,
	RF233_CMD_FRAME_WRITE = 0x60,
	RF233_CMD_SRAM_READ = 0x00,
	RF233_CMD_SRAM_WRITE = 0x40,
};

#endif//__RF233DRIVERLAYER_H__
