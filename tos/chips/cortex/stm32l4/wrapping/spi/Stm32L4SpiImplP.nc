/*
 * AsfUsartWrapperP.nc
 *
 *  Created on: Jul 17, 2015
 *      Author: obren
 */
#include "conf_spi.h"
#include "stm32l4xx_ll_spi.h"
generic module Stm32L4SpiImplP(uint32_t spi_port){
	provides interface SpiConfig[uint8_t];
	provides interface SpiByte ;
	provides interface SpiPacket[uint8_t] ;
	provides interface FastSpiByte ;
	provides interface Resource[uint8_t] ;
	provides interface ResourceConfigure[uint8_t] ;
	provides interface McuPowerOverride;
	
	uses interface McuPowerState;
	uses interface Resource as SubResource[uint8_t];
	uses interface SpiInterrupt ;

}
implementation{
	#define SPI_PORT ((SPI_TypeDef *) spi_port)
	enum {
    	NO_CLIENT = 0xff,
    	SPI_ATOMIC_SIZE = 10,
  	};


  
  	uint8_t currentClient = NO_CLIENT;

	
	uint16_t len;
	uint8_t* COUNT_NOK(len) txBuffer;
	uint8_t* COUNT_NOK(len) rxBuffer;
	uint16_t pos;

	error_t sendNextPart() {
		uint16_t end;
		uint16_t tmpPos;
		uint16_t myLen;
		uint8_t* COUNT_NOK(myLen) tx;
		uint8_t* COUNT_NOK(myLen) rx;

		atomic {
			myLen = len;
			tx = txBuffer;
			rx = rxBuffer;
			tmpPos = pos;
			end = pos + SPI_ATOMIC_SIZE;
			end = (end > len)? len:end;
		}

		for (;tmpPos < (end - 1) ; tmpPos++) {
			uint8_t val;
			if (tx != NULL)
				val = call SpiByte.write( tx[tmpPos] );
			else
				val = call SpiByte.write( 0 );

			if (rx != NULL) {
				rx[tmpPos] = val;
			}
		}
		// For the last byte, we re-enable interrupts.

		//call Spi.enableInterrupt(TRUE);
		LL_SPI_EnableIT_RXNE(SPI_PORT);
		atomic {
			if (tx != NULL)
				LL_SPI_TransmitData8(SPI_PORT,tx[tmpPos]); //call Spi.write(tx[tmpPos]);
			else
				LL_SPI_TransmitData8(SPI_PORT,0); //call Spi.write(0);

			pos = tmpPos;
			// The final increment will be in the interrupt
			// handler.
		}
		return SUCCESS;
	}

	task void zeroTask() {
		uint16_t  myLen;
		uint8_t* COUNT_NOK(myLen) rx;
		uint8_t* COUNT_NOK(myLen) tx;

		atomic {
			myLen = len;
			rx = rxBuffer;
			tx = txBuffer;
			rxBuffer = NULL;
			txBuffer = NULL;
			len = 0;
			pos = 0;
			signal SpiPacket.sendDone[currentClient](tx, rx, myLen, SUCCESS);
		}
	}

	void spi_setConfig(const spi_tos_config_t* cfg){
		  /* Configure SPI communication */
		  LL_SPI_SetBaudRatePrescaler(SPI_PORT, cfg->main_clock_div);
		  LL_SPI_SetTransferDirection(SPI_PORT,LL_SPI_FULL_DUPLEX);
		  LL_SPI_SetClockPhase(SPI_PORT, cfg->clock_phase);
		  LL_SPI_SetClockPolarity(SPI_PORT, cfg->clock_polarity);
		  LL_SPI_SetTransferBitOrder(SPI_PORT, LL_SPI_MSB_FIRST);
		  LL_SPI_SetDataWidth(SPI_PORT, LL_SPI_DATAWIDTH_8BIT);
		  LL_SPI_SetNSSMode(SPI_PORT, LL_SPI_NSS_SOFT);
		  LL_SPI_SetRxFIFOThreshold(SPI_PORT, LL_SPI_RX_FIFO_TH_QUARTER);
		  LL_SPI_SetMode(SPI_PORT, LL_SPI_MODE_MASTER);
	}

	void spi_start(){
		LL_SPI_Enable(SPI_PORT);
		call McuPowerState.update();

	}

	void spi_stop(){
		LL_SPI_Disable(SPI_PORT);
		call McuPowerState.update();
	}


	/**
	* Synchronous transmit and receive (can be in interrupt context)
	* @param tx Byte to transmit
	* @param rx Received byte is stored here.
	*/
	async command uint8_t SpiByte.write( uint8_t tx ){
		uint8_t rx_data ;
		while(!LL_SPI_IsActiveFlag_TXE(SPI_PORT)){}
		LL_SPI_TransmitData8(SPI_PORT,tx);
		while(!LL_SPI_IsActiveFlag_RXNE(SPI_PORT)){}
		rx_data = LL_SPI_ReceiveData8(SPI_PORT);
		return rx_data ;
	}

	  /**
	     * Send a message over the SPI bus.
	     *
	     * //@param 'uint8_t* COUNT_NOK(len) txBuf' A pointer to the buffer to send over the bus. If this
	     *              parameter is NULL, then the SPI will send zeroes.
	     * //@param 'uint8_t* COUNT_NOK(len) rxBuf' A pointer to the buffer where received data should
	     *              be stored. If this parameter is NULL, then the SPI will
	     *              discard incoming bytes.
	     * @param len   Length of the message.  Note that non-NULL rxBuf and txBuf
	     *              parameters must be AT LEAST as large as len, or the SPI
	     *              will overflow a buffer.
	     *
	     * @return SUCCESS if the request was accepted for transfer
	     */
	    async command error_t SpiPacket.send[uint8_t id]( uint8_t* writeBuf, uint8_t* readBuf, uint16_t bufLen ){
	    	uint8_t discard;
		    atomic {
				if (currentClient != id) return FAIL;
		      len = bufLen;
		      txBuffer = writeBuf;
		      rxBuffer = readBuf;
		      pos = 0;
		    }
		    if (bufLen > 0) {
		      discard = LL_SPI_ReceiveData8(SPI_PORT);//call Spi.read();
		      return sendNextPart();
		    }
		    else {
		      post zeroTask();
		      return SUCCESS;
		    }
	    }

	inline async command void FastSpiByte.splitWrite(uint8_t data) {
		while(!LL_SPI_IsActiveFlag_TXE(SPI_PORT)){}
		LL_SPI_TransmitData8(SPI_PORT,data);
	}

	inline async command uint8_t FastSpiByte.splitRead() {
		uint8_t rx_data ; 
		while(!LL_SPI_IsActiveFlag_RXNE(SPI_PORT)){}
		rx_data = LL_SPI_ReceiveData8(SPI_PORT);
		return rx_data ;
	}

	inline async command uint8_t FastSpiByte.splitReadWrite(uint8_t data) {
		uint8_t rx_data ; 
		while(!LL_SPI_IsActiveFlag_RXNE(SPI_PORT)){}
		rx_data = LL_SPI_ReceiveData8(SPI_PORT);
		while(!LL_SPI_IsActiveFlag_TXE(SPI_PORT)){}
		LL_SPI_TransmitData8(SPI_PORT,data);
		return rx_data ;
	}

	inline async command uint8_t FastSpiByte.write(uint8_t data) {
		uint8_t rx_data ;
		while(!LL_SPI_IsActiveFlag_TXE(SPI_PORT)){}
		LL_SPI_TransmitData8(SPI_PORT,data);
		while(!LL_SPI_IsActiveFlag_RXNE(SPI_PORT)){}
		rx_data = LL_SPI_ReceiveData8(SPI_PORT);
		return rx_data ;
	}




	async event void SpiInterrupt.transceiveComplete(){
		//signal SpiPacket.sendDone[currentClient]( tx_bfr_ptr, rx_bfr_ptr, tx_length, SUCCESS );
	}

	async event void SpiInterrupt.receiveComplete(){
		bool again;
		uint8_t data = LL_SPI_ReceiveData8(SPI_PORT);


		atomic {
			if (rxBuffer != NULL) {
				rxBuffer[pos] = data;
				// Increment position
			}
			pos++;
		}
		LL_SPI_DisableIT_RXNE(SPI_PORT);

		atomic {
			again = (pos < len);
		}

		if (again) {
			sendNextPart();
		}
		else {
			uint8_t discard;
			uint16_t  myLen;
			uint8_t* COUNT_NOK(myLen) rx;
			uint8_t* COUNT_NOK(myLen) tx;

			atomic {
				myLen = len;
				rx = rxBuffer;
				tx = txBuffer;
				rxBuffer = NULL;
				txBuffer = NULL;
				len = 0;
				pos = 0;
			}
			discard = LL_SPI_ReceiveData8(SPI_PORT); //call Spi.read();

			signal SpiPacket.sendDone[currentClient](tx, rx, myLen, SUCCESS);
		}
	}

	async event void SpiInterrupt.transmitComplete(){
		
		//signal SpiPacket.sendDone[currentClient]( tx_bfr_ptr, rx_bfr_ptr, tx_length, SUCCESS );
	}

	async event void SpiInterrupt.error(){
		//signal SpiPacket.sendDone[currentClient]( tx_bfr_ptr, rx_bfr_ptr, tx_length, FAIL );
	}

	 async command void ResourceConfigure.configure[ uint8_t id ]() {
	 	atomic{
	 		spi_setConfig(signal SpiConfig.getConfig[id]()) ;
		   	spi_start();
	   	}
	 }

	 async command void ResourceConfigure.unconfigure[ uint8_t id ]() {
	    atomic spi_stop();
	 }


	async command error_t Resource.request[uint8_t id]() {
		return call SubResource.request[id]();
	}

	async command error_t Resource.immediateRequest[uint8_t id]() {
		error_t rval = call SubResource.immediateRequest[id]();
		if (rval == SUCCESS) {
		  atomic currentClient = id;
		}
		return rval;
	}

	event void SubResource.granted[uint8_t id]() {
		atomic currentClient = id;
		signal Resource.granted[id]();
	}

	async command error_t Resource.release[uint8_t id]() {
		return call SubResource.release[id]();
	}

	async command bool Resource.isOwner[uint8_t id]() {
		return call SubResource.isOwner[id]();
	}



	async command mcu_power_t McuPowerOverride.lowestState()
	{
		if(LL_SPI_IsEnabled(SPI_PORT)){
			return STM32L4_SLEEP;
		}
		else return STM32L4_STOP2;
	}


	default async event void SpiPacket.sendDone[uint8_t id]( uint8_t* txBuf, uint8_t* rxBuf, uint16_t plen, error_t error){}


	default async event const spi_tos_config_t* SpiConfig.getConfig[uint8_t id](){
	  return &spi_tos_config_default;
	}

	default event void Resource.granted[uint8_t id]() {}

}

