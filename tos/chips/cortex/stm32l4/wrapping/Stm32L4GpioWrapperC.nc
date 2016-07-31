/*
 * AsfGpioWrapperC.nc
 *
 *  Created on: Jul 16, 2015
 *      Author: obren
 */
#define PORTMAPPING(n,p) Port_##p##n = Stm32L4GpioWrapperP.Port_##p##n ;
#define PORTS(n,p) provides interface GeneralIO as Port_##p##n ;
configuration Stm32L4GpioWrapperC{
	REPEAT16(PORTS,A);
	REPEAT16(PORTS,B);
	REPEAT16(PORTS,C);
	REPEAT16(PORTS,D);
	REPEAT16(PORTS,E);
}
implementation{
	components Stm32L4GpioWrapperP,MainC ;
	
	REPEAT16(PORTMAPPING,A);
	REPEAT16(PORTMAPPING,B);
	REPEAT16(PORTMAPPING,C);
	REPEAT16(PORTMAPPING,D);
	REPEAT16(PORTMAPPING,E);

}

