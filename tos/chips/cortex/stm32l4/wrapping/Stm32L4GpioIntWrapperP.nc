/*
 * AsfGpioIntWrapperP.nc
 *
 *  Created on: Jul 16, 2015
 *      Author: obren
 */
 #include "stm32l4xx_ll_exti.h"
 #include "stm32l4xx_ll_system.h"
generic module Stm32L4GpioIntWrapperP(uint32_t port, uint32_t line, uint8_t channel){
	provides interface GpioInterrupt as Channel ;
	provides interface Init ;
	uses interface InterruptSignal ;

}
implementation{
	#define CHANNEL ((uint32_t) 1U << channel)
	command error_t Init.init(){
		/* Connect External Line to the GPIO*/
		LL_APB2_GRP1_EnableClock(LL_APB2_GRP1_PERIPH_SYSCFG);
		LL_SYSCFG_SetEXTISource(port, line);
		return SUCCESS;
	}
	
	async command error_t Channel.enableRisingEdge(){
		LL_EXTI_InitTypeDef exti_initstruct;

		/* Enable a rising trigger EXTI line Interrupt */
		/* Set fields of initialization structure */
		exti_initstruct.Line_0_31   = CHANNEL;
		exti_initstruct.Line_32_63  = LL_EXTI_LINE_NONE;
		exti_initstruct.LineCommand = ENABLE;
		exti_initstruct.Mode        = LL_EXTI_MODE_IT;
		exti_initstruct.Trigger     = LL_EXTI_TRIGGER_RISING;

		LL_EXTI_Init(&exti_initstruct);

		return SUCCESS;
	  }

	  async command error_t Channel.enableFallingEdge(){
		LL_EXTI_InitTypeDef exti_initstruct;

		/* Enable a falling trigger EXTI line Interrupt */
		/* Set fields of initialization structure */
		exti_initstruct.Line_0_31   = CHANNEL;
		exti_initstruct.Line_32_63  = LL_EXTI_LINE_NONE;
		exti_initstruct.LineCommand = ENABLE;
		exti_initstruct.Mode        = LL_EXTI_MODE_IT;
		exti_initstruct.Trigger     = LL_EXTI_TRIGGER_FALLING;

		LL_EXTI_Init(&exti_initstruct);

		return SUCCESS ;
	  }

	  async command error_t Channel.disable(){
		LL_EXTI_InitTypeDef exti_initstruct;

		/* Disable trigger EXTI line Interrupt */
		/* Set fields of initialization structure */
		exti_initstruct.Line_0_31   = CHANNEL;
		exti_initstruct.Line_32_63  = LL_EXTI_LINE_NONE;
		exti_initstruct.LineCommand = DISABLE;
		exti_initstruct.Mode        = LL_EXTI_MODE_IT;
		exti_initstruct.Trigger     = LL_EXTI_TRIGGER_NONE;

		LL_EXTI_Init(&exti_initstruct);

		return SUCCESS ;
	  }

	  async event void InterruptSignal.fired(){
	  	signal Channel.fired();
	  }

	  

}
