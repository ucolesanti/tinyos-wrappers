/*
 * AsfRtcWrapperP.nc
 *
 *  Created on: Jul 16, 2015
 *      Author: obren
 */
#include "stm32l4xx_ll_lptim.h"
#include "stm32l4xx_ll_rcc.h"
#include "stm32l4xx_ll_bus.h"

module UlptimTimerP{
	provides interface Counter<T32khz, uint16_t>;
	provides interface Alarm<T32khz, uint16_t>;
	provides interface Init ;


}
implementation{
	void LPTimerAutoreloadMatch_Callback(void);
	void LPTimerCompareMatch_Callback(void);

	command error_t Init.init(){
		LL_LPTIM_InitTypeDef    lptim_initstruct;
  
		/***************************************/
		/* Select LSI as LPTIM1 clock source */
		/***************************************/
		LL_RCC_SetLPTIMClockSource(LL_RCC_LPTIM1_CLKSOURCE_LSI);

		/*************************************************/
		/* Configure the NVIC to handle LPTIM1 interrupt */
		/*************************************************/
		NVIC_SetPriority(LPTIM1_IRQn, DEFAULT_TINYOS_NVIC_PRIORITY);
		NVIC_EnableIRQ(LPTIM1_IRQn);

		/******************************/
		/* Peripheral clocks enabling */
		/******************************/
		/* Enable the timer peripheral clock */
		LL_APB1_GRP1_EnableClock(LL_APB1_GRP1_PERIPH_LPTIM1); 

		/****************************/
		/* LPTIM1 interrupts set-up */
		/****************************/
		/* Enable the Autoreload and Compare match Interrupt */
		LL_LPTIM_EnableIT_ARRM(LPTIM1);
		LL_LPTIM_EnableIT_CMPM(LPTIM1);

		/*****************************/
		/* LPTIM1 configuration      */
		/*****************************/
		/* Set fields of initialization structure */
		lptim_initstruct.ClockSource = LL_LPTIM_CLK_SOURCE_INTERNAL;
		lptim_initstruct.Prescaler   = LL_LPTIM_PRESCALER_DIV1;
		lptim_initstruct.Waveform    = LL_LPTIM_OUTPUT_WAVEFORM_PWM;
		lptim_initstruct.Polarity    = LL_LPTIM_OUTPUT_POLARITY_REGULAR;

		/* Initialize LPTIM instance according to parameters defined in             */
		/* initialization structure.                                                */
		LL_LPTIM_Init(LPTIM1, &lptim_initstruct);

		/* The counter is incremented following each valid clock pulse on the LPTIM external Input1 */
		LL_LPTIM_SetCounterMode(LPTIM1, LL_LPTIM_COUNTER_MODE_INTERNAL);

		/*****************************/
		/* Enable the LPTIM1 counter */
		/*****************************/
		LL_LPTIM_Enable(LPTIM1);

		/****************************/
		/* Set the Autoreload value */
		/****************************/
		LL_LPTIM_SetAutoReload(LPTIM1, 65535);

		/************************/
		/* Start LPTIM1 counter */
		/************************/
		/* Start the LPTIM counter in continuous mode */
		LL_LPTIM_StartCounter(LPTIM1, LL_LPTIM_OPERATING_MODE_CONTINUOUS);

		return SUCCESS ;
	}

	async command uint16_t Counter.get()
	{
		return (uint16_t) LL_LPTIM_GetCounter(LPTIM1);
	}

	default async event void Counter.overflow() { }


	/*
	 * @brief  Autoreload match callback in non blocking mode 
	 * @param  hlptim : LPTIM handle
	 * @retval None
	 */
	void LPTimerAutoreloadMatch_Callback()
	{
	  	signal Counter.overflow();
	}


	async command bool Counter.isOverflowPending()
	{
		return (LL_LPTIM_IsActiveFlag_ARRM(LPTIM1) != 0);
	}

	async command void Counter.clearOverflow()
	{
		LL_LPTIM_ClearFLAG_ARRM(LPTIM1);
	}

	default async event void Alarm.fired() { }

	/**
	  * @brief  Compare match callback in non blocking mode
	  * @param  hlptim : LPTIM handle
	  * @retval None
	  */
	void LPTimerCompareMatch_Callback() 
	{
		signal Alarm.fired();
	}

	async command void Alarm.stop()
	{
		LL_LPTIM_DisableIT_CMPM(LPTIM1);
	}

	async command bool Alarm.isRunning()
	{
		return (LL_LPTIM_IsEnabledIT_CMPM(LPTIM1) != 0);
	}

	// callers make sure that time is always in the future
	void setAlarm(uint16_t time)
	{
		LL_LPTIM_SetCompare(LPTIM1,time);
		LL_LPTIM_ClearFLAG_CMPM(LPTIM1);
		LL_LPTIM_EnableIT_CMPM(LPTIM1);
	}

	async command void Alarm.startAt(uint16_t nt0, uint16_t ndt)
	{
		atomic
		{
			// current time + time needed to set alarm
			uint16_t n = (uint16_t) LL_LPTIM_GetCounter(LPTIM1) + 1; // 1 is mindt

			// if alarm is set in the future, where n-nt0 is the time passed since nt0
			if( (uint16_t)(n - nt0) < ndt )
				n = nt0 + ndt;

			setAlarm(n);

		}
	}

	async command void Alarm.start(uint16_t ndt)
	{
		atomic
		{
			uint16_t n = (uint16_t) LL_LPTIM_GetCounter(LPTIM1);

			// calculate the next alarm
			n += (1 > ndt) ? 1 : ndt; // 1 is mindt

			setAlarm(n);

		}
	}

	async command uint16_t Alarm.getNow()
	{
		return (uint16_t) LL_LPTIM_GetCounter(LPTIM1);
	}

	async command uint16_t Alarm.getAlarm()
	{
		return (uint16_t) LL_LPTIM_GetCompare(LPTIM1);
	}

	////////////////////////////// IT Section //////////////////////////////////////////////

	/**
	  * @brief  This function handles LPTIM interrupt request.
	  * @param  None
	  * @retval None
	  */
	void LPTIM1_IRQHandler(void) @C() @spontaneous()
	{
	  /* Check whether Autoreload match interrupt is pending */
	  if(LL_LPTIM_IsEnabledIT_ARRM(LPTIM1) != 0 && LL_LPTIM_IsActiveFlag_ARRM(LPTIM1) != 0)
	  {
	    /* Clear the Autoreload match interrupt flag */
	    LL_LPTIM_ClearFLAG_ARRM(LPTIM1);
	    
	    /* LPTIM1 Autoreload match interrupt processing */
	    LPTimerAutoreloadMatch_Callback();
	  }

	  /* Check whether Compare match interrupt is pending */
	  if(LL_LPTIM_IsEnabledIT_CMPM(LPTIM1) != 0 && LL_LPTIM_IsActiveFlag_CMPM(LPTIM1) != 0)
	  {
	    /* Clear the Compare match interrupt flag */
	    LL_LPTIM_ClearFLAG_CMPM(LPTIM1);
	    
	    /* LPTIM1 Compare match interrupt processing */
	    LPTimerCompareMatch_Callback();
	  }
	}

	////////////////////////////////////////////////////////////////////////////////////////

	

	


}

