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
 * Wrapper for USB CDC implementation.
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */

#include "conf_usb.h"
#include "udc.h"
#include "udi_cdc.h"
module SamUsbP{
	provides interface Init ;
	provides interface StdControl as UsbControl ;
	provides interface UartByte;
	provides interface UartStream ;
	uses interface Timer<TMilli> as TimeoutTimer;
	uses interface Leds;

	// power management
	provides interface McuPowerOverride;
	uses interface McuPowerState;
}
implementation{
	bool vbus_det = FALSE;
	bool cdc_on = FALSE;
	bool dtr_on = FALSE;

	uint8_t* tx_bfr_ptr = NULL ;
	uint8_t* rx_bfr_ptr = NULL ;
	uint16_t tx_length = 0;
	uint16_t rx_length = 0;
	uint16_t rx_remaining = 0;

	enum{
		ENUMERATION_TIMEOUT = 10240U,
	};

	command error_t Init.init(){
		// Start USB stack with VBus monitoring (but wait vbus before calling udc_attach)
		udc_start();

		#if !defined(CONF_BOARD_USB_VBUS_DETECT)
			// If VBus monitoring is not available, attach it and start enumeration timeout
			atomic vbus_det = TRUE;
			call Leds.led0On();
			udc_attach();
			call TimeoutTimer.startOneShot(ENUMERATION_TIMEOUT);
			call McuPowerState.update();
		#endif

		return SUCCESS;
	}

	command error_t UsbControl.start(){
		// Auto power management
		return SUCCESS;
	}

	command error_t UsbControl.stop(){
		// Auto power management
		return SUCCESS;
	}

	event void TimeoutTimer.fired(){
		atomic vbus_det = FALSE;
		call Leds.led0Off();
		udc_detach();
		call McuPowerState.update();
	}

	/**
	   * Send a single uart byte. The call blocks until it is ready to
	   * accept another byte for sending.
	   *
	   * @param byte The byte to send.
	   * @return SUCCESS if byte was sent, FAIL otherwise.
	   */
	  async command error_t UartByte.send( uint8_t byte ){
		  	atomic{
				if(!cdc_on || ! dtr_on){
					return EOFF;
				}
			}
			if (!udi_cdc_is_tx_ready()) {
				/* Fifo full */
				udi_cdc_signal_overrun();
				return FAIL;
			} else {
				return (error_t) udi_cdc_putc(byte);
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
		  	atomic{
				if(!cdc_on || ! dtr_on){
					return EOFF;
				}
			}
		  while(!udi_cdc_is_rx_ready()){}
		  *byte = udi_cdc_getc();
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
			int remaining ;
			atomic{
				if(!cdc_on || ! dtr_on){
					return EOFF;
				}
			}
			remaining = udi_cdc_write_buf(buf,len) ;
			if(remaining > 0){
				return FAIL;
			}
			else{
				tx_bfr_ptr = buf ;
				tx_length = len ;
				return SUCCESS;
			} 
			
	  }

	 
	  async command error_t UartStream.enableReceiveInterrupt(){
		   return FAIL;
	  }

	  
	  async command error_t UartStream.disableReceiveInterrupt(){
		  return FAIL;
	  }

	 
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
		atomic{
			if(!cdc_on || ! dtr_on){
				return EOFF;
			}
		}
		if(rx_bfr_ptr != NULL){
			return EBUSY;
		}

		rx_bfr_ptr = buf ;
		rx_length = len ;
		rx_remaining = len;
		return SUCCESS;
	  }


	default async event void UartStream.sendDone( uint8_t* ptr ,uint16_t length, error_t result){}
	default async event void UartStream.receiveDone( uint8_t* ptr ,uint16_t length, error_t result){}



	////////////////////////////////////////////////////////////////////////////////////////////////////////

	void main_suspend_action(void) @C() @spontaneous()
	{
		// Do nothing
	}

	void main_resume_action(void) @C() @spontaneous() 
	{
		// Do nothing
	}

	void main_sof_action(void) @C() @spontaneous() 
	{
		// Do nothing (should I start something here?)
	}

	void main_usb_detected(asf_bool_t detected) @C() @spontaneous()
	{
		if(detected){
			udc_attach();
			call Leds.led0On();
			atomic vbus_det = TRUE; 
			call TimeoutTimer.startOneShot(ENUMERATION_TIMEOUT); // still need to check for cdc, but for 10s keep peripheral enabled.
		}
		else{
			udc_detach();
			call Leds.led0Off();
			atomic{
				vbus_det = FALSE;
				cdc_on = FALSE;
			} 

		} 
		call McuPowerState.update();
	}

#ifdef USB_DEVICE_LPM_SUPPORT
	void main_suspend_lpm_action(void) @C() @spontaneous() 
	{
		// Do nothing
	}

	void main_remotewakeup_lpm_disable(void) @C() @spontaneous() 
	{
		// Do nothing
	}

	void main_remotewakeup_lpm_enable(void) @C() @spontaneous() 
	{
		// Do nothing
	}
#endif

	asf_bool_t main_cdc_enable(uint8_t port) @C() @spontaneous() 
	{
		// enumeration performed, the device is USB powered with BUS active.
		atomic cdc_on = TRUE;
		call TimeoutTimer.stop();
		return cdc_on;
	}

	void main_cdc_disable(uint8_t port) @C() @spontaneous() 
	{
		atomic cdc_on = FALSE;
	}

	void main_cdc_set_dtr(uint8_t port, asf_bool_t b_enable) @C() @spontaneous() 
	{
		if(b_enable){
			atomic dtr_on = TRUE;
			call McuPowerState.update();
		}
		else{
			atomic dtr_on = FALSE;
			call McuPowerState.update();
		}
	}


	//////////////////////////////////////////

// called to notify the MCU that a character was sent over the USB
void uart_tx_notify(uint8_t port) @C() @spontaneous() 
{
	signal UartStream.sendDone( tx_bfr_ptr, tx_length, SUCCESS);
}

// called to notify the MCU that a character was received over the USB
void uart_rx_notify(uint8_t port) @C() @spontaneous() 
{
	
	if(rx_bfr_ptr != NULL && rx_length > 0){
		uint16_t bread = udi_cdc_read_no_polling(&rx_bfr_ptr[rx_length-rx_remaining],rx_remaining);
		if(bread >= rx_remaining){
			signal UartStream.receiveDone( rx_bfr_ptr, rx_length, SUCCESS);
			rx_bfr_ptr = NULL;
			rx_length = 0;
			rx_remaining = 0;
		}
		else{
			rx_remaining -= bread;
		}
	}
	// else ignore
}

void uart_config(uint8_t port,usb_cdc_line_coding_t *cfg) @C() @spontaneous() 
{
	// do nothing, I don't need to configure an uart or anything else.
}

void uart_open(uint8_t port) @C() @spontaneous() 
{
	// do nothing
}

void uart_close(uint8_t port) @C() @spontaneous() 
{
	// do nothing
}


	// Power management
	async command mcu_power_t McuPowerOverride.lowestState()
	{
		if(vbus_det || cdc_on){
			return SAMM0_PWR_IDLE0;
		}
		else return SAMM0_PWR_STDBY;

	}


}