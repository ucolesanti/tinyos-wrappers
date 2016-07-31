#include "stm32l4xx_ll_usart.h"
#include "stm32l4xx_ll_bus.h"
#include "stm32l4xx_ll_rcc.h"
#include "stm32l4xx_ll_gpio.h"
module Stm32L4Usart2WrapperP{
	provides interface UartByte ;
	provides interface UartStream ;
	provides interface StdControl ;
	provides interface Init ;
	provides interface McuPowerOverride;
	uses interface McuPowerState;
}
implementation{
	void USART_TXEmpty_Callback(void);

	norace uint16_t m_tx_len;
	norace uint8_t *COUNT_NOK(m_tx_len) m_tx_buf;
	norace uint16_t m_tx_pos, m_rx_pos;
	norace uint8_t m_tx_intr;

	command error_t Init.init(){
		/* Configure Tx Pin as : Alternate function, High Speed, Push pull, Pull up */
		LL_GPIO_SetPinMode(GPIOD, LL_GPIO_PIN_5, LL_GPIO_MODE_ALTERNATE);
		LL_GPIO_SetAFPin_0_7(GPIOD, LL_GPIO_PIN_5, LL_GPIO_AF_7);
		LL_GPIO_SetPinSpeed(GPIOD, LL_GPIO_PIN_5, LL_GPIO_SPEED_FREQ_VERY_HIGH);
		LL_GPIO_SetPinOutputType(GPIOD, LL_GPIO_PIN_5, LL_GPIO_OUTPUT_PUSHPULL);
		LL_GPIO_SetPinPull(GPIOD, LL_GPIO_PIN_5, LL_GPIO_PULL_UP);

		/* Configure Rx Pin as : Alternate function, High Speed, Push pull, Pull up */
		LL_GPIO_SetPinMode(GPIOD, LL_GPIO_PIN_6, LL_GPIO_MODE_ALTERNATE);
		LL_GPIO_SetAFPin_0_7(GPIOD, LL_GPIO_PIN_6, LL_GPIO_AF_7);
		LL_GPIO_SetPinSpeed(GPIOD, LL_GPIO_PIN_6, LL_GPIO_SPEED_FREQ_VERY_HIGH);
		LL_GPIO_SetPinOutputType(GPIOD, LL_GPIO_PIN_6, LL_GPIO_OUTPUT_PUSHPULL);
		LL_GPIO_SetPinPull(GPIOD, LL_GPIO_PIN_6, LL_GPIO_PULL_UP);

		/* (2) Enable USART peripheral clock and clock source ***********************/
		LL_APB1_GRP1_EnableClock(LL_APB1_GRP1_PERIPH_USART2);

		/* Set clock source */
		LL_RCC_SetUSARTClockSource(LL_RCC_USART2_CLKSOURCE_PCLK1);

		/* (3) Configure USART functional parameters ********************************/

		/* Disable USART prior modifying configuration registers */
		/* Note: Commented as corresponding to Reset value */
		// LL_USART_Disable(USARTx_INSTANCE);

		/* TX/RX direction */
		LL_USART_SetTransferDirection(USART2, LL_USART_DIRECTION_TX_RX);

		/* 8 data bit, 1 start bit, 1 stop bit, no parity */
		LL_USART_ConfigCharacter(USART2, LL_USART_DATAWIDTH_8B, LL_USART_PARITY_NONE, LL_USART_STOPBITS_1);

		/* No Hardware Flow control */
		/* Reset value is LL_USART_HWCONTROL_NONE */
		// LL_USART_SetHWFlowCtrl(USARTx_INSTANCE, LL_USART_HWCONTROL_NONE);

		/* Oversampling by 16 */
		/* Reset value is LL_USART_OVERSAMPLING_16 */
		// LL_USART_SetOverSampling(USARTx_INSTANCE, LL_USART_OVERSAMPLING_16);

		/* Set Baudrate to 115200 using APB frequency set to 80000000 Hz */
		/* Frequency available for USART peripheral can also be calculated through LL RCC macro */
		/* Ex :
		  Periphclk = LL_RCC_GetUSARTClockFreq(Instance); or LL_RCC_GetUARTClockFreq(Instance); depending on USART/UART instance

		  In this example, Peripheral Clock is expected to be equal to 80000000 Hz => equal to SystemCoreClock
		*/
		LL_USART_SetBaudRate(USART2, SystemCoreClock, LL_USART_OVERSAMPLING_16, 500000); 

		/*## Configure the NVIC for UART ########################################*/
		/* NVIC for USART */
		NVIC_SetPriority(USART2_IRQn, DEFAULT_TINYOS_NVIC_PRIORITY);  
		NVIC_EnableIRQ(USART2_IRQn);

		return SUCCESS;
	}

	command error_t StdControl.start(){
		/* make sure interupts are off and set flags */
		LL_USART_DisableIT_TXE(USART2); 
		m_tx_intr = 0;

		/* Enable USART *********************************************************/
		LL_USART_Enable(USART2);


		/* Polling USART initialisation */
		while((!(LL_USART_IsActiveFlag_TEACK(USART2))) || (!(LL_USART_IsActiveFlag_REACK(USART2))))
		{ 
		}
		call McuPowerState.update();
		return SUCCESS;
	}

	command error_t StdControl.stop(){
		LL_USART_Disable(USART2);
		call McuPowerState.update();
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
		  while (!LL_USART_IsActiveFlag_TXE(USART2)){}
		  LL_USART_TransmitData8(USART2, byte);
		  return SUCCESS;
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
		  while (!LL_USART_IsActiveFlag_RXNE(USART2)){}
		  *byte = LL_USART_ReceiveData8(USART2);
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
	  	if ( len == 0 )
			return FAIL;
		else if ( m_tx_buf )
			return EBUSY;

		m_tx_len = len;
		m_tx_buf = buf;
		m_tx_pos = 0;
		m_tx_intr = 1;
		while (!LL_USART_IsActiveFlag_TXE(USART2)){}
		LL_USART_EnableIT_TXE(USART2); 
		LL_USART_TransmitData8(USART2, buf[ m_tx_pos++ ]);
		return SUCCESS; 
	  }

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
		  // uint8_t result;
		  // result = call HplUsartInterrupt.usart_read_buffer_job(&device_instance,buf,len) ;
		  // switch(result){
			 //  case STATUS_BUSY:
				//   return EBUSY;
				//   break;
			 //  case STATUS_ERR_DENIED:
				//   return FAIL ;
				//   break;
			 //  case ERR_INVALID_ARG:
				//   return EINVAL;
				//   break;
			 //  case STATUS_OK:
				//   rx_bfr_ptr = buf ;
				//   rx_length = len ;
				//   return SUCCESS;
				//   break;
			 //  default:
				//   return FAIL ;
				//   break;
		  // }
		  return FAIL; // TODO: not implemented yet
	  }

	  /**
		* @brief  Tx Transfer completed callback
		* @param  UartHandle: UART handle. 
		* @note   This example shows a simple way to report end of IT Tx transfer, and 
		*         you can add your own implementation. 
		* @retval None
		*/
		void USART_TXEmpty_Callback()
		{
			if ( m_tx_pos < m_tx_len ) {
				LL_USART_TransmitData8(USART2, m_tx_buf[ m_tx_pos++ ]);
			}
			else {
				uint8_t* buf = m_tx_buf;
				m_tx_buf = NULL;
				m_tx_intr = 0;
				LL_USART_DisableIT_TXE(USART2); 
				signal UartStream.sendDone( buf, m_tx_len, SUCCESS );
			}
		}

	  default async event void UartStream.sendDone( uint8_t* ptr ,uint16_t length, error_t result){}
	  default async event void UartStream.receiveDone( uint8_t* ptr ,uint16_t length, error_t result){}

	////////////////////////////// IT Section //////////////////////////////////////////
	/**
	* @brief  This function handles UART interrupt request.  
	* @param  None
	* @retval None
	* @Note   This function is redefined in "main.h" and related to DMA  
	*         used for USART data transmission     
	*/
	void USART2_IRQHandler(void) @C() @spontaneous()
	{
		if(LL_USART_IsEnabledIT_TXE(USART2) && LL_USART_IsActiveFlag_TXE(USART2))
		{
			/* TXE flag will be automatically cleared when writing new data in TDR register */

			/* Call function in charge of handling empty DR => will lead to transmission of next character */
			USART_TXEmpty_Callback();
		}
	}
	///////////////////////////////////////////////////////////////////////////////////

	async command mcu_power_t McuPowerOverride.lowestState()
	{
		if(LL_USART_IsEnabled(USART2)){
			return STM32L4_SLEEP;
		}
		else return STM32L4_STOP2;

	}
}

