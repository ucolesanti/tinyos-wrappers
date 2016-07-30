#include "spi_wrapper.h"
interface SpiConfig{
	async event const spi_tos_config_t* getConfig();
}

