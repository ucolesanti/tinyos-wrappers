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
 * Author: Branislav Kusy (bugfixes)
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

#include <RF233DriverLayer.h>
#include <Tasklet.h>
#include <RadioAssert.h>
#include <TimeSyncMessageLayer.h>
#include <RadioConfig.h>

module RF233DriverLayerP
{
	provides
	{
		interface Init as PlatformInit @exactlyonce();
		interface Init as SoftwareInit @exactlyonce();

		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
		interface RadioPacket;

		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint8_t> as PacketTimeSyncOffset;
		interface PacketField<uint8_t> as PacketLinkQuality;
		interface LinkPacketMetadata;
	}

	uses
	{
		interface GeneralIO as SELN;
		interface Resource as SpiResource;

		interface FastSpiByte;

		interface GeneralIO as SLP_TR;
		interface GeneralIO as RSTN;

		interface GpioCapture as IRQ;

		interface BusyWait<TMicro, uint16_t>;
		interface LocalTime<TRadio>;

		interface RF233DriverConfig as Config;

		interface PacketFlag as TransmitPowerFlag;
		interface PacketFlag as RSSIFlag;
		interface PacketFlag as TimeSyncFlag;

		interface PacketTimeStamp<TRadio, uint32_t>;

		interface Tasklet;
		interface RadioAlarm;

#ifdef RADIO_DEBUG
		interface DiagMsg;
#endif

	}
}

implementation
{
	rf233_header_t* getHeader(message_t* msg)
	{
		return ((void*)msg) + call Config.headerLength(msg);
	}

	void* getPayload(message_t* msg)
	{
		return ((void*)msg) + call RadioPacket.headerLength(msg);
	}

	rf233_metadata_t* getMeta(message_t* msg)
	{
		return ((void*)msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg);
	}

/*----------------- STATE -----------------*/

	tasklet_norace uint8_t state;
	enum
	{
		STATE_P_ON = 0,
		STATE_SLEEP = 1,
		STATE_SLEEP_2_TRX_OFF = 2,
		STATE_TRX_OFF = 3,
		STATE_TRX_OFF_2_RX_ON = 4,
		STATE_RX_ON = 5,
		STATE_BUSY_TX_2_RX_ON = 6,
	};

	tasklet_norace uint8_t cmd;
	enum
	{
		CMD_NONE = 0,			// the state machine has stopped
		CMD_TURNOFF = 1,		// goto SLEEP state
		CMD_STANDBY = 2,		// goto TRX_OFF state
		CMD_TURNON = 3,			// goto RX_ON state
		CMD_TRANSMIT = 4,		// currently transmitting a message
		CMD_RECEIVE = 5,		// currently receiving a message
		CMD_CCA = 6,			// performing clear chanel assesment
		CMD_CHANNEL = 7,		// changing the channel
		CMD_SIGNAL_DONE = 8,		// signal the end of the state transition
		CMD_DOWNLOAD = 9,		// download the received message
	};

	norace bool radioIrq;

	tasklet_norace uint8_t txPower;
	tasklet_norace uint8_t channel;

	tasklet_norace message_t* rxMsg;
	message_t rxMsgBuffer;

	uint16_t capturedTime;	// the current time when the last interrupt has occured

	tasklet_norace uint8_t rssiClear;
	tasklet_norace uint8_t rssiBusy;

/*----------------- REGISTER -----------------*/

	inline void writeRegister(uint8_t reg, uint8_t value)
	{
		RADIO_ASSERT( call SpiResource.isOwner() );
		RADIO_ASSERT( reg == (reg & RF233_CMD_REGISTER_MASK) );

		call SELN.clr();
		call FastSpiByte.splitWrite(RF233_CMD_REGISTER_WRITE | reg);
		call FastSpiByte.splitReadWrite(value);
		call FastSpiByte.splitRead();
		call SELN.set();
	}

	inline uint8_t readRegister(uint8_t reg)
	{
		RADIO_ASSERT( call SpiResource.isOwner() );
		RADIO_ASSERT( reg == (reg & RF233_CMD_REGISTER_MASK) );

		call SELN.clr();
		call FastSpiByte.splitWrite(RF233_CMD_REGISTER_READ | reg);
		call FastSpiByte.splitReadWrite(0);
		reg = call FastSpiByte.splitRead();
		call SELN.set();

		return reg;
	}

/*----------------- ALARM -----------------*/

	enum
	{
		SLEEP_WAKEUP_TIME = (uint16_t)(880 * RADIO_ALARM_MICROSEC),
		CCA_REQUEST_TIME = (uint16_t)(140 * RADIO_ALARM_MICROSEC),

		TX_SFD_DELAY = (uint16_t)(176 * RADIO_ALARM_MICROSEC),
		RX_SFD_DELAY = (uint16_t)(8 * RADIO_ALARM_MICROSEC),
	};

	tasklet_async event void RadioAlarm.fired()
	{

		if( state == STATE_SLEEP_2_TRX_OFF )
			state = STATE_TRX_OFF;
		else if( cmd == CMD_CCA )
		{
			uint8_t cca;

			RADIO_ASSERT( state == STATE_RX_ON );

			cmd = CMD_NONE;
			cca = readRegister(RF233_TRX_STATUS);

			RADIO_ASSERT( (cca & RF233_TRX_STATUS_MASK) == RF233_RX_ON );

			signal RadioCCA.done( (cca & RF233_CCA_DONE) ? ((cca & RF233_CCA_STATUS) ? SUCCESS : EBUSY) : FAIL );
		}
		else
			RADIO_ASSERT(FALSE);

		// make sure the rest of the command processing is called
		call Tasklet.schedule();
	}

/*----------------- INIT -----------------*/

	command error_t PlatformInit.init()
	{
		call SELN.makeOutput();
		call SELN.set();
		call SLP_TR.makeOutput();
		call SLP_TR.clr();
		call RSTN.makeOutput();
		call RSTN.set();

		rxMsg = &rxMsgBuffer;

		// these are just good approximates
		rssiClear = 0;
		rssiBusy = 90;

		return SUCCESS;
	}

	command error_t SoftwareInit.init()
	{
		// for powering up the radio
		return call SpiResource.request();
	}

	void initRadio()
	{
		call BusyWait.wait(510);

		call RSTN.clr();
		call SLP_TR.clr();
		call BusyWait.wait(6);
		call RSTN.set();


		writeRegister(RF233_TRX_CTRL_0, RF233_TRX_CTRL_0_VALUE);
		writeRegister(RF233_TRX_CTRL_1, 0x20) ; //  -> AUTO_CRC on, IRQ_MASK_MODE off
		writeRegister(RF233_TRX_STATE, RF233_TRX_OFF);

		call BusyWait.wait(510);
//		writeRegister(RF233_IRQ_MASK, RF233_IRQ_6_TRX_UR | RF233_IRQ_0_PLL_LOCK | RF233_IRQ_3_TRX_END | RF233_IRQ_2_RX_START | RF233_IRQ_4_AWAKE_ED_END);

//		writeRegister(RF233_IRQ_MASK, RF233_IRQ_4_AWAKE_ED_END); // enable wakeup interrupt

		writeRegister(RF233_CCA_THRES, RF233_CCA_THRES_VALUE);
		writeRegister(RF233_PHY_TX_PWR, (RF233_DEF_RFPOWER & RF233_TX_PWR_MASK)); // no longer auto crc which has moved to RF233_TRX_CTRL_1 register

		txPower = RF233_DEF_RFPOWER & RF233_TX_PWR_MASK;
		channel = RF233_DEF_CHANNEL & RF233_CHANNEL_MASK;
		writeRegister(RF233_PHY_CC_CCA, RF233_CCA_MODE_VALUE | channel);

		readRegister(RF233_IRQ_STATUS); // clear the interrupt register

		call SLP_TR.set();
		state = STATE_SLEEP;



	}

/*----------------- SPI -----------------*/

	event void SpiResource.granted()
	{
		call SELN.makeOutput();
		call SELN.set();

		if( state == STATE_P_ON )
		{
			initRadio();
			call SpiResource.release();
		}
		else
			call Tasklet.schedule();
	}

	bool isSpiAcquired()
	{
		if( call SpiResource.isOwner() )
			return TRUE;

		if( call SpiResource.immediateRequest() == SUCCESS )
		{
			call SELN.makeOutput();
			call SELN.set();

			return TRUE;
		}

		call SpiResource.request();
		return FALSE;
	}

/*----------------- CHANNEL -----------------*/

	tasklet_async command uint8_t RadioState.getChannel()
	{
		return channel;
	}

	tasklet_async command error_t RadioState.setChannel(uint8_t c)
	{
		c &= RF233_CHANNEL_MASK;

		if( cmd != CMD_NONE )
			return EBUSY;
		else if( channel == c )
			return EALREADY;

		channel = c;
		cmd = CMD_CHANNEL;
		call Tasklet.schedule();

		return SUCCESS;
	}

	inline void changeChannel()
	{
		RADIO_ASSERT( cmd == CMD_CHANNEL );
		RADIO_ASSERT( state == STATE_SLEEP || state == STATE_TRX_OFF || state == STATE_RX_ON );

		if( isSpiAcquired() )
		{
			writeRegister(RF233_PHY_CC_CCA, RF233_CCA_MODE_VALUE | channel);

			if( state == STATE_RX_ON )
				state = STATE_TRX_OFF_2_RX_ON;
			else
				cmd = CMD_SIGNAL_DONE;
		}
	}

/*----------------- TURN ON/OFF -----------------*/

	inline void changeState()
	{

		if( (cmd == CMD_STANDBY || cmd == CMD_TURNON)
			&& state == STATE_SLEEP && call RadioAlarm.isFree() )
		{
			call SLP_TR.clr();

			call RadioAlarm.wait(SLEEP_WAKEUP_TIME);

			// now using the irq
			state = STATE_SLEEP_2_TRX_OFF;



		}
		else if( cmd == CMD_TURNON && state == STATE_TRX_OFF && isSpiAcquired() )
		{
			RADIO_ASSERT( ! radioIrq );
			readRegister(RF233_IRQ_STATUS); // clear the interrupt register
			writeRegister(RF233_IRQ_MASK, RF233_IRQ_6_TRX_UR | RF233_IRQ_0_PLL_LOCK | RF233_IRQ_3_TRX_END | RF233_IRQ_2_RX_START);
			call IRQ.captureRisingEdge();

			// setChannel was ignored in SLEEP because the SPI was not working, so do it here
			writeRegister(RF233_PHY_CC_CCA, RF233_CCA_MODE_VALUE | channel);

			writeRegister(RF233_TRX_STATE, RF233_RX_ON);
			state = STATE_TRX_OFF_2_RX_ON;

#ifdef RADIO_DEBUG_PARTNUM
			if( call DiagMsg.record() )
			{
				call DiagMsg.str("partnum");
				call DiagMsg.hex8(readRegister(RF233_PART_NUM));
				call DiagMsg.hex8(readRegister(RF233_VERSION_NUM));
				call DiagMsg.hex8(readRegister(RF233_MAN_ID_0));
				call DiagMsg.hex8(readRegister(RF233_MAN_ID_1));
				call DiagMsg.send();
			}
#endif
		}
		else if( (cmd == CMD_TURNOFF || cmd == CMD_STANDBY) 
			&& state == STATE_RX_ON && isSpiAcquired() )
		{
			writeRegister(RF233_IRQ_MASK, 0); // disable all interrupts
			readRegister(RF233_IRQ_STATUS) ; // clear the interrupt flag register

			writeRegister(RF233_TRX_STATE, RF233_FORCE_TRX_OFF);

			call IRQ.disable();
			radioIrq = FALSE;

			state = STATE_TRX_OFF;
		}

		if( cmd == CMD_TURNOFF && state == STATE_TRX_OFF )
		{
			call SLP_TR.set();
			state = STATE_SLEEP;
			cmd = CMD_SIGNAL_DONE;
		}
		else if( cmd == CMD_STANDBY && state == STATE_TRX_OFF )
			cmd = CMD_SIGNAL_DONE;
	}

	tasklet_async command error_t RadioState.turnOff()
	{
		if( cmd != CMD_NONE )
			return EBUSY;
		else if( state == STATE_SLEEP )
			return EALREADY;

		cmd = CMD_TURNOFF;
		call Tasklet.schedule();

		return SUCCESS;
	}
	
	tasklet_async command error_t RadioState.standby()
	{
		if( cmd != CMD_NONE || (state == STATE_SLEEP && ! call RadioAlarm.isFree()) )
			return EBUSY;
		else if( state == STATE_TRX_OFF )
			return EALREADY;

		cmd = CMD_STANDBY;
		call Tasklet.schedule();

		return SUCCESS;
	}

	tasklet_async command error_t RadioState.turnOn()
	{
		if( cmd != CMD_NONE || (state == STATE_SLEEP && ! call RadioAlarm.isFree()) )
			return EBUSY;
		else if( state == STATE_RX_ON )
			return EALREADY;

		cmd = CMD_TURNON;
		call Tasklet.schedule();

		return SUCCESS;
	}

	default tasklet_async event void RadioState.done() { }

/*----------------- TRANSMIT -----------------*/

	tasklet_async command error_t RadioSend.send(message_t* msg)
	{
		uint16_t time;
		uint8_t length;
		uint8_t* data;
		uint8_t header;
		uint32_t time32;
		void* timesync;

//		if( call DiagMsg.record() )
//		{
//			call DiagMsg.str("send");
//			call DiagMsg.send();
//		}
		if( cmd != CMD_NONE || state != STATE_RX_ON || ! isSpiAcquired() || radioIrq )
			return EBUSY;

		length = (call PacketTransmitPower.isSet(msg) ?
			call PacketTransmitPower.get(msg) : RF233_DEF_RFPOWER) & RF233_TX_PWR_MASK;

		if( length != txPower )
		{
			txPower = length;
			writeRegister(RF233_PHY_TX_PWR, RF233_TX_AUTO_CRC_ON | txPower);
		}

		if( call Config.requiresRssiCca(msg) 
				&& (readRegister(RF233_PHY_RSSI) & RF233_RSSI_MASK) > ((rssiClear + rssiBusy) >> 3) )
			return EBUSY;

//		if( call DiagMsg.record() )
//		{
//			call DiagMsg.str("send.PllOn");
//			call DiagMsg.send();
//		}

		writeRegister(RF233_TRX_STATE, RF233_PLL_ON);

		// do something useful, just to wait a little
		time32 = call LocalTime.get();
		timesync = call PacketTimeSyncOffset.isSet(msg) ? ((void*)msg) + call PacketTimeSyncOffset.get(msg) : 0;

		// we have missed an incoming message in this short amount of time
		if( (readRegister(RF233_TRX_STATUS) & RF233_TRX_STATUS_MASK) != RF233_PLL_ON )
		{
			RADIO_ASSERT( (readRegister(RF233_TRX_STATUS) & RF233_TRX_STATUS_MASK) == RF233_BUSY_RX );

			writeRegister(RF233_TRX_STATE, RF233_RX_ON);
			return EBUSY;
		}

#ifndef RF233_SLOW_SPI
		atomic
		{
			call SLP_TR.set();
			time = call RadioAlarm.getNow();
		}
		call SLP_TR.clr();
#endif

		RADIO_ASSERT( ! radioIrq );

		call SELN.clr();
		call FastSpiByte.splitWrite(RF233_CMD_FRAME_WRITE);

		data = getPayload(msg);
		length = getHeader(msg)->length;

		// length | data[0] ... data[length-3] | automatically generated FCS
		call FastSpiByte.splitReadWrite(length);

		// the FCS is atomatically generated (2 bytes)
		length -= 2;

		header = call Config.headerPreloadLength();
		if( header > length )
			header = length;

		length -= header;

		// first upload the header to gain some time
		do {
			call FastSpiByte.splitReadWrite(*(data++));
		}
		while( --header != 0 );

#ifdef RF233_SLOW_SPI
		atomic
		{
			call SLP_TR.set();
			time = call RadioAlarm.getNow();
		}
		call SLP_TR.clr();
#endif

		time32 += (int16_t)(time + TX_SFD_DELAY) - (int16_t)(time32);

		if( timesync != 0 )
			*(timesync_relative_t*)timesync = (*(timesync_absolute_t*)timesync) - time32;

		while( length-- != 0 )
			call FastSpiByte.splitReadWrite(*(data++));


		// wait for the SPI transfer to finish
		call FastSpiByte.splitRead();
		call SELN.set();


		/*
		 * There is a very small window (~1 microsecond) when the RF233 went
		 * into PLL_ON state but was somehow not properly initialized because 
		 * of an incoming message and could not go into BUSY_TX. I think the
		 * radio can even receive a message, and generate a TRX_UR interrupt
		 * because of concurrent access, but that message probably cannot be
		 * recovered.
		 *
		 * TODO: this needs to be verified, and make sure that the chip is 
		 * not locked up in this case.
		 */

		// go back to RX_ON state when finished
		writeRegister(RF233_TRX_STATE, RF233_RX_ON);
//		if( call DiagMsg.record() )
//		{
//			call DiagMsg.str("send.waitfinish");
//			call DiagMsg.send();
//		}


		
		if( timesync != 0 )
			*(timesync_absolute_t*)timesync = (*(timesync_relative_t*)timesync) + time32;

		call PacketTimeStamp.set(msg, time32);
//		PORT->Group[0].OUTCLR.reg = 1U<<19 ;


#ifdef RADIO_DEBUG_MESSAGES
		if( call DiagMsg.record() )
		{
			length = getHeader(msg)->length;

			call DiagMsg.chr('t');
			call DiagMsg.uint32(call PacketTimeStamp.isValid(rxMsg) ? call PacketTimeStamp.timestamp(rxMsg) : 0);
			call DiagMsg.uint16(call RadioAlarm.getNow());
			call DiagMsg.int8(length);
			call DiagMsg.hex8s(getPayload(msg), length - 2);
			call DiagMsg.send();
		}
#endif

		// wait for the TRX_END interrupt
		state = STATE_BUSY_TX_2_RX_ON;
		cmd = CMD_TRANSMIT;



		return SUCCESS;
	}

	default tasklet_async event void RadioSend.sendDone(error_t error) { }
	default tasklet_async event void RadioSend.ready() { }

/*----------------- CCA -----------------*/

	tasklet_async command error_t RadioCCA.request()
	{
		if( cmd != CMD_NONE || state != STATE_RX_ON || ! isSpiAcquired() || ! call RadioAlarm.isFree() )
			return EBUSY;

		// see Errata B7 of the datasheet
		// writeRegister(RF233_TRX_STATE, RF233_PLL_ON);
		// writeRegister(RF233_TRX_STATE, RF233_RX_ON);

		writeRegister(RF233_PHY_CC_CCA, RF233_CCA_REQUEST | RF233_CCA_MODE_VALUE | channel);
		call RadioAlarm.wait(CCA_REQUEST_TIME);
		cmd = CMD_CCA;
		
		return SUCCESS;
	}

	default tasklet_async event void RadioCCA.done(error_t error) { }

/*----------------- RECEIVE -----------------*/

	inline void downloadMessage()
	{
		uint8_t length;
		uint8_t crc;

		call SELN.clr();
		call FastSpiByte.write(RF233_CMD_FRAME_READ);

		// read the length byte
		length = call FastSpiByte.write(0);

		// if correct length
		if( length >= 3 && length <= call RadioPacket.maxPayloadLength() + 2 )
		{
			uint8_t read;
			uint8_t* data;

			// initiate the reading
			call FastSpiByte.splitWrite(0);

			data = getPayload(rxMsg);
			getHeader(rxMsg)->length = length;
			crc = 1;

			// we do not store the CRC field
			length -= 2;

			read = call Config.headerPreloadLength();
			if( length < read )
				read = length;

			length -= read;

			do {
				*(data++) = call FastSpiByte.splitReadWrite(0);
			}
			while( --read != 0  );

			if( signal RadioReceive.header(rxMsg) )
			{
				while( length-- != 0 )
					*(data++) = call FastSpiByte.splitReadWrite(0);

				call FastSpiByte.splitReadWrite(0);
				call FastSpiByte.splitReadWrite(0);

				call PacketLinkQuality.set(rxMsg, call FastSpiByte.splitReadWrite(0)); // LQI
				call FastSpiByte.splitReadWrite(0) ; // ED
				if(call FastSpiByte.splitRead() & (1<<7)) crc = 0; // RX_STATUS -> RX_CRC_VALID bit
			}
			else
			{
				call FastSpiByte.splitRead(); // finish the SPI transfer
				crc = 1;
			}
		}
		else
			crc = 1;

		call SELN.set();
		state = STATE_RX_ON;

#ifdef RADIO_DEBUG_MESSAGES
		if( call DiagMsg.record() )
		{
			length = getHeader(rxMsg)->length;

			call DiagMsg.chr('r');
			call DiagMsg.uint32(call PacketTimeStamp.isValid(rxMsg) ? call PacketTimeStamp.timestamp(rxMsg) : 0);
			call DiagMsg.uint16(call RadioAlarm.getNow());
			call DiagMsg.int8(crc == 0 ? length : -length);
			call DiagMsg.hex8s(getPayload(rxMsg), length - 2);
			call DiagMsg.int8(call PacketRSSI.isSet(rxMsg) ? call PacketRSSI.get(rxMsg) : -1);
			call DiagMsg.uint8(call PacketLinkQuality.isSet(rxMsg) ? call PacketLinkQuality.get(rxMsg) : 0);
			call DiagMsg.send();
		}
#endif
		
		cmd = CMD_NONE;

		// signal only if it has passed the CRC check
		if( crc == 0 )
			rxMsg = signal RadioReceive.receive(rxMsg);
	}

/*----------------- IRQ -----------------*/

	async event void IRQ.captured(uint16_t time)
	{

		RADIO_ASSERT( ! radioIrq );

		atomic
		{
			capturedTime = time;
			radioIrq = TRUE;
		}

		call Tasklet.schedule();
	}

	void serviceRadio()
	{
		if( isSpiAcquired() )
		{
			uint16_t time;
			uint32_t time32;
			uint8_t irq;
			uint8_t temp;
			
			atomic time = capturedTime;
			radioIrq = FALSE;
			irq = readRegister(RF233_IRQ_STATUS);

			// if( call DiagMsg.record() )
			// {
			// 	call DiagMsg.str("irq");
			// 	call DiagMsg.hex8(irq) ;
			// 	call DiagMsg.send();
			// }

#ifdef RADIO_DEBUG
			// TODO: handle this interrupt
			if( irq & RF233_IRQ_6_TRX_UR )
			{
				if( call DiagMsg.record() )
				{
					call DiagMsg.str("assert ur");
					call DiagMsg.uint16(call RadioAlarm.getNow());
					call DiagMsg.hex8(readRegister(RF233_TRX_STATUS));
					call DiagMsg.hex8(readRegister(RF233_TRX_STATE));
					call DiagMsg.hex8(irq);
					call DiagMsg.uint8(state);
					call DiagMsg.uint8(cmd);
					call DiagMsg.send();
				}
			}
#endif

#ifdef RF233_RSSI_ENERGY
			if( irq & RF233_IRQ_3_TRX_END )
			{
				if( irq == RF233_IRQ_3_TRX_END ||
					(irq == (RF233_IRQ_2_RX_START | RF233_IRQ_3_TRX_END) && cmd == CMD_NONE) )
					call PacketRSSI.set(rxMsg, readRegister(RF233_PHY_ED_LEVEL));
				else
					call PacketRSSI.clear(rxMsg);
			}
#endif

			// sometimes we miss a PLL lock interrupt after turn on
			if( cmd == CMD_TURNON || cmd == CMD_CHANNEL )
			{

				RADIO_ASSERT( irq & RF233_IRQ_0_PLL_LOCK );
				RADIO_ASSERT( state == STATE_TRX_OFF_2_RX_ON );
//				if( call DiagMsg.record() )
//				{
//					call DiagMsg.str("turnedOn");
//					call DiagMsg.hex8(readRegister(RF233_TRX_STATUS)) ;
//					call DiagMsg.send();
//				}
				state = STATE_RX_ON;
				cmd = CMD_SIGNAL_DONE;
			}
			else if( irq & RF233_IRQ_0_PLL_LOCK )
			{
				RADIO_ASSERT( cmd == CMD_TRANSMIT );
				RADIO_ASSERT( state == STATE_BUSY_TX_2_RX_ON );
//				if( call DiagMsg.record() )
//				{
//					call DiagMsg.str("tx2rxon");
//					call DiagMsg.send();
//				}
			}

			if( irq & RF233_IRQ_2_RX_START )
			{
//				if( call DiagMsg.record() )
//				{
//					call DiagMsg.str("rxStart");
//					call DiagMsg.send();
//				}
				if( cmd == CMD_CCA )
				{
					signal RadioCCA.done(FAIL);
					cmd = CMD_NONE;
				}
				
				if( cmd == CMD_NONE)
				{
					RADIO_ASSERT( state == STATE_RX_ON );

					// the most likely place for busy channel, with no TRX_END interrupt
					if( irq == RF233_IRQ_2_RX_START )
					{
						temp = readRegister(RF233_PHY_RSSI) & RF233_RSSI_MASK;
						rssiBusy += temp - (rssiBusy >> 2);
#ifndef RF233_RSSI_ENERGY
						call PacketRSSI.set(rxMsg, temp);
					}
					else
					{
						call PacketRSSI.clear(rxMsg);
#endif
					}

					/*
					 * The timestamp corresponds to the first event which could not
					 * have been a PLL_LOCK because then cmd != CMD_NONE, so we must
					 * have received a message (and could also have received the
					 * TRX_END interrupt in the mean time, but that is fine. Also,
					 * we could not be after a transmission, because then cmd =
					 * CMD_TRANSMIT.
					 */
					if( irq == RF233_IRQ_2_RX_START ) // just to be cautious
					{
						time32 = call LocalTime.get(); 
						time32 += (int16_t)(time - RX_SFD_DELAY) - (int16_t)(time32);
						call PacketTimeStamp.set(rxMsg, time32);
					}
					else
						call PacketTimeStamp.clear(rxMsg);
					
					cmd = CMD_RECEIVE;
				}
				else{
					if(irq & RF233_IRQ_3_TRX_END){ // possible radio start and trx end together?
						RADIO_ASSERT( cmd == CMD_TURNOFF );
					}
					else{ // Coult receive RX_START while I'm still signalig that I'm On. ndUgo
						RADIO_ASSERT( cmd == CMD_TURNOFF );
					}
				}	
				
			}

			
/////////////////////////////////////////////////////////////////////////////////////
// TODO: check how to handle the fact that I can have start and end at the same irq
			if( irq & RF233_IRQ_3_TRX_END )
			{
//				if( call DiagMsg.record() )
//				{
//					call DiagMsg.str("txend");
//					call DiagMsg.send();
//				}
				if( cmd == CMD_TRANSMIT )
				{
					RADIO_ASSERT( state == STATE_BUSY_TX_2_RX_ON );
//					if( call DiagMsg.record() )
//					{
//						call DiagMsg.str("success");
//						call DiagMsg.send();
//					}
					state = STATE_RX_ON;
					cmd = CMD_NONE;
					signal RadioSend.sendDone(SUCCESS);

					// TODO: we could have missed a received message
					RADIO_ASSERT( ! (irq & RF233_IRQ_2_RX_START) );
				}
				else if( cmd == CMD_RECEIVE )
				{
					RADIO_ASSERT( state == STATE_RX_ON );
					// the most likely place for clear channel (hope to avoid acks)
					rssiClear += (readRegister(RF233_PHY_RSSI) & RF233_RSSI_MASK) - (rssiClear >> 2);

					cmd = CMD_DOWNLOAD;
				}
				else // TODO: could miss an RX_START. ndUgo
					RADIO_ASSERT(FALSE);
			}


		}
	}

	default tasklet_async event bool RadioReceive.header(message_t* msg)
	{
		return TRUE;
	}

	default tasklet_async event message_t* RadioReceive.receive(message_t* msg)
	{
		return msg;
	}

/*----------------- TASKLET -----------------*/

	task void releaseSpi()
	{
		call SpiResource.release();
	}

	tasklet_async event void Tasklet.run()
	{
		if( radioIrq )
			serviceRadio();
		if( cmd != CMD_NONE )
		{
			if( cmd == CMD_DOWNLOAD )
				downloadMessage();
			else if( CMD_TURNOFF <= cmd && cmd <= CMD_TURNON )
				changeState();
			else if( cmd == CMD_CHANNEL )
				changeChannel();
			
			if( cmd == CMD_SIGNAL_DONE )
			{
				cmd = CMD_NONE;
				signal RadioState.done();
			}
		}

		if( cmd == CMD_NONE && state == STATE_RX_ON && ! radioIrq ){
			signal RadioSend.ready();
		}

		if( cmd == CMD_NONE )
			post releaseSpi();
	}

/*----------------- RadioPacket -----------------*/
	
	async command uint8_t RadioPacket.headerLength(message_t* msg)
	{
		return call Config.headerLength(msg) + sizeof(rf233_header_t);
	}

	async command uint8_t RadioPacket.payloadLength(message_t* msg)
	{
		return getHeader(msg)->length - 2;
	}

	async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length)
	{
		RADIO_ASSERT( 1 <= length && length <= 125 );
		RADIO_ASSERT( call RadioPacket.headerLength(msg) + length + call RadioPacket.metadataLength(msg) <= sizeof(message_t) );

		// we add the length of the CRC, which is automatically generated
		getHeader(msg)->length = length + 2;
	}

	async command uint8_t RadioPacket.maxPayloadLength()
	{
		RADIO_ASSERT( call Config.maxPayloadLength() - sizeof(rf233_header_t) <= 125 );

		return call Config.maxPayloadLength() - sizeof(rf233_header_t);
	}

	async command uint8_t RadioPacket.metadataLength(message_t* msg)
	{
		return call Config.metadataLength(msg) + sizeof(rf233_metadata_t);
	}

	async command void RadioPacket.clear(message_t* msg)
	{
		// all flags are automatically cleared
	}

/*----------------- PacketTransmitPower -----------------*/

	async command bool PacketTransmitPower.isSet(message_t* msg)
	{
		return call TransmitPowerFlag.get(msg);
	}

	async command uint8_t PacketTransmitPower.get(message_t* msg)
	{
		return getMeta(msg)->power;
	}

	async command void PacketTransmitPower.clear(message_t* msg)
	{
		call TransmitPowerFlag.clear(msg);
	}

	async command void PacketTransmitPower.set(message_t* msg, uint8_t value)
	{
		call TransmitPowerFlag.set(msg);
		getMeta(msg)->power = value;
	}

/*----------------- PacketRSSI -----------------*/

	async command bool PacketRSSI.isSet(message_t* msg)
	{
		return call RSSIFlag.get(msg);
	}

	async command uint8_t PacketRSSI.get(message_t* msg)
	{
		return getMeta(msg)->rssi;
	}

	async command void PacketRSSI.clear(message_t* msg)
	{
		call RSSIFlag.clear(msg);
	}

	async command void PacketRSSI.set(message_t* msg, uint8_t value)
	{
		// just to be safe if the user fails to clear the packet
		call TransmitPowerFlag.clear(msg);

		call RSSIFlag.set(msg);
		getMeta(msg)->rssi = value;
	}

/*----------------- PacketTimeSyncOffset -----------------*/

	async command bool PacketTimeSyncOffset.isSet(message_t* msg)
	{
		return call TimeSyncFlag.get(msg);
	}

	async command uint8_t PacketTimeSyncOffset.get(message_t* msg)
	{
		return call RadioPacket.headerLength(msg) + call RadioPacket.payloadLength(msg) - sizeof(timesync_absolute_t);
	}

	async command void PacketTimeSyncOffset.clear(message_t* msg)
	{
		call TimeSyncFlag.clear(msg);
	}

	async command void PacketTimeSyncOffset.set(message_t* msg, uint8_t value)
	{
		// we do not store the value, the time sync field is always the last 4 bytes
		RADIO_ASSERT( call PacketTimeSyncOffset.get(msg) == value );

		call TimeSyncFlag.set(msg);
	}

/*----------------- PacketLinkQuality -----------------*/

	async command bool PacketLinkQuality.isSet(message_t* msg)
	{
		return TRUE;
	}

	async command uint8_t PacketLinkQuality.get(message_t* msg)
	{
		return getMeta(msg)->lqi;
	}

	async command void PacketLinkQuality.clear(message_t* msg)
	{
	}

	async command void PacketLinkQuality.set(message_t* msg, uint8_t value)
	{
		getMeta(msg)->lqi = value;
	}

/*----------------- LinkPacketMetadata -----------------*/

	async command bool LinkPacketMetadata.highChannelQuality(message_t* msg)
	{
		return call PacketLinkQuality.get(msg) > 200;
	}
}
