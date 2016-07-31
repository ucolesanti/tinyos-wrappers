/*
 * AsfGpioIntWrapperC.nc
 *
 *  Created on: Jul 16, 2015
 *      Author: obren
 */

generic configuration Stm32L4GpioIntWrapperC(uint32_t port,uint32_t line,uint8_t channel){
	provides interface GpioInterrupt ;
}
implementation{
	components new Stm32L4GpioIntWrapperP(port,line,channel) as GpioIntP;
	components Stm32L4ExtiP;
	components MainC ;

	GpioInterrupt = GpioIntP;


	MainC.SoftwareInit->GpioIntP;
	MainC.SoftwareInit->Stm32L4ExtiP;
	GpioIntP.InterruptSignal->Stm32L4ExtiP.InterruptSignal[channel];

}
