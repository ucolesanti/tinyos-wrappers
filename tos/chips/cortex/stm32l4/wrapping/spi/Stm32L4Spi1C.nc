/*
 * AsfSpiWrapperC.nc
 *
 *  Created on: Jul 17, 2015
 *      Author: obren
 */
generic configuration Stm32L4Spi1C(){
	provides interface SpiPacket ;
	provides interface SpiByte ;
	provides interface FastSpiByte ;
	provides interface SpiConfig;
	provides interface Resource ;
}
implementation{
	enum{
		CLIENT_ID = unique("Stm32L4Spi1C"),
	};

	components Stm32L4Spi1P as SpiP;
	
	SpiByte = SpiP ;
	FastSpiByte = SpiP ;

	SpiPacket = SpiP.SpiPacket[CLIENT_ID] ;
	Resource = SpiP.Resource[CLIENT_ID] ;
	SpiConfig = SpiP.SpiConfig[CLIENT_ID] ;

}
