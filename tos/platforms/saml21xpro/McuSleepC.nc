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
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 31, 2016
 */

#include "power.h"
module McuSleepC
{
  provides{
    interface McuSleep;
    interface McuPowerState;
  }
  uses{
    interface McuPowerOverride;
  }

}
implementation{
  norace int8_t powerState = -1;

  async command void McuSleep.sleep()
  {
    if( powerState < 0 ) {
      powerState = call McuPowerOverride.lowestState();
    }

// #if (SAMD20 || SAMD21 || SAMR21)
//   /* Errata: Make sure that the Flash does not power all the way down
//    * when in sleep mode. */
//   #warning ################## Applying patch for errata 13140 (ROM in standby)
//   NVMCTRL->CTRLB.bit.SLEEPPRM = NVMCTRL_CTRLB_SLEEPPRM_DISABLED_Val;
// #endif
  switch(powerState){
    case SAMM0_PWR_IDLE0:
        system_set_sleepmode(SYSTEM_SLEEPMODE_IDLE);
     break;
     case SAMM0_PWR_IDLE2:
        system_set_sleepmode(SYSTEM_SLEEPMODE_IDLE);
     break;
     case SAMM0_PWR_STDBY:
       //system_set_sleepmode(SYSTEM_SLEEPMODE_STANDBY);
       system_set_sleepmode(SYSTEM_SLEEPMODE_IDLE); // TODO: sleep disabled, need to debug...ndUgo
     break;
     default:
       system_set_sleepmode(SYSTEM_SLEEPMODE_IDLE);
     break;
        
   }
    __nesc_enable_interrupt();
    system_sleep();
    __nesc_disable_interrupt();

  }

  async command void McuPowerState.update(){
    powerState = -1;
  }

  default async command mcu_power_t McuPowerOverride.lowestState()
  {
    return SAMM0_PWR_STDBY;
  }
  
}

