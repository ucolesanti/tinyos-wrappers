module Stm32L4ExtiP{
	provides interface InterruptSignal[uint8_t];
	provides interface Init ;
}
implementation{

	command error_t Init.init(){
		NVIC_SetPriority((IRQn_Type)(EXTI0_IRQn), DEFAULT_TINYOS_NVIC_PRIORITY);
		NVIC_SetPriority((IRQn_Type)(EXTI1_IRQn), DEFAULT_TINYOS_NVIC_PRIORITY);
		NVIC_SetPriority((IRQn_Type)(EXTI2_IRQn), DEFAULT_TINYOS_NVIC_PRIORITY);
		NVIC_SetPriority((IRQn_Type)(EXTI3_IRQn), DEFAULT_TINYOS_NVIC_PRIORITY);
		NVIC_SetPriority((IRQn_Type)(EXTI4_IRQn), DEFAULT_TINYOS_NVIC_PRIORITY);
		NVIC_SetPriority((IRQn_Type)(EXTI9_5_IRQn), DEFAULT_TINYOS_NVIC_PRIORITY);
		NVIC_SetPriority((IRQn_Type)(EXTI15_10_IRQn), DEFAULT_TINYOS_NVIC_PRIORITY);

		NVIC_EnableIRQ(EXTI0_IRQn);
		NVIC_EnableIRQ(EXTI1_IRQn);
		NVIC_EnableIRQ(EXTI2_IRQn);
		NVIC_EnableIRQ(EXTI3_IRQn);
		NVIC_EnableIRQ(EXTI4_IRQn);
		NVIC_EnableIRQ(EXTI9_5_IRQn);
		NVIC_EnableIRQ(EXTI15_10_IRQn);

		return SUCCESS;
	}
	
	void EXTI0_IRQHandler(void) @C() @spontaneous()
	{
		LL_EXTI_ClearFlag_0_31(1U<<0);
		signal InterruptSignal.fired[0]() ;
	}

	void EXTI1_IRQHandler(void) @C() @spontaneous()
	{
		LL_EXTI_ClearFlag_0_31(1U<<1);
		signal InterruptSignal.fired[1]() ;
	}

	void EXTI2_IRQHandler(void) @C() @spontaneous()
	{
		LL_EXTI_ClearFlag_0_31(1U<<2);
		signal InterruptSignal.fired[2]() ;
	}

	void EXTI3_IRQHandler(void) @C() @spontaneous()
	{
		LL_EXTI_ClearFlag_0_31(1U<<3);
		signal InterruptSignal.fired[3]() ;
	}

	void EXTI4_IRQHandler(void) @C() @spontaneous()
	{
		LL_EXTI_ClearFlag_0_31(1U<<4);
		signal InterruptSignal.fired[4]() ;
	}

	void EXTI9_5_IRQHandler(void) @C() @spontaneous()
	{
		uint8_t i;
		for(i=5;i<10;i++){
			/* Manage Flags */
			if(LL_EXTI_IsActiveFlag_0_31(1U<<i) != RESET)
			{
				LL_EXTI_ClearFlag_0_31(1U<<i);
				signal InterruptSignal.fired[i]() ;
			}
		}
	}

	void EXTI15_10_IRQHandler(void) @C() @spontaneous()
	{
		uint8_t i;
		for(i=10;i<16;i++){
			/* Manage Flags */
			if(LL_EXTI_IsActiveFlag_0_31(1U<<i) != RESET)
			{
				LL_EXTI_ClearFlag_0_31(1U<<i);
				signal InterruptSignal.fired[i]() ;
			}
		}
	}

	default async event void InterruptSignal.fired[uint8_t i](){}
}