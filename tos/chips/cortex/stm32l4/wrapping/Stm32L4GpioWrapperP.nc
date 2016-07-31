/*
 * AsfPinWrapper.nc
 *
 *  Created on: Jul 16, 2015
 *      Author: obren
 */
#include "stm32l4xx_ll_gpio.h"
#include "stm32l4xx_ll_bus.h"
#define PORTSMAP(n,p) provides interface GeneralIO as Port_##p##n ;

module Stm32L4GpioWrapperP{
	REPEAT16(PORTSMAP, A)
	REPEAT16(PORTSMAP, B)
	REPEAT16(PORTSMAP, C)
	REPEAT16(PORTSMAP, D)
	REPEAT16(PORTSMAP, E)
}
implementation{
	
	#define PORTSET(n,p) \
	  async command void Port_##p##n.set(){ \
		atomic{\
		  if(LL_GPIO_GetPinMode(GPIO##p,LL_GPIO_PIN_##n) == LL_GPIO_MODE_OUTPUT){ \
			  LL_GPIO_SetOutputPin(GPIO##p,LL_GPIO_PIN_##n); \
		  } \
		  else if(LL_GPIO_GetPinMode(GPIO##p,LL_GPIO_PIN_##n) == LL_GPIO_MODE_INPUT){ \
			  LL_GPIO_SetPinPull(GPIO##p,LL_GPIO_PIN_##n,LL_GPIO_PULL_UP); \
		  } \
  	    }\
	  }

	#define PORTCLR(n,p) \
	  async command void Port_##p##n.clr(){ \
	  	atomic{\
			if(LL_GPIO_GetPinMode(GPIO##p,LL_GPIO_PIN_##n) == LL_GPIO_MODE_OUTPUT){ \
				  LL_GPIO_ResetOutputPin(GPIO##p,LL_GPIO_PIN_##n); \
		    } \
			else if(LL_GPIO_GetPinMode(GPIO##p,LL_GPIO_PIN_##n) == LL_GPIO_MODE_INPUT){ \
				  LL_GPIO_SetPinPull(GPIO##p,LL_GPIO_PIN_##n,LL_GPIO_PULL_NO); \
			} \
	  	}\
	  }

	#define PORTTGL(n,p) \
	  async command void Port_##p##n.toggle(){ \
		atomic{\
			if(LL_GPIO_GetPinMode(GPIO##p,LL_GPIO_PIN_##n) == LL_GPIO_MODE_OUTPUT){ \
				  LL_GPIO_TogglePin(GPIO##p,LL_GPIO_PIN_##n); \
			  } \
			  /*else do nothing*/ \
		}\
	  }



	#define PORTGET(n,p) \
	  async command bool Port_##p##n.get(){ \
		  atomic{\
			  if(LL_GPIO_GetPinMode(GPIO##p,LL_GPIO_PIN_##n) == LL_GPIO_MODE_OUTPUT){ \
			  	  return (LL_GPIO_IsOutputPinSet(GPIO##p,LL_GPIO_PIN_##n) != 0); \
			  } \
			  else if(LL_GPIO_GetPinMode(GPIO##p,LL_GPIO_PIN_##n) == LL_GPIO_MODE_INPUT){ \
				  return (LL_GPIO_IsInputPinSet(GPIO##p,LL_GPIO_PIN_##n) != 0); \
			  } \
			  else return FALSE;\
	  	  }\
	  }



	#define PORTMKINPUT(n,p) \
	  async command void Port_##p##n.makeInput(){ \
	  	atomic{\
			LL_GPIO_SetPinMode(GPIO##p,LL_GPIO_PIN_##n,LL_GPIO_MODE_INPUT); \
		}\
	  }


	#define PORTISINPUT(n,p) \
	  async command bool Port_##p##n.isInput(){ \
		  atomic return (LL_GPIO_GetPinMode(GPIO##p,LL_GPIO_PIN_##n) == LL_GPIO_MODE_INPUT) ; \
	  }



	#define PORTMKOUTPUT(n,p) \
	  async command void Port_##p##n.makeOutput(){ \
		atomic{\
			LL_GPIO_SetPinMode(GPIO##p,LL_GPIO_PIN_##n,LL_GPIO_MODE_OUTPUT); \
		}\
	  }


	#define PORTISOUTPUT(n,p) \
	  async command bool Port_##p##n.isOutput(){ \
		 atomic return (LL_GPIO_GetPinMode(GPIO##p,LL_GPIO_PIN_##n) == LL_GPIO_MODE_OUTPUT) ; \
	  }



	REPEAT16(PORTSET,A)
	REPEAT16(PORTSET,B)
	REPEAT16(PORTSET,C)
	REPEAT16(PORTSET,D)
	REPEAT16(PORTSET,E)
		

	REPEAT16(PORTCLR,A)
	REPEAT16(PORTCLR,B)
	REPEAT16(PORTCLR,C)
	REPEAT16(PORTCLR,D)
	REPEAT16(PORTCLR,E)


	REPEAT16(PORTTGL,A)
	REPEAT16(PORTTGL,B)
	REPEAT16(PORTTGL,C)
	REPEAT16(PORTTGL,D)
	REPEAT16(PORTTGL,E)
		

	REPEAT16(PORTGET,A)
	REPEAT16(PORTGET,B)
	REPEAT16(PORTGET,C)
	REPEAT16(PORTGET,D)
	REPEAT16(PORTGET,E)
		

	REPEAT16(PORTMKINPUT,A)
	REPEAT16(PORTMKINPUT,B)
	REPEAT16(PORTMKINPUT,C)
	REPEAT16(PORTMKINPUT,D)
	REPEAT16(PORTMKINPUT,E)
		

	REPEAT16(PORTISINPUT,A)
	REPEAT16(PORTISINPUT,B)
	REPEAT16(PORTISINPUT,C)
	REPEAT16(PORTISINPUT,D)
	REPEAT16(PORTISINPUT,E)
		

	REPEAT16(PORTMKOUTPUT,A)
	REPEAT16(PORTMKOUTPUT,B)
	REPEAT16(PORTMKOUTPUT,C)
	REPEAT16(PORTMKOUTPUT,D)
	REPEAT16(PORTMKOUTPUT,E)
		

	REPEAT16(PORTISOUTPUT,A)
	REPEAT16(PORTISOUTPUT,B)
	REPEAT16(PORTISOUTPUT,C)
	REPEAT16(PORTISOUTPUT,D)
	REPEAT16(PORTISOUTPUT,E)
		
}

