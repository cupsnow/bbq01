/*
 * util.h
 *
 *  Created on: Jun 26, 2014
 *      Author: joelai
 */

#ifndef _H_SAMPLE01_UTIL
#define _H_SAMPLE01_UTIL

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define util_log_msg(level, fmt, args...) do { \
	printf(level "%s #%ld " fmt, __func__, __LINE__, ##args); \
} while(0)
#define util_log_debug(fmt, args...) util_log_msg("Debug ", fmt, ##args)
#define util_log_error(fmt, args...) util_log_msg("ERROR ", fmt, ##args)

#define UTIL_CMD_FB 1
#define UTIL_CMD_EV 2
#define UTIL_CMD_DFB 3

typedef struct util_dfb_rec {
	int argc;
	char **argv;
} util_dfb_t;

#ifdef __cplusplus
extern "C" {
#endif



#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* _H_SAMPLE01_UTIL */
