/*
 * main.c
 *
 *  Created on: Jun 8, 2015
 *      Author: joelai
 */

#include <sys/mman.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/queue.h>
#include <sys/tree.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <time.h>
#include <fcntl.h>
#include <errno.h>

#include <linux/fb.h>

#include <moss/net.h>
#include <moss/util.h>

#include "poll-video.h"

#define FBDEV_PATH "/dev/fb0"
#define CAPDEV_PATH "/dev/video0"

static struct {
	moss_evm_t *evm;

	struct {
		ex2_video_cap_t *dev;
		ex2_video_buffer_info_t *buf_info;
		moss_ev_t *ev;

		int w, h, fps, bitrate, v4l2_pf;
		void *sws;
		void (*video_dispatch)(void *start, size_t sz);
	} cap;

	struct {
		int fd;
		struct fb_var_screeninfo vinfo;
		struct fb_fix_screeninfo finfo;
		char *mm;
	} fb;
} impl = {NULL};

static void fb_draw_video(void *start, size_t sz)
{
	int x, y, fx, vx;
	unsigned short *fb;
	char *cap;

	/* fb          cap
	 * R5 G6 G5 <- R8 G8 B8
	 */

//	log_debug("receive %d x %d, %zd bytes\n", impl.cap.w, impl.cap.h, sz);
	fb = (unsigned short*)impl.fb.mm; cap = (char*)start;
	for (y = 0; y < impl.cap.h; y++) {
		fx = vx = 0;
		for (x = 0; x < impl.cap.w; x++) {
//			fb[fx++] = 0x1f << 11;
			fb[fx++] =
				((cap[vx++] << 8) & 0xf800) |
				((cap[vx++] << 3) & 0x07e0) |
				((cap[vx++] >> 3) & 0x001f);
		}
		fb += impl.fb.vinfo.xres;
		cap += (impl.cap.w * 3);
	}

finally:
	return;
}

static void cap_data(ex2_video_buffer_t *buf, void *arg)
{
	void *out;
	size_t sz;

	if (impl.cap.v4l2_pf == V4L2_PIX_FMT_RGB24) {
		if (impl.cap.video_dispatch) {
			impl.cap.video_dispatch(buf->start, buf->len);
		}
	} else {
		log_error("video service: unsupport pixelformat\n");
		return;
	}
}

static void cap_read(moss_ev_t *ev, unsigned act, void *arg)
{
	if (!(act & MOSS_EV_ACT_RD)) {
		log_error("video service: act: 0x%X\n", act);
		return;
	}
	if (act & MOSS_EV_ACT_EX) {
		log_debug("video service: ignore oob\n");
		return;
	}

	if (ex2_video_read(impl.cap.dev->fd, impl.cap.buf_info,
			&cap_data, arg) != 0) {
		log_error("video service: read capture\n");
		return;
	}
	return;
}

static void cap_deinit(void)
{

}

static ex2_video_cap_t* cap_init(const char *dev)
{
	int r = EIO;
	ex2_video_fmt_t *fmt;
	ex2_video_sz_t *sz;
	fb_tailq_entry_t *fmt_ent, *sz_ent;
	struct v4l2_format v4l2_fmt;

	if ((impl.cap.dev = ex2_video_cap(CAPDEV_PATH)) == NULL) {
		r = EIO;
		log_error("video service: open video\n");
		goto finally;
	}
//	ex2_video_dump_cap(&impl.cap.dev->val);
//	ex2_video_dump_parm(&impl.cap.dev->val2);
//	TAILQ_FOREACH(fmt_ent, &impl.cap.dev->fmt_queue, entry) {
//		fmt = MOSS_CONTAINER_OF(fmt_ent,
//				ex2_video_fmt_t, queue_entry);
//		ex2_video_dump_fmtdesc(&fmt->val);
//		TAILQ_FOREACH(sz_ent, &fmt->sz_queue, entry) {
//			sz = MOSS_CONTAINER_OF(sz_ent,
//					ex2_video_sz_t, queue_entry);
//			ex2_video_dump_sz(&sz->val);
//		}
//	}

	impl.cap.w = MOSS_MIN(1920, impl.fb.vinfo.xres);
	impl.cap.h = MOSS_MIN(1080, impl.fb.vinfo.yres);
	impl.cap.fps = (impl.cap.dev->val2.parm.capture.timeperframe.denominator +
			impl.cap.dev->val2.parm.capture.timeperframe.numerator - 1) /
			impl.cap.dev->val2.parm.capture.timeperframe.numerator;
	impl.cap.bitrate = 1000 * 1000 * 1;
	impl.cap.v4l2_pf = V4L2_PIX_FMT_RGB24;

	if ((impl.cap.sws = malloc(impl.cap.w * impl.cap.h * 2)) == NULL) {
		log_error("video service: alloc scaler\n");
		goto finally;
	}

	if (ex2_video_format(impl.cap.dev->fd,
			impl.cap.w, impl.cap.h,
			impl.cap.v4l2_pf, &v4l2_fmt) != 0) {
		log_error("video service: set video format\n");
		goto finally;
	}

	if ((impl.cap.buf_info = ex2_video_start(impl.cap.dev->fd,
			2, V4L2_MEMORY_MMAP)) == NULL) {
		log_error("video service: start video\n");
		goto finally;
	}

	if ((impl.cap.ev = moss_ev_poll_alloc(impl.cap.dev->fd,
			MOSS_EV_ACT_RD,
			&cap_read, &impl.cap)) == NULL) {
		log_error("video service: create ev to capture\n");
		goto finally;
	}
	moss_evm_poll_add(impl.evm, impl.cap.ev);

	r = 0;
finally:
	if (r == 0) return impl.cap.dev;
	if (impl.cap.dev) {
		ex2_video_cap_free(impl.cap.dev);
		impl.cap.dev = NULL;
	}
	return NULL;
}

static void fb_deinit(void)
{
	if (impl.fb.mm) munmap(impl.fb.mm, impl.fb.finfo.smem_len);
	if (impl.fb.fd != -1) {
		close(impl.fb.fd);
		impl.fb.fd = -1;
	}
}

static int fb_init(const char *dev)
{
	int r, screensize;

	if ((impl.fb.fd = open(dev, O_RDWR)) == -1) {
		r = errno;
		log_error("open %s: %s(%d)\n", dev, strerror(r), r);
		goto finally;
	}
	if (ioctl(impl.fb.fd, FBIOGET_FSCREENINFO, &impl.fb.finfo) != 0) {
		r = errno;
		log_error("get fb info: %s(%d)\n", strerror(r), r);
		goto finally;
	}
	if (ioctl(impl.fb.fd, FBIOGET_VSCREENINFO, &impl.fb.vinfo) != 0) {
		r = errno;
		log_error("get fb screen info: %s(%d)\n", strerror(r), r);
		goto finally;
	}

	screensize = impl.fb.finfo.smem_len;
	log_debug("fb, %dx%d, %d bpp(screen size: %d)\n",
			impl.fb.vinfo.xres, impl.fb.vinfo.yres,
			impl.fb.vinfo.bits_per_pixel,
			screensize);

	if ((impl.fb.mm = (char*)mmap(0, screensize, PROT_READ | PROT_WRITE,
			MAP_SHARED, impl.fb.fd, 0)) == MAP_FAILED) {
		r = errno;
		log_error("mmap fb: %s(%d)\n", strerror(r), r);
		goto finally;
	}
	memset(impl.fb.mm, 0xff, screensize / 2);
	memset(impl.fb.mm + screensize / 2, 0x18, screensize / 2);
	r = 0;
finally:
	if (r == 0) return impl.fb.fd;
	fb_deinit();
	return -1;
}

int main(int argc, char* argv[])
{
	int r;
	int fbfd = 0;
	struct fb_var_screeninfo vinfo;
	struct fb_fix_screeninfo finfo;
	long int screensize = 0;
	char *fbp = 0;

	memset(&impl, 0, sizeof(impl));

	if ((impl.evm = moss_evm_poll_alloc()) == NULL) {
		log_error("evm: alloc\n");
		goto finally;
	}

	if ((impl.fb.fd = fb_init(FBDEV_PATH)) == -1) {
		r = EIO;
		log_error("open fb\n");
		goto finally;
	}

	if ((impl.cap.dev = cap_init(CAPDEV_PATH)) == NULL) {
		r = EIO;
		log_error("open cap\n");
		goto finally;
	}

	impl.cap.video_dispatch = &fb_draw_video;

	if (moss_evm_poll_loop(impl.evm) != 0) {
		log_error("evm: loop\n");
		goto finally;
	}
finally:
	cap_deinit();
	fb_deinit();
	if (impl.evm) moss_evm_poll_free(impl.evm);
	return 0;
}
