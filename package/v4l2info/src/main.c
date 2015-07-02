
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
		"  Show v4l2 device info\n"
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

static void cam_dump_capability(struct v4l2_capability *capability)
{
	__u32 caps = (capability->capabilities & V4L2_CAP_DEVICE_CAPS ?
			capability->device_caps : capability->capabilities);
	char *cap_str;

	if (capability->capabilities & V4L2_CAP_DEVICE_CAPS) {
		cap_str = "device ";
		caps = capability->device_caps;
	} else {
		cap_str = "";
		caps = capability->capabilities;
	}

	log_debug("Video device capabilities:\n"
		"  bus: %s, card: %s\n"
		"  driver: %s, version: %u.%u.%u\n"
		"  %scapabilities: 0x%X\n"
		"    single-planar capture interface: %s\n"
		"    read/write io method: %s\n"
		"    streaming io(mmap) method: %s\n",
			capability->bus_info, capability->card, capability->driver,
			(capability->version >> 16) & 0xff, (capability->version >> 8) & 0xff,
			(capability->version >> 0) & 0xff,
			cap_str, caps,
			(caps & V4L2_CAP_VIDEO_CAPTURE ? "yes" : "no"),
			(caps & V4L2_CAP_READWRITE ? "yes" : "no"),
			(caps & V4L2_CAP_STREAMING ? "yes" : "no"));
}

static void cam_dump_fmtdesc(struct v4l2_fmtdesc *fmtdesc)
{
	log_debug("Video format describe[%d]: %s\n",
			fmtdesc->index, fmtdesc->description);
}

static void cam_dump_frmsizeenum(struct v4l2_frmsizeenum *frmsizeenum)
{
	switch(frmsizeenum->type) {
	case V4L2_FRMSIZE_TYPE_DISCRETE:
		log_debug("Video size[%d]: discrete, %d x %d\n",
				frmsizeenum->index, frmsizeenum->discrete.width,
				frmsizeenum->discrete.height);
		break;
	case V4L2_FRMSIZE_TYPE_CONTINUOUS:
		log_debug("Video size[%d]: continuous, [%d..%d] x [%d..%d]\n",
				frmsizeenum->index,
				frmsizeenum->stepwise.min_width,
				frmsizeenum->stepwise.max_width,
				frmsizeenum->stepwise.min_height,
				frmsizeenum->stepwise.max_height);
		break;
	case V4L2_FRMSIZE_TYPE_STEPWISE:
		log_debug("Video size[%d]: step, [%d+%d..%d] x [%d+%d..%d]\n",
				frmsizeenum->index,
				frmsizeenum->stepwise.min_width,
				frmsizeenum->stepwise.step_width,
				frmsizeenum->stepwise.max_width,
				frmsizeenum->stepwise.min_height,
				frmsizeenum->stepwise.step_height,
				frmsizeenum->stepwise.max_height);
		break;
	default:
		;
	}
}

static void cam_dump_streamparm(struct v4l2_streamparm *streamparm)
{
	log_debug("Video stream parameter:\n"
			"  frame interval: %d / %d\n"
			"  capability: 0x%X\n"
			"    skip frame: %s\n",
			streamparm->parm.capture.timeperframe.numerator,
			streamparm->parm.capture.timeperframe.denominator,
			streamparm->parm.capture.capability,
			(streamparm->parm.capture.capability & V4L2_CAP_TIMEPERFRAME ? "yes" : "no"));
}

static void cam_dump_format(struct v4l2_format *format)
{
	log_debug("Video format:\n"
		"  stream: %s(%d)\n"
		"  image dimension: %d(%d bytes) x %d, size: %d\n"
		"  image pixelformat: %c%c%c%c(0x%X)\n"
		"  field: %s(%d)\n",
			((format->type == 1) ? "single-planar video capture" :
			"http://linuxtv.org/downloads/v4l-dvb-apis/buffer.html#v4l2-buf-type"),
			format->type, format->fmt.pix.width, format->fmt.pix.bytesperline,
			format->fmt.pix.height, format->fmt.pix.sizeimage,
			(format->fmt.pix.pixelformat >> 0) & 0xff,
			(format->fmt.pix.pixelformat >> 8) & 0xff,
			(format->fmt.pix.pixelformat >> 16) & 0xff,
			(format->fmt.pix.pixelformat >> 24) & 0xff,
			format->fmt.pix.pixelformat,
			((format->fmt.pix.field == V4L2_FIELD_ANY) ? "Any" :
			(format->fmt.pix.field == V4L2_FIELD_NONE) ? "Progressive" :
			(format->fmt.pix.field == V4L2_FIELD_INTERLACED) ? "Interlaced" :
			"unknown"), format->fmt.pix.field);
}

static void cam_dump_frmivalenum(struct v4l2_frmivalenum *frmivalenum)
{
	switch(frmivalenum->type) {
	case V4L2_FRMIVAL_TYPE_DISCRETE:
		log_debug("Frame interval[%d]: discrete, %d / %d\n",
				frmivalenum->index,
				frmivalenum->discrete.numerator,
				frmivalenum->discrete.denominator);
		break;
	case V4L2_FRMIVAL_TYPE_CONTINUOUS:
		log_debug("Frame interval[%d]: continuous, (%d / %d)..(%d / %d)\n",
				frmivalenum->index,
				frmivalenum->stepwise.min.numerator,
				frmivalenum->stepwise.min.denominator,
				frmivalenum->stepwise.max.numerator,
				frmivalenum->stepwise.max.denominator);
		break;
	case V4L2_FRMIVAL_TYPE_STEPWISE:
		log_debug("Frame interval[%d]: step, (%d / %d)+(%d / %d)..(%d / %d)\n",
				frmivalenum->index,
				frmivalenum->stepwise.min.numerator,
				frmivalenum->stepwise.min.denominator,
				frmivalenum->stepwise.step.numerator,
				frmivalenum->stepwise.step.denominator,
				frmivalenum->stepwise.max.numerator,
				frmivalenum->stepwise.max.denominator);
		break;
	default:
		;
	}
}

static int cam_enum_fmt(void)
{
	struct v4l2_fmtdesc desc;
	struct v4l2_frmsizeenum sz;
	struct v4l2_capability cap;
	struct v4l2_streamparm parm;
	struct v4l2_format fmt;
	struct v4l2_frmivalenum frmi;
	int r = EIO;

	if ((r = cam_ioctl(impl.fd, VIDIOC_QUERYCAP, &cap)) != 0) {
		log_error("VIDIOC_QUERYCAP, %s(%d)\n", strerror(r), r);
		return r;
	}
	cam_dump_capability(&cap);

	memset(&desc, 0, sizeof(desc));
	for (desc.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
			cam_ioctl(impl.fd, VIDIOC_ENUM_FMT, &desc) == 0;
			desc.index++) {
		cam_dump_fmtdesc(&desc);

		memset(&sz, 0, sizeof(sz));
		for (sz.pixel_format = desc.pixelformat;
				cam_ioctl(impl.fd, VIDIOC_ENUM_FRAMESIZES, &sz) == 0;
				sz.index++) {
			cam_dump_frmsizeenum(&sz);

			memset(&frmi, 0, sizeof(frmi));
			frmi.pixel_format = sz.pixel_format;
			switch(sz.type) {
			case V4L2_FRMSIZE_TYPE_DISCRETE:
				frmi.width = sz.discrete.width;
				frmi.height = sz.discrete.height;
				break;
			case V4L2_FRMSIZE_TYPE_CONTINUOUS:
			case V4L2_FRMSIZE_TYPE_STEPWISE:
				frmi.width = sz.stepwise.min_width;
				frmi.height = sz.stepwise.min_height;
				break;
			default:
				log_error("unknown size type\n");
				return -1;
			}

			for ( ; cam_ioctl(impl.fd, VIDIOC_ENUM_FRAMEINTERVALS, &frmi) == 0;
					frmi.index++) {
				cam_dump_frmivalenum(&frmi);
			}
		}
	}

	memset(&fmt, 0, sizeof(fmt));
	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if ((r = cam_ioctl(impl.fd, VIDIOC_G_FMT, &fmt)) != 0) {
		log_error("VIDIOC_G_FMT, %s(%d)\n", strerror(r), r);
		return r;
	}
	cam_dump_format(&fmt);

	memset(&parm, 0, sizeof(parm));
	parm.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if ((r = cam_ioctl(impl.fd, VIDIOC_G_PARM, &parm)) != 0) {
		log_error("VIDIOC_G_PARM, %s(%d)\n", strerror(r), r);
		return r;
	}
	cam_dump_streamparm(&parm);

	return 0;
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
	close(impl.fd);
finally:
	return 0;
}
