/*
 * i2c_wrapper.h
 *
 *  Created on: Sep 7, 2015
 *      Author: obren
 */

#ifndef SPI_WRAPPER_H_
#define SPI_WRAPPER_H_
#include "stm32l4xx_ll_spi.h"

typedef struct spi_tos_config{
	uint32_t main_clock_div; // set the baudrate
	uint32_t clock_phase;
	uint32_t clock_polarity;
}spi_tos_config_t;


const spi_tos_config_t spi_tos_config_default = {
	LL_SPI_BAUDRATEPRESCALER_DIV32,
	LL_SPI_PHASE_1EDGE,
	LL_SPI_POLARITY_LOW
};

#endif /* SPI_WRAPPER_H_ */