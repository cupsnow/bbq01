
#include <sys/stat.h>
#include <sys/mman.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <linux/videodev2.h>

#define log_msg(level, msg, args...) do { \
	printf(level "%s #%d " msg, __func__, __LINE__, ##args); \
} while(0)
#define log_debug(msg, args...) log_msg("Debug ", msg, ##args)
#define log_error(msg, args...) log_msg("ERROR ", msg, ##args)
#define MOSS_FILE_MODE_DIR(_path) S_ISDIR(moss_file_mode(_path))
#define MOSS_XOR(_a, _b) (!!(_a) ^ !!(_b))

static struct {
	void *init;
	int pin, dir, val;
} impl = {NULL};

static char* moss_stripr(char *s)
{
	int len = s ? strlen(s) : 0;

	while(--len >= 0 && isspace(s[len]));
	if (s) s[len + 1] = '\0';
	return s;
}

static int moss_file_mode(const char *path)
{
	struct stat st;

	if (stat(path, &st) != 0) return 0;
	return st.st_mode;
}

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
"  -h, --help       show this help\n"
"  -p, --pin=PIN    select gpio PIN\n"
"  -i, --in         config gpio input\n"
"  -o, --out=VALUE  config gpio output and set value when VALUE >= 0\n"
"\n",
name);
}

static int gpio_write(const void *msg, size_t len, const char *fn_fmt, ...)
{
	char fn[] = "/sys/class/gpio/gpio00000000/01234567890abcdef";
	va_list ap;
	int r, fd;

	va_start(ap, fn_fmt);
	r = vsnprintf(fn, sizeof(fn), fn_fmt, ap);
	va_end(ap);
	if (r <= 0 || r >= sizeof(fn)) {
		log_error("generate filename\n");
		return EINVAL;
	}
	if ((fd = open(fn, O_WRONLY)) == -1) {
		r = errno;
		log_error("open %s, %s(%d)\n", fn, strerror(r), r);
		return r;
	}
	if ((r = write(fd, msg, len)) != len) {
		if (r < 0) {
			r = errno;
			log_error("write, %s(%d)\n", strerror(r), r);
		} else {
			r = EIO;
			log_error("write incomplete %d / %d\n", r, len);
		}
	} else {
		r = 0;
	}
	close(fd);
	return r;
}

static int gpio_read(void *msg, size_t len, const char *fn_fmt, ...)
{
	char fn[] = "/sys/class/gpio/gpio00000000/01234567890abcdef";
	va_list ap;
	int r, fd;

	va_start(ap, fn_fmt);
	r = vsnprintf(fn, sizeof(fn), fn_fmt, ap);
	va_end(ap);
	if (r <= 0 || r >= sizeof(fn)) {
		log_error("generate filename\n");
		return -1;
	}
	if ((fd = open(fn, O_RDONLY)) == -1) {
		r = errno;
		log_error("open %s, %s(%d)\n", fn, strerror(r), r);
		return -1;
	}
	if ((r = read(fd, msg, len)) < 0) {
		r = errno;
		log_error("read, %s(%d)\n", strerror(r), r);
		close(fd);
		return -1;
	}
	close(fd);
	return r;
}

static int gpio_open(int pin)
{
	char msg[] = "/sys/class/gpio/gpio01234567890";
	int fd, r, i;

	i = snprintf(msg, sizeof(msg), "/sys/class/gpio/gpio%d", pin);
	if (i >= sizeof(msg)) {
		log_error("generate filename\n");
		return EINVAL;
	}
	if (MOSS_FILE_MODE_DIR(msg)) return 0;

	i = snprintf(msg, sizeof(msg), "%d", pin);
	if (i >= sizeof(msg)) {
		log_error("generate pin num\n");
		return EINVAL;
	}
	if ((r = gpio_write(msg, i, "/sys/class/gpio/export")) != 0) {
		log_error("gpio open\n");
		return r;
	}
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

int main(int argc, char *const *argv)
{
	int r;

	memset(&impl, 0, sizeof(impl));
	impl.pin = -1;
	impl.dir = -1;
	{
		char *opt_short = "-:hp:io:";
		struct option opt_long[] = {
			{"help", no_argument, NULL, 'h'},
			{"pin", required_argument, NULL, 'p'},
			{"in", no_argument, NULL, 'i'},
			{"out", required_argument, NULL, 'o'},
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
				impl.val = strtol(optarg, NULL, 10);
				continue;
			}
			if (opt_op == 'i') {
				impl.dir = 0;
				continue;
			}
		}
	}
	if (impl.pin < 2 || impl.pin > 27) {
		log_error("unknown gpio pin\n");
		help(argv[0]);
		goto finally;
	}

	if (gpio_open(impl.pin) != 0) {
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
