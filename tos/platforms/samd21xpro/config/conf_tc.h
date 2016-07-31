/*
 * conf_tc.h
 *
 *  Created on: Jul 21, 2015
 *      Author: obren
 */

#ifndef CONF_TC_H_
#define CONF_TC_H_
#define TC_ASYNC true
////[definition_pwm]
///** PWM module to use */
//#define PWM_MODULE      EXT1_PWM_MODULE
///** PWM output pin */
//#define PWM_OUT_PIN     EXT1_PWM_0_PIN
///** PWM output pinmux */
//#define PWM_OUT_MUX     EXT1_PWM_0_MUX
////[definition_pwm]
#define GENERATOR_31KHZ GCLK_GENERATOR_3
#define DIV_8MHZ_31KHZ TC_CLOCK_PRESCALER_DIV256



#endif /* CONF_TC_H_ */
