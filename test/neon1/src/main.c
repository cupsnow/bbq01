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
#include <signal.h>

#include <moss/util.h>

typedef enum cap_id_enum {
	CAP_NEON = 0x1,
} cap_id_t;

static int cap = 0
#ifdef __ARM_NEON__
		| CAP_NEON
#endif
		;

static struct {
	void *evb;
	struct sigaction _sigint_org, *sigint_org;
	char stop;

} impl = {NULL};

static void signal_handler(int signo)
{
	log_debug("signo: %d\n", signo);
	if (signo == SIGINT) {
		log_debug("SIGINT\n");
		impl.stop = 1;
	}
}

static void sigaction_handler(int signum, siginfo_t *info, void *ptr)
{
	signal_handler(signum);
}

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

static void test02(int argc, char *const *argv)
{
	struct sigaction sigint;
	int r, cnt;

	if ((sigaction(SIGINT, NULL, &impl._sigint_org)) != 0) {
		r = errno;
		log_error("check SIGINT status: %s(%d)\n", strerror(r), r);
	} else {
		impl.sigint_org = &impl._sigint_org;
		if (impl.sigint_org->sa_handler == SIG_DFL) {
			log_debug("check SIGINT status: SIG_DFL\n");
		} else if (impl.sigint_org->sa_handler == SIG_IGN) {
			log_debug("check SIGINT status: SIG_IGN\n");
		}
	}

	sigint.sa_sigaction = sigaction_handler;
	sigemptyset (&sigint.sa_mask);
	sigint.sa_flags = SA_SIGINFO;
	if ((sigaction(SIGINT, &sigint, NULL)) != 0) {
		r = errno;
		log_error("hook SIGINT: %s(%d)\n", strerror(r), r);
		goto finally;
	}

	for (cnt = 10; !impl.stop && cnt > 0; cnt--) {
		sleep(1);
		log_debug("idx: %d\n", cnt);
	}
finally:
	;
}

int main(int argc, char *const *argv)
{
	memset(&impl, 0, sizeof(impl));
	log_debug("capabilities:\n"
		"  neon: %s\n",
		((cap & CAP_NEON) ? "yes" : "no"));
//	test01(argc, argv);
	test02(argc, argv);

}
