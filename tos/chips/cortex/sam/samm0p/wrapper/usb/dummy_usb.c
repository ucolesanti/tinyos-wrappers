#include "compiler.h"
#include "usb_protocol_cdc.h"

void __attribute__((weak)) main_usb_detected(asf_bool_t detected){}
void __attribute__((weak)) main_sof_action(){} 
void __attribute__((weak)) main_suspend_action(){} 
void __attribute__((weak)) main_resume_action(){} 
void __attribute__((weak)) main_suspend_lpm_action(){} 
void __attribute__((weak)) main_remotewakeup_lpm_enable(){} 
void __attribute__((weak)) main_remotewakeup_lpm_disable(){} 

void __attribute__((weak)) main_cdc_enable(uint8_t p){} 
void __attribute__((weak)) main_cdc_disable(uint8_t p){} 
void __attribute__((weak)) uart_rx_notify(uint8_t p){} 
void __attribute__((weak)) uart_tx_notify(uint8_t p){} 
void __attribute__((weak)) uart_config(uint8_t p,usb_cdc_line_coding_t *c){} 
void __attribute__((weak)) main_cdc_set_dtr(uint8_t p, asf_bool_t b){} 