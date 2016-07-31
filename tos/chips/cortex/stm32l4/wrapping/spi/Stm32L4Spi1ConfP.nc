
#include "stm32l4xx_ll_gpio.h"
#include "stm32l4xx_ll_rcc.h"

module Stm32L4Spi1ConfP{
	provides interface Init ;
	provides interface SpiInterrupt;
}
implementation{
	command error_t Init.init(){
		/* Configure SCK Pin connected to pin 31 of CN10 connector */
		LL_GPIO_SetPinMode(SPI1_SCK_GPIO_PORT, SPI1_SCK_PIN, LL_GPIO_MODE_ALTERNATE);
		LL_GPIO_SetPinOutputType(SPI1_SCK_GPIO_PORT, SPI1_SCK_PIN,LL_GPIO_OUTPUT_PUSHPULL);
		if (POSITION_VAL(SPI1_SCK_PIN) < 0x00000008U) LL_GPIO_SetAFPin_0_7(SPI1_SCK_GPIO_PORT, SPI1_SCK_PIN, LL_GPIO_AF_5);
		else LL_GPIO_SetAFPin_8_15(SPI1_SCK_GPIO_PORT, SPI1_SCK_PIN, LL_GPIO_AF_5);
		LL_GPIO_SetPinSpeed(SPI1_SCK_GPIO_PORT, SPI1_SCK_PIN, LL_GPIO_SPEED_FREQ_VERY_HIGH);
		LL_GPIO_SetPinPull(SPI1_SCK_GPIO_PORT, SPI1_SCK_PIN, LL_GPIO_PULL_DOWN);

		/* Configure MISO Pin connected to pin 27 of CN10 connector */
		LL_GPIO_SetPinMode(SPI1_MISO_GPIO_PORT, SPI1_MISO_PIN, LL_GPIO_MODE_ALTERNATE);
		LL_GPIO_SetPinOutputType(SPI1_MISO_GPIO_PORT, SPI1_MISO_PIN,LL_GPIO_OUTPUT_PUSHPULL);
		if (POSITION_VAL(SPI1_MISO_PIN) < 0x00000008U) LL_GPIO_SetAFPin_0_7(SPI1_MISO_GPIO_PORT, SPI1_MISO_PIN, LL_GPIO_AF_5);
		else LL_GPIO_SetAFPin_8_15(SPI1_MISO_GPIO_PORT, SPI1_MISO_PIN, LL_GPIO_AF_5);
		LL_GPIO_SetPinSpeed(SPI1_MISO_GPIO_PORT, SPI1_MISO_PIN, LL_GPIO_SPEED_FREQ_VERY_HIGH);
		LL_GPIO_SetPinPull(SPI1_MISO_GPIO_PORT, SPI1_MISO_PIN, LL_GPIO_PULL_DOWN);

		/* Configure MOSI Pin connected to pin 29 of CN10 connector */
		LL_GPIO_SetPinMode(SPI1_MOSI_GPIO_PORT, SPI1_MOSI_PIN, LL_GPIO_MODE_ALTERNATE);
		LL_GPIO_SetPinOutputType(SPI1_MOSI_GPIO_PORT, SPI1_MOSI_PIN,LL_GPIO_OUTPUT_PUSHPULL);
		if (POSITION_VAL(SPI1_MOSI_PIN) < 0x00000008U) LL_GPIO_SetAFPin_0_7(SPI1_MOSI_GPIO_PORT, SPI1_MOSI_PIN, LL_GPIO_AF_5);
		else LL_GPIO_SetAFPin_8_15(SPI1_MOSI_GPIO_PORT, SPI1_MOSI_PIN, LL_GPIO_AF_5);
		LL_GPIO_SetPinSpeed(SPI1_MOSI_GPIO_PORT, SPI1_MOSI_PIN, LL_GPIO_SPEED_FREQ_VERY_HIGH);
		LL_GPIO_SetPinPull(SPI1_MOSI_GPIO_PORT, SPI1_MOSI_PIN, LL_GPIO_PULL_DOWN);

		/* (2) Configure NVIC for SPI1 transfer complete/error interrupts **********/
		/* Set priority for SPI1_IRQn */
		NVIC_SetPriority(SPI1_IRQn, 0);
		/* Enable SPI1_IRQn           */
		NVIC_EnableIRQ(SPI1_IRQn);

		/* Enable the peripheral clock of SPI1 */
		LL_APB2_GRP1_EnableClock(LL_APB2_GRP1_PERIPH_SPI1);

		return SUCCESS;
	}

	/**
	* @brief  This function handles SPI1 interrupt request.
	* @param  None
	* @retval None
	*/
	void SPI1_IRQHandler(void) @C() @spontaneous()
	{
		/* Check RXNE flag value in ISR register */
		if(LL_SPI_IsEnabledIT_RXNE(SPI1) != 0 && LL_SPI_IsActiveFlag_RXNE(SPI1))
		{
			/* Call function Slave Reception Callback */
			//SPI1_Rx_Callback();
			signal SpiInterrupt.receiveComplete();
		}
		
		/* Check RXNE flag value in ISR register */
		else if(LL_SPI_IsEnabledIT_TXE(SPI1) != 0 && LL_SPI_IsActiveFlag_TXE(SPI1))
		{
			/* Call function Slave Reception Callback */
			//SPI1_Tx_Callback();
			signal SpiInterrupt.transmitComplete();

		}
		
		/* Check STOP flag value in ISR register */
		else if(LL_SPI_IsEnabledIT_ERR(SPI1) != 0  && LL_SPI_IsActiveFlag_OVR(SPI1))
		{
			/* Call Error function */
			//SPI1_TransferError_Callback();
			signal SpiInterrupt.error();
		}
	}

	default async event void SpiInterrupt.transceiveComplete(){}

	default async event void SpiInterrupt.receiveComplete(){}

	default async event void SpiInterrupt.transmitComplete(){}

	default async event void SpiInterrupt.error(){}
}