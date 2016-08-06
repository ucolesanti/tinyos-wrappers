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
 * Wrapper for Gpio module.
 *
 * @author Ugo Maria Colesanti
 * @date   Jul 30, 2016
 */

#include "mrepeat.h"
#define PORTSMAP(n,p) provides interface GeneralIO as Port_##p##n ;

module SamGpioP{
	MREPEAT(32,PORTSMAP, PA)
	MREPEAT(32,PORTSMAP, PB)
	MREPEAT(32,PORTSMAP, PC)

}
implementation{


	//#define PORTCONF(n,p) struct port_config pin_conf_##p##n = {PORT_PIN_DIR_INPUT,PORT_PIN_PULL_UP,false};

	#define PORTSET(n,p) \
  	async command void Port_##p##n.set(){ \
		struct port_config pin_conf;\
	 	atomic{\
	 	  if(port_pin_is_output(HPL_PIN_##p##n)){ \
	 		  port_pin_set_output_level(HPL_PIN_##p##n,1); \
	 	  } \
	 	  else{ \
	 		  port_get_config_defaults(&pin_conf); \
	 		  pin_conf.input_pull = PORT_PIN_PULL_UP; \
	 		  port_pin_set_config(HPL_PIN_##p##n,&pin_conf); \
	 	  } \
   	    }\
    }

	// #define PORTSET(n,p) \
	//   async command void Port_##p##n.set(){ \
	// 	atomic{\
	// 	  if(pin_conf_##p##n.direction == PORT_PIN_DIR_OUTPUT || pin_conf_##p##n.direction == PORT_PIN_DIR_OUTPUT_WTH_READBACK){ \
	// 		   port_pin_set_output_level(HPL_PIN_##p##n,1); \
	// 	  } \
	// 	  else{ \
	// 		  pin_conf_##p##n.input_pull = PORT_PIN_PULL_UP; \
	// 		   port_pin_set_config(HPL_PIN_##p##n,&pin_conf_##p##n); \
	// 	  } \
	//   	  }\
	//   }

	#define PORTCLR(n,p) \
  	async command void Port_##p##n.clr(){ \
	  	struct port_config pin_conf;\
		atomic{\
			if(port_pin_is_output(HPL_PIN_##p##n)){ \
				  port_pin_set_output_level(HPL_PIN_##p##n,0); \
		    } \
			else{ \
				  port_get_config_defaults(&pin_conf); \
				  pin_conf.input_pull = PORT_PIN_PULL_NONE; \
				  port_pin_set_config(HPL_PIN_##p##n,&pin_conf); \
			} \
	  	}\
  	}

	// #define PORTCLR(n,p) \
	//   async command void Port_##p##n.clr(){ \
	// 	atomic{\
	// 	if(pin_conf_##p##n.direction == PORT_PIN_DIR_OUTPUT || pin_conf_##p##n.direction == PORT_PIN_DIR_OUTPUT_WTH_READBACK){ \
	// 		   port_pin_set_output_level(HPL_PIN_##p##n,0); \
	// 	  } \
	// 	  else{ \
	// 		  pin_conf_##p##n.input_pull = PORT_PIN_PULL_NONE; \
	// 		   port_pin_set_config(HPL_PIN_##p##n,&pin_conf_##p##n); \
	// 	  } \
	//   	  }\
	//   }

	#define PORTTGL(n,p) \
  	async command void Port_##p##n.toggle(){ \
		atomic{\
			if(port_pin_is_output(HPL_PIN_##p##n)){ \
				  port_pin_toggle_output_level(HPL_PIN_##p##n); \
			  } \
			  /*else do nothing*/ \
		}\
  	}

	// #define PORTTGL(n,p) \
	//   async command void Port_##p##n.toggle(){ \
	// 	atomic{\
	// 	if(pin_conf_##p##n.direction == PORT_PIN_DIR_OUTPUT || pin_conf_##p##n.direction == PORT_PIN_DIR_OUTPUT_WTH_READBACK){ \
	// 		   port_pin_toggle_output_level(HPL_PIN_##p##n); \
	// 	  } \
	// 	  /*else do nothing*/ \
	// 	}\
	//   }

	#define PORTGET(n,p) \
  	async command bool Port_##p##n.get(){ \
		  atomic{\
			  if(port_pin_is_output(HPL_PIN_##p##n)){ \
			  	  return (port_pin_get_output_level(HPL_PIN_##p##n) != 0); \
			  } \
			  else{ \
				  return (port_pin_get_input_level(HPL_PIN_##p##n) != 0); \
			  } \
	  	  }\
  	}

	// #define PORTGET(n,p) \
	//   async command bool Port_##p##n.get(){ \
	// 	  atomic{\
	// 	  if(pin_conf_##p##n.direction == PORT_PIN_DIR_OUTPUT || pin_conf_##p##n.direction == PORT_PIN_DIR_OUTPUT_WTH_READBACK){ \
	// 	  	  return  port_pin_get_output_level(HPL_PIN_##p##n); \
	// 	  } \
	// 	  else{ \
	// 		  return  port_pin_get_input_level(HPL_PIN_##p##n); \
	// 	  } \
	//   	  }\
	//   }

	#define PORTMKINPUT(n,p) \
  	async command void Port_##p##n.makeInput(){ \
	  	struct port_config pin_conf;\
    	atomic{\
		  if(port_pin_is_output(HPL_PIN_##p##n)){ \
			  port_get_config_defaults(&pin_conf); \
			  pin_conf.input_pull = PORT_PIN_PULL_NONE;\
			  port_pin_set_config(HPL_PIN_##p##n,&pin_conf); \
		  } \
  	  	}\
  	}

   //  #define PORTMKINPUT(n,p) \
	  // async command void Port_##p##n.makeInput(){ \
   //  	atomic{\
		 //  if(pin_conf_##p##n.direction != PORT_PIN_DIR_INPUT){ \
			//   pin_conf_##p##n.direction = PORT_PIN_DIR_INPUT; \
			//    port_pin_set_config(HPL_PIN_##p##n,&pin_conf_##p##n); \
		 //  } \
	  // 	  }\
	  // }

	#define PORTISINPUT(n,p) \
	  async command bool Port_##p##n.isInput(){ \
		  atomic return (port_pin_is_output(HPL_PIN_##p##n) == 0) ; \
  	}

	// #define PORTISINPUT(n,p) \
	//   async command bool Port_##p##n.isInput(){ \
	// 	  atomic return pin_conf_##p##n.direction == PORT_PIN_DIR_INPUT ; \
	//   }

	#define PORTMKOUTPUT(n,p) \
	  async command void Port_##p##n.makeOutput(){ \
		struct port_config pin_conf;\
		atomic{\
		if(! port_pin_is_output(HPL_PIN_##p##n)){ \
			  port_get_config_defaults(&pin_conf); \
			  pin_conf.direction = PORT_PIN_DIR_OUTPUT;\
			  pin_conf.input_pull = PORT_PIN_PULL_NONE;\
			  port_pin_set_config(HPL_PIN_##p##n,&pin_conf); \
		  } \
	  	}\
	}

	// #define PORTMKOUTPUT(n,p) \
	//   async command void Port_##p##n.makeOutput(){ \
	// 	atomic{\
	// 	if(pin_conf_##p##n.direction != PORT_PIN_DIR_OUTPUT){ \
	// 		  pin_conf_##p##n.direction = PORT_PIN_DIR_OUTPUT; \
	// 		   port_pin_set_config(HPL_PIN_##p##n,&pin_conf_##p##n); \
	// 	  } \
	// 	  }\
	//   }

	// #define PORTISOUTPUT(n,p) \
	//   async command bool Port_##p##n.isOutput(){ \
	// 	 atomic return !(pin_conf_##p##n.direction == PORT_PIN_DIR_INPUT) ; \
	//   }

  	#define PORTISOUTPUT(n,p) \
	  async command bool Port_##p##n.isOutput(){ \
		 atomic return ( port_pin_is_output(HPL_PIN_##p##n) != 0) ; \
	  }

	//   MREPEAT(32,PORTCONF,PA)
	// MREPEAT(32,PORTCONF,PB)
	// MREPEAT(32,PORTCONF,PC)

	MREPEAT(32,PORTSET,PA)
	MREPEAT(32,PORTSET,PB)
	MREPEAT(32,PORTSET,PC)

	MREPEAT(32,PORTCLR,PA)
	MREPEAT(32,PORTCLR,PB)
	MREPEAT(32,PORTCLR,PC)


	MREPEAT(32,PORTTGL,PA)
	MREPEAT(32,PORTTGL,PB)
	MREPEAT(32,PORTTGL,PC)


	MREPEAT(32,PORTGET,PA)
	MREPEAT(32,PORTGET,PB)
	MREPEAT(32,PORTGET,PC)


	MREPEAT(32,PORTMKINPUT,PA)
	MREPEAT(32,PORTMKINPUT,PB)
	MREPEAT(32,PORTMKINPUT,PC)


	MREPEAT(32,PORTISINPUT,PA)
	MREPEAT(32,PORTISINPUT,PB)
	MREPEAT(32,PORTISINPUT,PC)


	MREPEAT(32,PORTMKOUTPUT,PA)
	MREPEAT(32,PORTMKOUTPUT,PB)
	MREPEAT(32,PORTMKOUTPUT,PC)


	MREPEAT(32,PORTISOUTPUT,PA)
	MREPEAT(32,PORTISOUTPUT,PB)
	MREPEAT(32,PORTISOUTPUT,PC)

}

