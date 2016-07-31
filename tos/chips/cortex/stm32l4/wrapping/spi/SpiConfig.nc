/*
 * I2CControl.nc
 *
 *  Created on: Sep 7, 2015
 *      Author: obren
 */
#include "spi_wrapper.h"
interface SpiConfig{
	async event const spi_tos_config_t* getConfig();
}
