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
 * Wrapper for Usart module implementation.
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */

#include "usart.h"
#include "usart_interrupt.h"
generic module SamUsartP(uint32_t sercom_port, uint8_t gen, uint32_t speed, uint32_t mux, uint32_t pad0, uint32_t pad1, uint32_t pad2, uint32_t pad3 ){
	provides interface UartByte ;
	provides interface UartStream ;
	provides interface StdControl ;
	provides interface Init ;

}
implementation{
	struct usart_module device_instance;
	uint8_t* tx_bfr_ptr = NULL ;
	uint8_t* rx_bfr_ptr = NULL ;
	uint16_t tx_length = 0;
	uint16_t rx_length = 0;

	void bufferTransmitted(struct usart_module *const usart_module);
	void bufferReceived(struct usart_module *const usart_module);

	command error_t Init.init(){
		
			struct usart_config config_usart;
			usart_get_config_defaults(&config_usart);
		
			// set the clock generator
			config_usart.generator_source = gen ;

			// current usart configuration
			config_usart.baudrate    = speed;
			config_usart.mux_setting = mux;
			config_usart.pinmux_pad0 = pad0;
			config_usart.pinmux_pad1 = pad1;
			config_usart.pinmux_pad2 = pad2;
			config_usart.pinmux_pad3 = pad3;
		
			//config_usart.run_in_standby = true;

			while (usart_init(&device_instance,(Sercom*)
					sercom_port, &config_usart) != STATUS_OK) {
			}
		
			return SUCCESS;
	}

	command error_t StdControl.start(){
		usart_enable(&device_instance);
		// register callbacks
		usart_register_callback(&device_instance,bufferTransmitted, USART_CALLBACK_BUFFER_TRANSMITTED);
		usart_register_callback(&device_instance,bufferReceived, USART_CALLBACK_BUFFER_RECEIVED);
		usart_enable_callback(&device_instance,USART_CALLBACK_BUFFER_TRANSMITTED) ;
		usart_enable_callback(&device_instance,USART_CALLBACK_BUFFER_RECEIVED) ;
		return SUCCESS;
	}

	command error_t StdControl.stop(){
		usart_disable_callback(&device_instance,USART_CALLBACK_BUFFER_TRANSMITTED) ;
		usart_disable_callback(&device_instance,USART_CALLBACK_BUFFER_RECEIVED) ;
		// register callbacks
		usart_unregister_callback(&device_instance, USART_CALLBACK_BUFFER_TRANSMITTED);
		usart_unregister_callback(&device_instance, USART_CALLBACK_BUFFER_RECEIVED);
		usart_disable(&device_instance);
		return SUCCESS;
	}

	/**
	   * Send a single uart byte. The call blocks until it is ready to
	   * accept another byte for sending.
	   *
	   * @param byte The byte to send.
	   * @return SUCCESS if byte was sent, FAIL otherwise.
	   */
	  async command error_t UartByte.send( uint8_t byte ){
		  int result = usart_write_wait(&device_instance,byte);
		  switch(result){
		  case STATUS_BUSY:
			  return EBUSY;
			  break;
		  case STATUS_ERR_DENIED:
			  return FAIL ;
			  break;
		  case STATUS_OK:
			  return SUCCESS;
			  break;
		  default:
			  return FAIL ;
			  break;
		  }

	  }

	  /**
	   * Receive a single uart byte. The call blocks until a byte is
	   * received.
	   *
	   * @param 'uint8_t* ONE byte' Where to place received byte.
	   * @param timeout How long in byte times to wait.
	   * @return SUCCESS if a byte was received, FAIL if timed out.
	   */
	  async command error_t UartByte.receive( uint8_t* byte, uint8_t timeout ){
		  uint16_t rxbyte;
		  while(usart_read_wait(&device_instance,&rxbyte) != STATUS_OK){

		  }
		  *byte = (uint8_t) rxbyte;
		  return SUCCESS; // TODO: timeout not implemented yet
	  }


	  /**
	   * Begin transmission of a UART stream. If SUCCESS is returned,
	   * <code>sendDone</code> will be signalled when transmission is
	   * complete.
	   *
	   * @param 'uint8_t* COUNT(len) buf' Buffer for bytes to send.
	   * @param len Number of bytes to send.
	   * @return SUCCESS if request was accepted, FAIL otherwise.
	   */
	  async command error_t UartStream.send( uint8_t* buf, uint16_t len ){
		  int result ;
		  result = usart_write_buffer_job(&device_instance,buf,len) ;
		  switch(result){
			  case STATUS_BUSY:
				  return EBUSY;
				  break;
			  case STATUS_ERR_DENIED:
				  return FAIL ;
				  break;
			  case ERR_INVALID_ARG:
				  return EINVAL;
				  break;
			  case STATUS_OK:
				  tx_bfr_ptr = buf ;
				  tx_length = len ;
				  return SUCCESS;
				  break;
			  default:
				  return FAIL ;
				  break;
		  }
	  }

	  /**
	   * Signal completion of sending a stream.
	   *
	   * @param 'uint8_t* COUNT(len) buf' Bytes sent.
	   * @param len Number of bytes sent.
	   * @param error SUCCESS if the transmission was successful, FAIL otherwise.
	   */
//	  async event void sendDone( uint8_t* buf, uint16_t len, error_t error );

	  /**
	   * Enable the receive byte interrupt. The <code>receive</code> event
	   * is signalled each time a byte is received.
	   *
	   * @return SUCCESS if interrupt was enabled, FAIL otherwise.
	   */
	  async command error_t UartStream.enableReceiveInterrupt(){
		  //void usart_enable_callback(&device_instance,USART_CALLBACK_BUFFER_RECEIVED);
		  return FAIL;
	  }

	  /**
	   * Disable the receive byte interrupt.
	   *
	   * @return SUCCESS if interrupt was disabled, FAIL otherwise.
	   */
	  async command error_t UartStream.disableReceiveInterrupt(){
//		  void usart_disable_callback(&device_instance,USART_CALLBACK_BUFFER_RECEIVED);
		  return FAIL;
	  }

	  /**
	   * Signals the receipt of a byte.
	   *
	   * @param byte The byte received.
	   */
//	  async event void UartStream.receivedByte( uint8_t byte );

	  /**
	   * Begin reception of a UART stream. If SUCCESS is returned,
	   * <code>receiveDone</code> will be signalled when reception is
	   * complete.
	   *
	   * @param 'uint8_t* COUNT(len) buf' Buffer for received bytes.
	   * @param len Number of bytes to receive.
	   * @return SUCCESS if request was accepted, FAIL otherwise.
	   */
	  async command error_t UartStream.receive( uint8_t* buf, uint16_t len ){
		  uint8_t result;
		  result = usart_read_buffer_job(&device_instance,buf,len) ;
		  switch(result){
			  case STATUS_BUSY:
				  return EBUSY;
				  break;
			  case STATUS_ERR_DENIED:
				  return FAIL ;
				  break;
			  case ERR_INVALID_ARG:
				  return EINVAL;
				  break;
			  case STATUS_OK:
				  rx_bfr_ptr = buf ;
				  rx_length = len ;
				  return SUCCESS;
				  break;
			  default:
				  return FAIL ;
				  break;
		  }
	  }


	  void bufferTransmitted(struct usart_module *const usart_module){
	  	signal UartStream.sendDone( tx_bfr_ptr, tx_length, SUCCESS);
	  }
	  void bufferReceived(struct usart_module *const usart_module){
	  	signal UartStream.receiveDone( rx_bfr_ptr, rx_length, SUCCESS);
	  }

	  default async event void UartStream.sendDone( uint8_t* ptr ,uint16_t length, error_t result){}
	  default async event void UartStream.receiveDone( uint8_t* ptr ,uint16_t length, error_t result){}
}

