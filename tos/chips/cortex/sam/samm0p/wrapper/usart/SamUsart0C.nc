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
 * Usart0 module.
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */
#include "usart.h"
#include "conf_sercom.h"
configuration SamUsart0C{
	provides interface StdControl ;
	provides interface UartByte;
	provides interface UartStream;
}
implementation{
	components MainC ;
	components new SamUsartP((uint32_t)SERCOM0,SERCOM0_GENERATOR,SERCOM0_SPEED,SERCOM0_MUX,SERCOM0_PAD0,SERCOM0_PAD1,SERCOM0_PAD2,SERCOM0_PAD3) ;
	
	StdControl = SamUsartP;
	UartByte = SamUsartP;
	UartStream = SamUsartP ;

	MainC.SoftwareInit -> SamUsartP ;

}

