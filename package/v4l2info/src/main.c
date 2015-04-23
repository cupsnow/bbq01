
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <linux/videodev2.h>

#define VDEV_PATH "/dev/video0"

#define log_msg(level, msg, args...) do { \
	printf(level "%s #%d " msg, __func__, __LINE__, ##args); \
} while(0)
#define log_debug(msg, args...) log_msg("Debug ", msg, ##args)
#define log_error(msg, args...) log_msg("ERROR ", msg, ##args)

#define MOSS_ARRAYSIZE(_arr) (sizeof(_arr) / sizeof((_arr)[0]))

static struct {
	const char *dev_path;
	int fd;
} impl = {NULL};

static void help(const char *name)
{
	printf(
		"USAGE\n"
		"  %s [OPTION...]\n"
		"\n"
		"DESCRIPTION\n"
		"  Demo for web server\n"
		"\n"
		"OPTION\n"
		"  -h, --help      show this help\n"
		/* media */
		"  -d, --video     video device [%s]\n"
		"\n",
		name,

		VDEV_PATH);



}

static int cam_ioctl(int fd, int req, void *arg)
{
	int r = -1, cnt;

	for (cnt = 5; cnt > 0; cnt--) {
		if ((r = ioctl(fd, req, arg)) == 0 || (r = errno) != EINTR)
			break;
	}
	return r;
}

static int cam_enum_fmt(void)
{
	struct v4l2_fmtdesc desc;
	struct v4l2_frmsizeenum sz;
	int i, r = EIO;

	memset(&desc, 0, sizeof(desc));
	for (i = 0, desc.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
			(r = cam_ioctl(impl.fd, VIDIOC_ENUM_FMT, &desc)) == 0;
			desc.index++) {
		log_debug("enum fmt[%d]: %s\n", desc.index, desc.description);

		memset(&sz, 0, sizeof(sz));
		for (sz.pixel_format = desc.pixelformat;
				(r = cam_ioctl(impl.fd, VIDIOC_ENUM_FRAMESIZES,
						&sz)) == 0; sz.index++) {
			switch(sz.type) {
			case V4L2_FRMSIZE_TYPE_DISCRETE:
				log_debug("enum sz[%d]: discrete, %d x %d\n",
						sz.index, sz.discrete.width,
						sz.discrete.height);
				break;
			case V4L2_FRMSIZE_TYPE_CONTINUOUS:
				sz.stepwise.step_width =
						sz.stepwise.step_height = 1;
			case V4L2_FRMSIZE_TYPE_STEPWISE:
				log_debug("enum sz[%d]: step, [%d+%d..%d]"
						" x [%d+%d..%d]\n", sz.index,
						sz.stepwise.min_width,
						sz.stepwise.step_width,
						sz.stepwise.max_width,
						sz.stepwise.min_height,
						sz.stepwise.step_height,
						sz.stepwise.max_height);
				break;
			default:
				;
			}
		}
		if (r != 0 && r != EINVAL) break;
	}
	if (r == EINVAL) r = 0;
	return r;
}

int main(int argc, char *const *argv)
{
	int r, i;

	memset(&impl, 0, sizeof(impl));
	impl.fd = -1;

	{
		char *opt_short = "-:d:i:";
		struct option opt_long[] = {
			{"video", required_argument, NULL, 'd'},
			{"help", no_argument, NULL, 'h'},
			{NULL, 0, NULL, 0},
		};
		int opt_op, opt_idx;

		optind = 0;
		while ((opt_op = getopt_long(argc, argv, opt_short, opt_long,
				&opt_idx)) != -1) {
			if (opt_op == 'd') {
				impl.dev_path = optarg;
				continue;
			}
			if (opt_op == 'h') {
				help(argv[0]);
				goto finally;
			}
		}
	}
	if (!impl.dev_path) impl.dev_path = VDEV_PATH;
	if ((impl.fd = open(impl.dev_path, O_RDWR | O_NONBLOCK, 0)) == -1) {
		r = errno;
		log_error("open cam %s: %s(%d)\n", impl.dev_path, strerror(r), r);
		goto finally;
	}
	cam_enum_fmt();
finally:
	return 0;
}
