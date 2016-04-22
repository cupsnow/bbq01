/*
 * main.c
 *
 *  Created on: Apr 20, 2016
 *      Author: joelai
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <getopt.h>
#include <bluetooth/bluetooth.h>
#include <bluetooth/hci.h>
#include <bluetooth/hci_lib.h>
#include <bluetooth/rfcomm.h>

#include <moss/util.h>

typedef struct dev_lut_rec {
	const char *opt;
	const char *addr;
	const char *name;
} dev_lut_t;

static dev_lut_t dev_lut[] = {
	{"1", "30:A8:DB:5F:30:07", "Xperia Z2 Tablet"},
	{"2", "14:DD:A9:38:16:54", "ASUS_Z00AD"},
};

static struct {
	void *evb;
	const char *dev;

} impl = {NULL};

static void help(const char *name)
{
	printf(
"USAGE\n"
"  %s [OPTION...]\n"
"\n"
"DESCRIPTION\n"
"  Bluetooth test app\n"
"\n"
"OPTION\n"
"  -h, --help      show this help\n"
"  -d, --dev       bt device\n"
"    1: xperia tablet z2\n"
"    2: asus zenfone2\n"
"\n",
	name);

}

static int server_loop(void)
{
	struct sockaddr_rc loc_addr, rem_addr;
	char buf[1024];
	int r, sock = -1, fd = -1, rem_addr_sz = sizeof(rem_addr), len;

	if ((sock = socket(AF_BLUETOOTH, SOCK_STREAM, BTPROTO_RFCOMM)) < 0) {
		r = errno;
		log_error("create socket: %s(%d)\n", strerror(r), r);
		goto finally;
	}
	loc_addr.rc_family = AF_BLUETOOTH;
	loc_addr.rc_bdaddr = *BDADDR_ANY;
	loc_addr.rc_channel = (uint8_t)1;
	if ((r = bind(sock, (struct sockaddr*)&loc_addr, sizeof(loc_addr))) < 0) {
		r = errno;
		log_error("bind socket: %s(%d)\n", strerror(r), r);
		goto finally;
	}
	if ((r = listen(sock, 1)) < 0) {
		r = errno;
		log_error("listen socket: %s(%d)\n", strerror(r), r);
		goto finally;
	}
	log_debug("listen on bluetooth...\n");
	if ((fd = accept(sock, (struct sockaddr*)&rem_addr,
			&rem_addr_sz)) < 0) {
		r = errno;
		log_error("accept socket: %s(%d)\n", strerror(r), r);
		goto finally;
	}
	ba2str(&rem_addr.rc_bdaddr, buf);
	log_debug("accept bluetooth from %s\n", buf);

	while ((len = read(fd, buf, sizeof(buf) - 1)) > 0) {
		buf[len] = '\0';
		log_debug("receive %s\n", buf);
	}
	r = 0;
finally:
	if (fd != -1) close(fd);
	if (sock != -1) close(sock);
	return r;
}

int main(int argc, char **argv)
{
	inquiry_info *ii = NULL;
	int r, route = -1, dev = -1, i, len, max_rsp, num_rsp, flags;
	struct {
		dev_lut_t *dev_spec;
		inquiry_info *ii;
	} found = {NULL, NULL};

	memset(&impl, 0, sizeof(impl));
	{
		char *opt_short = "-:hd:";
		struct option opt_long[] = {
				{"help", no_argument, NULL, 'h'},
				{"dev", required_argument, NULL, 'd'},
				{NULL, 0, NULL, 0}
		};
		int opt_op, opt_idx;

		optind = 0;
		while ((opt_op = getopt_long(argc, argv, opt_short, opt_long,
				&opt_idx)) != -1) {
			if (opt_op == 'h') {
				help(argv[0]);
				goto finally;
			}
			if (opt_op == 'd') {
				if (!optarg) {
					impl.dev = "0";
					continue;
				}
				if (*optarg >= '1' && *optarg <= '2') {
					impl.dev = optarg;
					continue;
				}
				log_error("invalid option for device\n");
				help(argv[0]);
				goto finally;
			}
		}
	}

	if ((route = hci_get_route(NULL)) < 0) {
		r = errno;
		log_error("hci get route: %s(%d)\n", strerror(r), r);
		goto finally;
	}
	if ((dev = hci_open_dev(route)) < 0) {
		r = errno;
		log_error("hci open dev: %s(%d)\n", strerror(r), r);
		goto finally;
	}

	max_rsp = 255;
	if ((ii = (inquiry_info*)malloc(max_rsp * sizeof(inquiry_info))) == NULL) {
		log_error("alloc inquiry_info\n");
		goto finally;
	}

	log_debug("inquiry device...\n");
	len = 8;
	flags = IREQ_CACHE_FLUSH;
	if ((num_rsp = hci_inquiry(route, len, max_rsp, NULL, &ii, flags)) < 0) {
		r = errno;
		log_error("hci inquiry: %s(%d)\n", strerror(r), r);
		goto finally;
	}

	for (i = 0; i < num_rsp; i++) {
		inquiry_info *ii2 = ii + i;
		char addr[19], name[248];
		ba2str(&ii2->bdaddr, addr);
		memset(name, 0, sizeof(name));
		if ((hci_read_remote_name(dev, &ii2->bdaddr,
				sizeof(name), name, 0)) < 0) {
			strcpy(name, "[unknown]");
		}
		/* 30:A8:DB:5F:30:07  Xperia Z2 Tablet */

		if (!found.dev_spec && impl.dev) {
			int i;
			for (i = 0; i < MOSS_ARRAYSIZE(dev_lut); i++) {
				dev_lut_t *dev_spec = dev_lut + i;
				if ((*impl.dev == '0' || *impl.dev == *dev_spec->opt) &&
						strcmp(addr, dev_spec->addr) == 0) {
					found.dev_spec = dev_spec;
					found.ii = ii2;
					break;
				}
			}
		}
		log_debug("%s %s\n", addr, name);
	}

	if (found.dev_spec) {
		log_debug("found %s\n", found.dev_spec->name);
	}
	if ((r = server_loop()) != 0) {
		log_error("server failed\n");
		goto finally;
	}
	r = 0;
finally:
	if (ii) free(ii);
	if (dev) close(dev);
	return r;
}

