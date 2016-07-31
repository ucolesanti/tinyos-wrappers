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
 * @author Ugo Maria Colesanti
 * @date   Jul 31, 2016
 */
 
#include "stm32l4xx_ll_pwr.h"
#include "stm32l4xx_ll_cortex.h"
module McuSleepC
{
  provides{
    interface McuSleep;
    interface McuPowerState;
  }
  uses {
    interface McuPowerOverride;
    interface Leds @atmostonce();
  }

}
implementation{

	norace int8_t powerState = -1;

  async command void McuSleep.sleep()
  {
  	if( powerState < 0 ) {
      powerState = call McuPowerOverride.lowestState();
    }

    //powerState = STM32L4_SLEEP; // HACK: disable stop2 mode. ndUgo -> remove when tests are finished.

    switch(powerState){
	   case STM32L4_STOP2:
        __nesc_enable_interrupt(); 
        /* Set STOP2 mode when CPU enters deepsleep */
        LL_PWR_SetPowerMode(LL_PWR_MODE_STOP2);

        /* Set SLEEPDEEP bit of Cortex System Control Register */
        LL_LPM_EnableDeepSleep();  

        /* Request Wait For Interrupt */
        __WFI();
        __nesc_disable_interrupt();
	   break;
	   case STM32L4_SLEEP:
	   		__nesc_enable_interrupt(); 
		   LL_PWR_DisableLowPowerRunMode();
       LL_LPM_EnableSleep();
       /* Request Wait For Interrupt */
        __WFI();
		   __nesc_disable_interrupt();
	   break;
	   default:
		   __nesc_enable_interrupt();
		   __nesc_disable_interrupt();
	   break;
	      
   }
  }

  async command void McuPowerState.update(){
  	powerState = -1;
  }

  default async command mcu_power_t McuPowerOverride.lowestState()
  {
    return STM32L4_STOP2;
  }
  
}

