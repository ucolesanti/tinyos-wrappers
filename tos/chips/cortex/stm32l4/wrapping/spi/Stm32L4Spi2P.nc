/*
 * AsfSpiWrapperC.nc
 *
 *  Created on: Jul 17, 2015
 *      Author: obren
 */
//#include "conf_spi.h"
//#include "conf_sercom.h"
configuration Stm32L4Spi2P{
	provides interface SpiPacket[uint8_t id] ;
	provides interface SpiByte ;
	provides interface FastSpiByte ;
	provides interface Resource[uint8_t id] ;
	//provides interface SpiConfig[uint8_t id] ;
}
implementation{
	components new Stm32L4SpiImplP((uint32_t) SPI2) as SpiImplP ;
	components new SimpleFcfsArbiterC("Stm32L4Spi2C") as ResourceArbiterC;
	components Stm32L4SpiIntP;

	SpiByte = SpiImplP;
	SpiPacket = SpiImplP ;
	FastSpiByte = SpiImplP ;
	//SpiConfig = SamSpiImplP ;
	Resource = SpiImplP.Resource ;

	SpiImplP.ResourceConfigure <- ResourceArbiterC;
	SpiImplP.SubResource -> ResourceArbiterC;
	SpiImplP.SpiInterrupt -> Stm32L4SpiIntP.SpiInterrupt[2];
}