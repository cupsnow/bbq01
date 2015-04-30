
#include "util.h"

typedef enum trigger_enum {
	TRIGGER_NONE,
	TRIGGER_RISING,
	TRIGGER_FALLING,
	TRIGGER_BOTH,

} trigger_t;

static struct {
	void *init;
	int pin, dir, val;
	trigger_t trig;

	moss_evm_t *evm;
	moss_ev_t *ev;
	int fd;

} impl = {NULL};

static void help(const char *name)
{
	printf(
"USAGE\n"
"  %s [OPTION...]\n"
"\n"
"DESCRIPTION\n"
"  Demo to access GPIO\n"
"\n"
"OPTION\n"
"  -h, --help  show this help\n"
"  -p, --pin=PIN\n"
"              select gpio PIN\n"
"  -i, --in[=METHOD]\n"
"              config gpio input, edge trigger monitor\n"
"              METHOD := <rising | falling | both>\n"
"  -o, --out[=VALUE]\n"
"              config gpio output, output value\n"
"              VALUE := <0 | 1>\n"
"\n",
name);
}

static int file_vopen(unsigned mode, const char *fmt, va_list ap)
{
	char fn[] = "/sys/class/gpio/gpio00000000/01234567890abcdef";
	int r;

	r = vsnprintf(fn, sizeof(fn), fmt, ap);
	if (r <= 0 || r >= sizeof(fn)) {
		log_error("generate filename\n");
		return -1;
	}
	if ((r = open(fn, mode)) == -1) {
		r = errno;
		log_error("open %s, %s(%d)\n", fn, strerror(r), r);
		return -1;
	}
	return r;
}

static int file_open(unsigned mode, const char *fmt, ...)
{
	va_list ap;
	int r;

	va_start(ap, fmt);
	r = file_vopen(mode, fmt, ap);
	va_end(ap);
	return r;
}

static int file_vwrite(int fd, const char *fmt, va_list ap)
{
	char msg[] = "01234567890abcdef01234567890abcdef01234567890abcdef";
	int r, len;

	len = vsnprintf(msg, sizeof(msg), fmt, ap);
	if (len <= 0 || len >= sizeof(msg)) {
		log_error("generate message\n");
		return EINVAL;
	}
	if ((r = write(fd, msg, len)) != len) {
		if (r < 0) {
			r = errno;
			log_error("write, %s(%d)\n", strerror(r), r);
			return r;
		}
		log_error("write incomplete %d / %d\n", r, len);
		return EIO;
	}
	return 0;
}

static int file_write(int fd, const char *fmt, ...)
{
	va_list ap;
	int r;

	va_start(ap, fmt);
	r = file_vwrite(fd, fmt, ap);
	va_end(ap);
	return r;
}

static int gpio_write(const void *msg, size_t len, const char *fn_fmt, ...)
{
	va_list ap;
	int r, fd;

	va_start(ap, fn_fmt);
	fd = file_vopen(O_WRONLY, fn_fmt, ap);
	va_end(ap);

	if (fd == -1) return EIO;
	r = file_write(fd, msg);
	close(fd);
	return r;
}

static int gpio_read(void *msg, size_t len, const char *fn_fmt, ...)
{
	va_list ap;
	int r, fd;

	va_start(ap, fn_fmt);
	fd = file_vopen(O_RDONLY, fn_fmt, ap);
	va_end(ap);

	if (fd == -1) return EIO;
	if ((r = read(fd, msg, len)) < 0) {
		r = errno;
		log_error("read, %s(%d)\n", strerror(r), r);
		close(fd);
		return -1;
	}
	close(fd);
	return r;
}

static int gpio_open(int pin, int sw)
{
	char msg[] = "/sys/class/gpio/gpio01234567890";
	int fd, r, i;

	i = snprintf(msg, sizeof(msg), "/sys/class/gpio/gpio%d", pin);
	if (i >= sizeof(msg)) {
		log_error("generate filename\n");
		return EINVAL;
	}
	r = MOSS_FILE_MODE_DIR(msg);
	if (MOSS_XOR(sw, r) == 0) {
		return 0;
	}

	i = snprintf(msg, sizeof(msg), "%d", pin);
	if (i >= sizeof(msg)) {
		log_error("generate pin num\n");
		return EINVAL;
	}
	if ((r = gpio_write(msg, i, "/sys/class/gpio/%s",
			(sw ? "export" : "unexport"))) != 0) {
		log_error("gpio %s\n", (sw ? "on" : "off"));
		return r;
	}
	log_debug("gpio%d %s\n", pin, (sw ? "on" : "off"));
	return 0;
}

static int gpio_dir(int pin, int out)
{
	char msg[] = "01234567890";
	int r;

	if (out >= 0) {
		r = snprintf(msg, sizeof(msg), "%s", out ? "out" : "in");
		if (r >= sizeof(msg)) {
			log_error("generate pin dir\n");
			return -1;
		}
		if ((r = gpio_write(msg, r, "/sys/class/gpio/gpio%d/direction",
				pin)) != 0) {
			log_error("gpio dir\n");
			return -1;
		}
	}
	if ((r = gpio_read(msg, sizeof(msg), "/sys/class/gpio/gpio%d/direction",
			pin)) <= 0 || r >= sizeof(msg)) {
		log_error("gpio dir\n");
		return -1;
	}
	msg[r] = '\0';
	r = strcasecmp(moss_stripr(msg), "out") == 0;
	if (out >= 0 && MOSS_XOR(out, r)) {
		log_error("gpio dir\n");
		return -1;
	}
	return r;
}

static int gpio_val(int pin, int val)
{
	char msg[] = "01234567890";
	int r;

	if (val >= 0) {
		r = snprintf(msg, sizeof(msg), "%d", val);
		if (r >= sizeof(msg)) {
			log_error("generate pin val\n");
			return -1;
		}
		if ((r = gpio_write(msg, r, "/sys/class/gpio/gpio%d/value",
				pin)) != 0) {
			log_error("gpio val\n");
			return -1;
		}
	}
	if ((r = gpio_read(msg, sizeof(msg), "/sys/class/gpio/gpio%d/value",
			pin)) <= 0 || r >= sizeof(msg)) {
		log_error("gpio val\n");
		return -1;
	}
	msg[r] = '\0';
	r = strtol(moss_stripr(msg), NULL, 10);
	if (val >= 0 && MOSS_XOR(val, r)) {
		log_error("gpio val\n");
		return -1;
	}
	return r;
}

static int gpio_edge(int pin, trigger_t trig)
{
	char msg[] = "risingfalling";
	int r;

	r = snprintf(msg, sizeof(msg), "%s",
			((trig == TRIGGER_RISING) ? "rising" :
			(trig == TRIGGER_FALLING) ? "falling" :
			(trig == TRIGGER_BOTH) ? "both" :
			"none"));
	if (r >= sizeof(msg)) {
		log_error("generate pin edge\n");
		return -1;
	}
	if ((r = gpio_write(msg, r, "/sys/class/gpio/gpio%d/edge",
			pin)) != 0) {
		log_error("gpio edge\n");
		return -1;
	}
	return 0;
}

static int gpio_poll(int pin, trigger_t trig)
{
	char msg[] = "risingfalling";
	int r;

	if (gpio_open(pin, 0) != 0 || gpio_open(pin, 1) != 0 ||
			gpio_dir(pin, 0) < 0) {
		log_error("gpio reopen to input\n");
		goto finally;
	}

	if (gpio_edge(pin, trig) != 0) {
		log_error("gpio edge\n");
		goto finally;
	}

	if ((impl.evm = moss_evm_poll_alloc()) == NULL) {
		log_error("evm: alloc\n");
		r = -1;
		goto finally;
	}

//	if ((impl.fd = open(fn, O_RDONLY)) == -1) {
//		r = errno;
//		log_error("open %s, %s(%d)\n", fn, strerror(r), r);
//		return -1;
//	}
//	if ((impl.ev = moss_ev_poll_alloc(impl.rtsp.fd,
//			MOSS_EV_ACT_RD,
//			&rtsp_accept, &impl.rtsp)) == NULL) {
//		log_error("rtsp server: create ev to accept\n");
//		goto finally;
//	}
//	moss_evm_poll_add(impl.evm, impl.rtsp.ev);



finally:
	return r;
}

int main(int argc, char *const *argv)
{
	int r;

	memset(&impl, 0, sizeof(impl));
	impl.pin = -1;
	impl.dir = -1;
	impl.val = -1;
	impl.trig = TRIGGER_NONE;
	impl.fd = -1;
	{
		char *opt_short = "-:hp:i::o::";
		struct option opt_long[] = {
			{"help", no_argument, NULL, 'h'},
			{"pin", required_argument, NULL, 'p'},
			{"in", optional_argument, NULL, 'i'},
			{"out", optional_argument, NULL, 'o'},
			{NULL, 0, NULL, 0},
		};
		int opt_op, opt_idx;

		optind = 0;
		while ((opt_op = getopt_long(argc, argv, opt_short, opt_long,
				&opt_idx)) != -1) {
			if (opt_op == 'h') {
				help(argv[0]);
				goto finally;
			}
			if (opt_op == 'p') {
				impl.pin = strtol(optarg, NULL, 10);
				continue;
			}
			if (opt_op == 'o') {
				impl.dir = 1;
				if (optarg) impl.val = strtol(optarg, NULL, 10);
				continue;
			}
			if (opt_op == 'i') {
				impl.dir = 0;
				if (!optarg) {
					impl.trig = TRIGGER_NONE;
				} else if (strcasecmp(optarg, "rising") == 0 ||
						strcmp(optarg, "1") == 0) {
					impl.trig = TRIGGER_RISING;
				} else if (strcasecmp(optarg, "falling") == 0 ||
						strcmp(optarg, "0") == 0) {
					impl.trig = TRIGGER_FALLING;
				} else if (strcasecmp(optarg, "both") == 0 ||
						strcmp(optarg, "2") == 0) {
					impl.trig = TRIGGER_BOTH;
				} else {
					log_error("unknown trigger\n");
					help(argv[0]);
					goto finally;
				}
				continue;
			}
		}
	}

	/* PI/pin32 : led on camera module */
	if (impl.pin < 0 /* || impl.pin > 53 */) {
		log_error("unknown gpio pin\n");
		help(argv[0]);
		goto finally;
	}

	if (impl.trig != TRIGGER_NONE) {
		gpio_poll(impl.pin, impl.trig);
		goto finally;
	}

	if (gpio_open(impl.pin, 1) != 0) {
		log_error("gpio open\n");
		goto finally;
	}

	if (impl.dir >= 0 && gpio_dir(impl.pin, impl.dir) < 0) {
		log_error("gpio dir\n");
		goto finally;
	}

	if (impl.dir > 0 && impl.val >= 0 && gpio_val(impl.pin, impl.val) < 0) {
		log_error("gpio out val\n");
		goto finally;
	}

	log_debug("GPIO%d, dir: %d, val: %d\n", impl.pin,
			gpio_dir(impl.pin, -1), gpio_val(impl.pin, -1));
finally:
	return 0;
}
