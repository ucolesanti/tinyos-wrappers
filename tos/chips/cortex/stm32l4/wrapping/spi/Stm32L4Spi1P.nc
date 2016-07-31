/*
 * AsfSpiWrapperC.nc
 *
 *  Created on: Jul 17, 2015
 *      Author: obren
 */
configuration Stm32L4Spi1P{
	provides interface SpiPacket[uint8_t id] ;
	provides interface SpiByte ;
	provides interface FastSpiByte ;
	provides interface Resource[uint8_t id] ;
	provides interface SpiConfig[uint8_t id] ;
}
implementation{
	components new Stm32L4SpiImplP((uint32_t) SPI1) as SpiImplP ;
	components new SimpleFcfsArbiterC("Stm32L4Spi1C") as ResourceArbiterC;
	components Stm32L4Spi1ConfP as SpiConfP;
	components MainC,McuSleepC;

	SpiByte = SpiImplP;
	SpiPacket = SpiImplP ;
	FastSpiByte = SpiImplP ;
	SpiConfig = SpiImplP ;
	Resource = SpiImplP.Resource ;

	SpiImplP.ResourceConfigure <- ResourceArbiterC;
	SpiImplP.SubResource -> ResourceArbiterC;
	SpiImplP.SpiInterrupt -> SpiConfP;

	MainC.SoftwareInit -> SpiConfP;
	McuSleepC.McuPowerOverride -> SpiImplP;
	SpiImplP.McuPowerState -> McuSleepC;
}