/*
 * main.c
 *
 *  Created on: Jun 26, 2014
 *      Author: joelai
 */

#include <getopt.h>

#include "util.h"

extern int fb(void *cmd);
extern int ev(void *cmd);
extern int test_dfb(void *cmd);

static struct {
	void *init;
	int cmd;
	void *cmd_arg;
} impl = {NULL};

static void help(const char *prog)
{
	printf(
	"USAGE\n"
	"  %s [OPTION]\n"
	"\n"
	"OPTION\n"
	"  -h, --help  show help\n"
#ifdef WITH_EV
	"  -e, --ev    demo libevent\n"
#endif
#ifdef WITH_FB
	"  -f, --fb    demo framebuffer\n"
#endif
#ifdef WITH_DFB
	"  -d, --dfb   demo DirectFB\n"
#endif
	"\n", prog);
}

static int cmdline(int argc, char **argv)
{
	int op, idx;
	const struct option longopts[] = {
		{"help", 0, NULL, 'h'},
#ifdef WITH_EV
		{"ev", 0, NULL, 'e'},
#endif
#ifdef WITH_FB
		{"fb", 0, NULL, 'f'},
#endif
#ifdef WITH_DFB
		{"dfb", 0, NULL, 'd'},
#endif
		{""},
	};

	while((op = getopt_long(argc, argv, "-hef", longopts, &idx)) != -1) {
		switch(op) {
		case 'h':
			return 1;
#ifdef WITH_EV
		case 'e':
			if (impl.cmd) {
				util_log_error("Multiple command\n");
				return -1;
			}
			impl.cmd = UTIL_CMD_EV;
			break;
#endif
#ifdef WITH_FB
		case 'f':
			if (impl.cmd) {
				util_log_error("Multiple command\n");
				return -1;
			}
			impl.cmd = UTIL_CMD_FB;
			break;
#endif
#ifdef WITH_DFB
		case 'd':
			if (impl.cmd) {
				util_log_error("Multiple command\n");
				return -1;
			}
			impl.cmd = UTIL_CMD_DFB;
			break;
#endif
		case 1:
		case '?':
		default:
			break;
		}
	}
	return 0;
}

int main(int argc, char **argv)
{
	int i;

	memset(&impl, 0, sizeof(impl));

	for (i = 0; i < argc; i++)
		util_log_debug("argv[%d/%d]: %s\n", i + 1, argc, argv[i]);

	if (cmdline(argc, argv) != 0) {
		help(argv[0]);
		return 1;
	}
	switch(impl.cmd) {
#ifdef WITH_DFB
	case UTIL_CMD_FB:
		fb(NULL);
		break;
#endif
#ifdef WITH_EV
	case UTIL_CMD_EV:
		ev(NULL);
		break;
#endif
#ifdef WITH_DFB
	case UTIL_CMD_DFB:
	{
		util_dfb_t cmd;
		cmd.argc = argc;
		cmd.argv = argv;
		test_dfb(&cmd);
	}
		break;
#endif
	default:
		break;
	}
	return 0;
}
