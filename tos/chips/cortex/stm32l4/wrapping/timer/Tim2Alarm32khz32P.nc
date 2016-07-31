/*
 * AsfRtcWrapperP.nc
 *
 *  Created on: Jul 16, 2015
 *      Author: obren
 */
#include "stm32l4xx_ll_tim.h"
#include "stm32l4xx_ll_rcc.h"
module Tim2Alarm32khz32P{
	provides interface Counter<T32khz, uint32_t>;
	provides interface Alarm<T32khz, uint32_t>;
	provides interface Init ;
}
implementation{
	/* Timer handler declaration */

	void TimerCaptureCompare_Callback(void);
	void TimerUpdate_Callback(void) ;

	command error_t Init.init(){
		/* Enable the timer peripheral clock */
		LL_APB1_GRP1_EnableClock(LL_APB1_GRP1_PERIPH_TIM2); 

		/* Set counter mode */
		/* Reset value is LL_TIM_COUNTERMODE_UP */
		LL_TIM_SetCounterMode(TIM2, LL_TIM_COUNTERMODE_UP);

		/* Disable output pins */ 
		LL_TIM_OC_SetMode(TIM2, LL_TIM_CHANNEL_CH1, LL_TIM_OCMODE_FROZEN);
		
		/* Set the pre-scaler value to have TIM2 counter clock equal to 32.768 kHz      */
		LL_TIM_SetPrescaler(TIM2, __LL_TIM_CALC_PSC(SystemCoreClock, 32768));

		/* Set the auto-reload value to its maximum */
		LL_TIM_SetAutoReload(TIM2, 0xffffffff);

		/* Enable the update interrupt */
		LL_TIM_EnableIT_UPDATE(TIM2);

		/* Configure the NVIC to handle TIM2 update interrupt */
		NVIC_SetPriority(TIM2_IRQn, DEFAULT_TINYOS_NVIC_PRIORITY);
		NVIC_EnableIRQ(TIM2_IRQn);


		/* Enable output channel 1 */
  		LL_TIM_CC_EnableChannel(TIM2, LL_TIM_CHANNEL_CH1);

		/* Enable counter */
		LL_TIM_EnableCounter(TIM2);

		/* Force update generation */ // TODO: not sure if it is required...
  		//LL_TIM_GenerateEvent_UPDATE(TIM2);

		return SUCCESS ;
	}

	async command uint32_t Counter.get()
	{
		return LL_TIM_GetCounter(TIM2);
	}

	default async event void Counter.overflow() { }


	
	void TimerUpdate_Callback() 
	{
	  	signal Counter.overflow();
	}


	async command bool Counter.isOverflowPending()
	{
		return (LL_TIM_IsActiveFlag_UPDATE(TIM2) != 0);
	}

	async command void Counter.clearOverflow()
	{
		LL_TIM_ClearFlag_UPDATE(TIM2);
	}

	default async event void Alarm.fired() { }

	void TimerCaptureCompare_Callback()
	{
		signal Alarm.fired();
	}

	async command void Alarm.stop()
	{
		LL_TIM_DisableIT_CC1(TIM2);
	}

	async command bool Alarm.isRunning()
	{
		return (LL_TIM_IsEnabledIT_CC1(TIM2) != 0);
	}

	// callers make sure that time is always in the future
	void setAlarm(uint32_t time)
	{
		LL_TIM_OC_SetCompareCH1(TIM2,time);
		LL_TIM_ClearFlag_CC1(TIM2);
		LL_TIM_EnableIT_CC1(TIM2);
	}

	async command void Alarm.startAt(uint32_t nt0, uint32_t ndt)
	{
		atomic
		{
			// current time + time needed to set alarm
			uint32_t n = LL_TIM_GetCounter(TIM2) + 1; // 1 is mindt

			// if alarm is set in the future, where n-nt0 is the time passed since nt0
			if( (uint32_t)(n - nt0) < ndt )
				n = nt0 + ndt;

			setAlarm(n);

		}
	}

	async command void Alarm.start(uint32_t ndt)
	{
		atomic
		{
			uint32_t n = LL_TIM_GetCounter(TIM2);

			// calculate the next alarm
			n += (1 > ndt) ? 1 : ndt; // 1 is mindt

			setAlarm(n);

		}
	}

	async command uint32_t Alarm.getNow()
	{
		return LL_TIM_GetCounter(TIM2);
	}

	async command uint32_t Alarm.getAlarm()
	{
		return LL_TIM_OC_GetCompareCH1(TIM2);
	}

	////////////////////////////// IT Section //////////////////////////////////////////////

	/**
	  * @brief  This function handles TIMx_INSTANCE Interrupt.
	  * @param  None
	  * @retval None
	  */
	void TIM2_IRQHandler(void) @C() @spontaneous()
	{
		//HAL_TIM_IRQHandler(&TimHandle);
		/* Check whether Update interrupt is pending */
		if(LL_TIM_IsEnabledIT_UPDATE(TIM2) != 0 && LL_TIM_IsActiveFlag_UPDATE(TIM2) != 0)
		{
			/* Clear the update interrupt flag*/
			LL_TIM_ClearFlag_UPDATE(TIM2);

			/* TIM2 capture/compare interrupt processing(function defined in main.c) */
			TimerUpdate_Callback();
		}

		/* Check whether CC1 interrupt is pending */
		if(LL_TIM_IsEnabledIT_CC1(TIM2) != 0 && LL_TIM_IsActiveFlag_CC1(TIM2) != 0)
		{
			/* Clear the update interrupt flag*/
			LL_TIM_ClearFlag_CC1(TIM2);

			/* TIM2 capture/compare interrupt processing(function defined in main.c) */
			TimerCaptureCompare_Callback();
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////

	

	


}

