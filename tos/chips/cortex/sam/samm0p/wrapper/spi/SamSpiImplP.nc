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
 * Wrapper for SPI module implementation. The SPI is unconfigured and 
 * reconfigured at each resource request.
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */
 
#include "spi_interrupt.h"
#include "spi.h"
generic module SamSpiImplP(uint32_t sercom_port, uint8_t gen){
	provides interface SpiConfig[uint8_t];
	provides interface SpiByte ;
	provides interface SpiPacket[uint8_t] ;
	provides interface FastSpiByte ;
	provides interface Resource[uint8_t] ;
	provides interface ResourceConfigure[uint8_t] ;

	uses interface Resource as SubResource[uint8_t];

}
implementation{
	enum {
    	NO_CLIENT = 0xff
  	};
  
  	uint8_t currentClient = NO_CLIENT;

	struct spi_module device_instance;
	struct spi_slave_inst slave;
	uint8_t* tx_bfr_ptr = NULL ;
	uint8_t* rx_bfr_ptr = NULL ;
	uint16_t tx_length = 0;

	void callback_buffer_transceived( struct spi_module *const asf_module);
	void callback_buffer_received( struct spi_module *const asf_module);
	void callback_buffer_transmitted( struct spi_module *const asf_module);
	void callback_error( struct spi_module *const asf_module);


	void spi_setConfig(const spi_tos_config_t* cfg){
		// spi init

		struct spi_config config_spi_master;

		/* Configure, initialize and enable SERCOM SPI module */
		spi_get_config_defaults(&config_spi_master);

		// set the clock generator
		config_spi_master.generator_source = gen ;

		config_spi_master.transfer_mode = cfg->transfer_mode;

		config_spi_master.mode_specific.master.baudrate = cfg->baud;


		config_spi_master.mux_setting = cfg->muxSetting;

		config_spi_master.pinmux_pad0 = cfg->pad0;
		config_spi_master.pinmux_pad1 = cfg->pad1;
		config_spi_master.pinmux_pad2 = cfg->pad2;
		config_spi_master.pinmux_pad3 = cfg->pad3;

		while(spi_init(&device_instance,(Sercom*) sercom_port, &config_spi_master) != STATUS_OK){
			// call MtbControl.stopMicroTraceBuffer();
			// while(true){}
		}
	}

	void spi_start(){
		spi_enable(&device_instance); // TODO: check if use it here or not

		// register callbacks here
		spi_register_callback(&device_instance, callback_buffer_transceived,SPI_CALLBACK_BUFFER_TRANSCEIVED);
		spi_register_callback(&device_instance, callback_buffer_received,SPI_CALLBACK_BUFFER_RECEIVED);
		spi_register_callback(&device_instance, callback_buffer_transmitted,SPI_CALLBACK_BUFFER_TRANSMITTED);
		spi_register_callback(&device_instance, callback_error,SPI_CALLBACK_ERROR);


		spi_enable_callback(&device_instance, SPI_CALLBACK_BUFFER_TRANSCEIVED);
		spi_enable_callback(&device_instance, SPI_CALLBACK_BUFFER_RECEIVED);
		spi_enable_callback(&device_instance, SPI_CALLBACK_BUFFER_TRANSMITTED);
		spi_enable_callback(&device_instance, SPI_CALLBACK_ERROR);
	}

	void spi_stop(){
		spi_disable(&device_instance); // TODO: check if use it here or not

		spi_disable_callback(&device_instance, SPI_CALLBACK_BUFFER_TRANSCEIVED);
		spi_disable_callback(&device_instance, SPI_CALLBACK_BUFFER_RECEIVED);
		spi_disable_callback(&device_instance, SPI_CALLBACK_BUFFER_TRANSMITTED);
		spi_disable_callback(&device_instance, SPI_CALLBACK_ERROR);

		// register callbacks here
		spi_unregister_callback(&device_instance, SPI_CALLBACK_BUFFER_TRANSCEIVED);
		spi_unregister_callback(&device_instance, SPI_CALLBACK_BUFFER_RECEIVED);
		spi_unregister_callback(&device_instance, SPI_CALLBACK_BUFFER_TRANSMITTED);
		spi_unregister_callback(&device_instance, SPI_CALLBACK_ERROR);


	}


	  /**
	   * Synchronous transmit and receive (can be in interrupt context)
	   * @param tx Byte to transmit
	   * @param rx Received byte is stored here.
	   */
	  async command uint8_t SpiByte.write( uint8_t tx ){
		  uint16_t tx_data ;
		  uint16_t value = 0x00;
		  int result ;
		  tx_data = tx ;
		  result  = spi_transceive_wait(&device_instance,tx_data,&value);
		  switch(result){
		  case STATUS_OK:
			  break;
		  case STATUS_ERR_DENIED: case STATUS_ERR_TIMEOUT: case STATUS_ERR_OVERFLOW: case STATUS_ERR_IO:
			  value = 0x00;
			  break;
		  case STATUS_BUSY:
			  value = 0x00;
			  break;
		  default:
			  value = 0x00;
			  break;
		  }
		  return (uint8_t) value ;
	  }

	  /**
	     * Send a message over the SPI bus.
	     *
	     * @param 'uint8_t* COUNT_NOK(len) txBuf' A pointer to the buffer to send over the bus. If this
	     *              parameter is NULL, then the SPI will send zeroes.
	     * @param 'uint8_t* COUNT_NOK(len) rxBuf' A pointer to the buffer where received data should
	     *              be stored. If this parameter is NULL, then the SPI will
	     *              discard incoming bytes.
	     * @param len   Length of the message.  Note that non-NULL rxBuf and txBuf
	     *              parameters must be AT LEAST as large as len, or the SPI
	     *              will overflow a buffer.
	     *
	     * @return SUCCESS if the request was accepted for transfer
	     */
	    async command error_t SpiPacket.send[uint8_t id]( uint8_t* txBuf, uint8_t* rxBuf, uint16_t len ){
	    	int result;
	    	atomic {
			  if (currentClient != id) {
				return FAIL;
		  	  }
		  	}
	    	if(txBuf == NULL) result = spi_read_buffer_job(&device_instance,rxBuf,len,0);
	    	else if(rxBuf == NULL) result = spi_write_buffer_job(&device_instance,txBuf,len);
	    	else result = spi_transceive_buffer_job(&device_instance,txBuf,rxBuf,len);
	    	 switch(result){
			  case STATUS_OK:
				  tx_bfr_ptr = txBuf;
				  rx_bfr_ptr = rxBuf;
				  tx_length = len ;
				  return SUCCESS;
				  break;
			  case STATUS_ERR_DENIED:
				  return FAIL ;
				  break;
			  case STATUS_BUSY:
				  return EBUSY;
				  break;
			  case STATUS_ERR_INVALID_ARG:
				  return EINVAL;
				  break;
			  default:
				  return FAIL ;
				  break;
			  }
	    }

	    inline async command void FastSpiByte.splitWrite(uint8_t data) {
	        spi_write(&device_instance,data);
	    }

	      inline async command uint8_t FastSpiByte.splitRead() {
	        uint16_t result = 0;
	    	  while( ! spi_is_write_complete(&device_instance) )
	          ;
	    	  spi_read(&device_instance,&result);

	        return (uint8_t) result ;
	      }

	      inline async command uint8_t FastSpiByte.splitReadWrite(uint8_t data) {
	        uint16_t result;

	        while( ! spi_is_write_complete(&device_instance) )
	    	;

	        spi_read(&device_instance,&result);
	        spi_write(&device_instance,data);

	        return (uint8_t) result ;
	      }

	      inline async command uint8_t FastSpiByte.write(uint8_t data) {
	    	  uint16_t result;
	    	  spi_write(&device_instance,data);

	        while( ! spi_is_write_complete(&device_instance) )
	          ;

	        spi_read(&device_instance,&result);
	        return (uint8_t) result ;
	      }

	void callback_buffer_transceived( struct spi_module *const asf_module){
		signal SpiPacket.sendDone[currentClient]( tx_bfr_ptr, rx_bfr_ptr, tx_length, SUCCESS );
	}
	void callback_buffer_received( struct spi_module *const asf_module){
		signal SpiPacket.sendDone[currentClient]( tx_bfr_ptr, rx_bfr_ptr, tx_length, SUCCESS );
	}
	void callback_buffer_transmitted( struct spi_module *const asf_module){
		signal SpiPacket.sendDone[currentClient]( tx_bfr_ptr, rx_bfr_ptr, tx_length, SUCCESS );
	}
	void callback_error( struct spi_module *const asf_module){
		signal SpiPacket.sendDone[currentClient]( tx_bfr_ptr, rx_bfr_ptr, tx_length, FAIL );
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

	default async event void SpiPacket.sendDone[uint8_t id]( uint8_t* txBuf, uint8_t* rxBuf, uint16_t len, error_t error){}


	  default async event const spi_tos_config_t* SpiConfig.getConfig[uint8_t id](){
		  return &spi_tos_config_default;
	  }

	  default event void Resource.granted[uint8_t id]() {}


}

