/*
 * main.c
 *
 *  Created on: Aug 10, 2015
 *      Author: joelai
 */

#ifdef __ARM_NEON__
#include <arm_neon.h>
#endif

#include <moss/util.h>

typedef enum cap_id_enum {
	CAP_NEON = 0x1,
} cap_id_t;

static int cap = 0
#ifdef __ARM_NEON__
		| CAP_NEON
#endif
		;

int main()
{
	log_debug("capabilities:\n"
		"  neon: %s\n",
		((cap & CAP_NEON) ? "yes" : "no"));


}
