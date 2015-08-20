/*
 * main.c
 *
 *  Created on: Aug 10, 2015
 *      Author: joelai
 */

#ifdef __ARM_NEON__
#include <arm_neon.h>
#endif

#include <sys/types.h>
#include <pwd.h>
#include <errno.h>
#include <moss/util.h>

typedef enum cap_id_enum {
	CAP_NEON = 0x1,
} cap_id_t;

static int cap = 0
#ifdef __ARM_NEON__
		| CAP_NEON
#endif
		;

static void test01(int argc, char *const *argv)
{
	int r;
	struct passwd pwd, *pwd_res;
	char *pwd_buf = NULL;
	size_t pwd_buf_sz;
	const char *user = "joelai";

	if (argc >= 2) user = argv[1];

	if ((pwd_buf_sz = sysconf(_SC_GETPW_R_SIZE_MAX)) <= 0) {
		r = errno;
		log_error("_SC_GETPW_R_SIZE_MAX: %s(%d)\n", strerror(r), r);
		goto finally;
	}

	if ((pwd_buf = malloc(pwd_buf_sz)) == NULL) {
		r = ENOMEM;
		log_error("alloc pwd_buf\n");
		goto finally;
	}

	log_debug("check against %s\n", user);
	if ((r = getpwnam_r(user, &pwd, pwd_buf, pwd_buf_sz,
			&pwd_res)) != 0) {
		r = errno;
		log_error("getpwnam_r: %s(%d)\n", strerror(r), r);
		goto finally;
	}
finally:
	if (pwd_buf) free(pwd_buf);
}

int main(int argc, char *const *argv)
{
	log_debug("capabilities:\n"
		"  neon: %s\n",
		((cap & CAP_NEON) ? "yes" : "no"));
	test01(argc, argv);

}
