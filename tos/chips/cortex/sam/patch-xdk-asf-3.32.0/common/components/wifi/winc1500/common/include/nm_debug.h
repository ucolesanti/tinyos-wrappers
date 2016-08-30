#ifndef _NM_DEBUG_H_
#define _NM_DEBUG_H_

#include "bsp/include/nm_bsp.h"
#include "bsp/include/nm_bsp_internal.h"

/**@defgroup  DebugDefines DebugDefines
 * @ingroup WlanDefines
 */
/**@{*/


#define M2M_LOG_NONE									0
#define M2M_LOG_ERROR									1
#define M2M_LOG_INFO									2
#define M2M_LOG_REQ										3
#define M2M_LOG_DBG										4

#if (defined __APS3_CORTUS__)
#define M2M_LOG_LEVEL									M2M_LOG_ERROR
#else
#define M2M_LOG_LEVEL									M2M_LOG_REQ
#endif


#define M2M_ERR(...)
#define M2M_INFO(...)
#define M2M_REQ(...)
#define M2M_DBG(...)
#define M2M_PRINT(...)

#if (CONF_WINC_DEBUG == 1)
#undef M2M_PRINT
#define M2M_PRINT(...)							do{CONF_WINC_PRINTF(__VA_ARGS__);CONF_WINC_PRINTF("\r");}while(0)
#if (M2M_LOG_LEVEL >= M2M_LOG_ERROR)
#undef M2M_ERR
#define M2M_ERR(...)							do{CONF_WINC_PRINTF("(APP)(ERR)[%s][%d]",__FUNCTION__,__LINE__); CONF_WINC_PRINTF(__VA_ARGS__);CONF_WINC_PRINTF("\r");}while(0)
#if (M2M_LOG_LEVEL >= M2M_LOG_INFO)
#undef M2M_INFO
#define M2M_INFO(...)							do{CONF_WINC_PRINTF("(APP)(INFO)"); CONF_WINC_PRINTF(__VA_ARGS__);CONF_WINC_PRINTF("\r");}while(0)
#if (M2M_LOG_LEVEL >= M2M_LOG_REQ)
#undef M2M_REQ
#define M2M_REQ(...)							do{CONF_WINC_PRINTF("(APP)(R)"); CONF_WINC_PRINTF(__VA_ARGS__);CONF_WINC_PRINTF("\r");}while(0)
#if (M2M_LOG_LEVEL >= M2M_LOG_DBG)
#undef M2M_DBG
#define M2M_DBG(...)							do{CONF_WINC_PRINTF("(APP)(DBG)[%s][%d]",__FUNCTION__,__LINE__); CONF_WINC_PRINTF(__VA_ARGS__);CONF_WINC_PRINTF("\r");}while(0)
#endif /*M2M_LOG_DBG*/
#endif /*M2M_LOG_REQ*/
#endif /*M2M_LOG_INFO*/
#endif /*M2M_LOG_ERROR*/
#endif /*CONF_WINC_DEBUG */

/**@}*/
#endif