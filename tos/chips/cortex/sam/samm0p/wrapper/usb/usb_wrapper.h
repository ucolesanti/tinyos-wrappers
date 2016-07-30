#ifndef __USB_WRAPPER_H__
#define __USB_WRAPPER_H__

	void main_suspend_action(void);

	void main_resume_action(void);

	void main_sof_action(void);

	void main_usb_detected(asf_bool_t);


#ifdef USB_DEVICE_LPM_SUPPORT
	void main_suspend_lpm_action(void);

	void main_remotewakeup_lpm_disable(void);

	void main_remotewakeup_lpm_enable(void);
#endif

	asf_bool_t main_cdc_enable(uint8_t port);

	void main_cdc_disable(uint8_t port);

	void main_cdc_set_dtr(uint8_t port, asf_bool_t b_enable);


	//////////////////////////////////////////

void uart_tx_notify(uint8_t port);


void uart_rx_notify(uint8_t port);

void uart_config(uint8_t port,usb_cdc_line_coding_t *cfg);

void uart_open(uint8_t port);

void uart_close(uint8_t port);

#endif //__USB_WRAPPER_H__