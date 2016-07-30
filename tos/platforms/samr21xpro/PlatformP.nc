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
 * @date   Jul 30, 2016
 */

#include "system.h"
module PlatformP
{
  provides
  {
    interface Init;
  }
  uses{
	interface Init as LedsInit ;
  }


  
}

implementation
{

  command error_t Init.init()
  {
    error_t ok = SUCCESS;

    system_init(); // ASF system initialization: defines clocks etc...

#if !(SAMD10)
#warning "########### Applying patch for errata 12537 (VREG in standby)"
    /*
     * WORKAROUND for errata 12537:
     * Digital pin outputs from Timer/Counters, AC (Analog Comparator), GCLK
     * (Generic Clock Controller), and SERCOM (I2C and SPI) do not change value
     * during standby sleep mode. Errata reference: 12537
     * Fix/Workaround:
     * Set the voltage regulator in Normal mode before entering STANDBY sleep mode
     * in order to keep digital pin output enabled. This is done by setting the RUNSTDBY
     * bit in the VREG register.
     */
    SYSCTRL->VREG.bit.RUNSTDBY = 1 ;

#endif

  	ok = ecombine(ok, call LedsInit.init());
    if(ok != SUCCESS){
    	while(TRUE){} // forever loop to avoid boot.booted to be generated
    }
    return ok;
    return SUCCESS;
  }

default command error_t LedsInit.init() { return SUCCESS; }

 

  
}
