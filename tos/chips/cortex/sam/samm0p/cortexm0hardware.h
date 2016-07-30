/*
 * Copyright (c) 2009 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
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
 * Definitions specific to the Cortex-M3 MCU.
 * Includes interrupt enable/disable routines for nesC.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 * @author Thomas Schmid
 */

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
 * File modified for Cortex M0+ with some add-ons. 
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */
 
#ifndef CORTEXM0_HARDWARE_H
#define CORTEXM0_HARDWARE_H



#define SAMM0_NONATOMIC_HANDLER(signame) \
	__attribute__((interrupt)) void signame() @C() @spontaneous()




#define ROUNDDOWN(a, n)                                         \
({                                                              \
        uint32_t __a = (uint32_t) (a);                          \
        (typeof(a)) (__a - __a % (n));                          \
})
// Round up to the nearest multiple of n
#define ROUNDUP(a, n)                                           \
({                                                              \
        uint32_t __n = (uint32_t) (n);                          \
        (typeof(a)) (ROUNDDOWN((uint32_t) (a) + __n - 1, __n)); \
})

typedef uint32_t __nesc_atomic_t;

inline __nesc_atomic_t __nesc_atomic_start() @spontaneous() __attribute__((always_inline))
{
	__nesc_atomic_t oldState = 0;
	__nesc_atomic_t newState = 1;
	asm volatile(
		"mrs %[old], primask\n"
		"msr primask, %[new]\n"
		: [old] "=&r" (oldState) // output, assure write only!
		: [new] "r"  (newState)  // input
        : "cc", "memory"         // clobber condition code flag and memory
	);
	return oldState;
}
 
inline void __nesc_atomic_end(__nesc_atomic_t oldState) @spontaneous() __attribute__((always_inline))
{
	asm volatile("" : : : "memory"); // memory barrier
 
	asm volatile(
		"msr primask, %[old]"
		:                      // no output
		: [old] "r" (oldState) // input
	);
}

// See definitive guide to Cortex-M3, p. 141, 142
// Enables all exceptions except hard fault and NMI
inline void __nesc_enable_interrupt() __attribute__((always_inline))
{
	// __nesc_atomic_t newState = 0;

	// asm volatile(
	// 	"msr primask, %0"
	// 	: // output
	// 	: "r" (newState) // input
	// );
	__DMB();
	__enable_irq(); // TODO: the previous implementation was not working in atmel studio. Check why.
}

// See definitive guide to Cortex-M3, p. 141, 142
// Disables all exceptions except hard fault and NMI
inline void __nesc_disable_interrupt() __attribute__((always_inline))
{
	// __nesc_atomic_t newState = 1;

	// asm volatile(
	// 	"msr primask, %0"
	// 	: // output
	// 	: "r" (newState) // input
	// );
	__disable_irq(); // TODO: the previous implementation was not working in atmel studio. Check why.
	__DMB();
}

#ifdef MTB_ENABLED
inline void __mtb_init() __attribute__((always_inline))
{
	MTB->POSITION.bit.WRAP = 0 ;
	MTB->POSITION.bit.POINTER = 0;//((uint32_t) __tracebuffer__ - MTB->BASE.reg)>>3 ;
	//MTB->MASTER.bit.MASK = 0x0a; // 16k MTB
	MTB->MASTER.bit.MASK = 0x08; // 4k MTB // 2^(MASK+4)

}

inline void __mtb_start() __attribute__((always_inline))
{
	REG_MTB_MASTER = REG_MTB_MASTER | MTB_MASTER_EN;
}

inline void __mtb_stop() __attribute__((always_inline))
{
	REG_MTB_MASTER = REG_MTB_MASTER & ~MTB_MASTER_EN;
}
#else
inline void __mtb_init() __attribute__((always_inline))
{
	for(;0;);
}

inline void __mtb_start() __attribute__((always_inline))
{
	for(;0;);
}

inline void __mtb_stop() __attribute__((always_inline))
{
	for(;0;);
}
#endif
inline void __mtb_stopblock() __attribute__((always_inline))
{
	atomic{
	    __mtb_stop();
	    while(TRUE){}
  	}
}


#endif // CORTEXM0_HARDWARE_H
