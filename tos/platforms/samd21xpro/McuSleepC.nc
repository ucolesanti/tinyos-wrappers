/*
 * Copyright (c) 2009 Stanford University.
 * Copyright (c) 2010 CSIRO Australia
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Wanja Hofer <wanja@cs.fau.de>
 * @author Kevin Klues <Kevin.Klues@csiro.au>
 * @author JeongGil Ko <jgko@cs.jhu.edu>
 * @author Philipp Sommer <philipp.sommer@csiro.au>
 */

#include "power.h"
module McuSleepC
{
  provides{
    interface McuSleep;
    interface McuPowerState;
  }

}
implementation{

  // This C function is defined so that we can call it
  // from platform_bootstrap(), as defined in platform.h
  void sam3uLowPowerConfigure() @C() @spontaneous() {

  }  

  async command void McuSleep.sleep()
  {
   // stay awake - I need to reenable interrupts here, otherwise I will never exit this status !

	  // can go to sleep since the PM is already configured to keep awake what is needed to run
//	  SCB->SCR |= SCB_SCR_SLEEPDEEP_Msk ;
//	  REG_PM_SLEEP = 0x02U ;
//	  __nesc_enable_interrupt();
//	  __DSB() ;
//	  __WFI() ;
#if (SAMD20 || SAMD21 || SAMR21)
  /* Errata: Make sure that the Flash does not power all the way down
   * when in sleep mode. */
  #warning ################## Applying patch for errata 13140 (ROM in standby)
  NVMCTRL->CTRLB.bit.SLEEPPRM = NVMCTRL_CTRLB_SLEEPPRM_DISABLED_Val;
#endif
	  system_set_sleepmode(SYSTEM_SLEEPMODE_STANDBY);
	  __nesc_enable_interrupt();
	  system_sleep();
    __nesc_disable_interrupt();

  }

  async command void McuPowerState.update(){}
  
}

