/*
 * poll-video.c
 *
 *  Created on: May 4, 2015
 *      Author: joelai
 */

#include <sys/types.h>
#include <sys/mman.h>
#include <time.h>
#include <fcntl.h>
#include <errno.h>

#include "poll-video.h"

static int cam_ioctl(int fd, int req, void *arg)
{
	int r = -1, cnt;

	for (cnt = 5; cnt > 0; cnt--) {
		if ((r = ioctl(fd, req, arg)) == 0 || (r = errno) != EINTR)
			break;
	}
	return r;
}

void ex2_video_dump_cap(struct v4l2_capability *cap)
{
	__u32 caps = (cap->capabilities & V4L2_CAP_DEVICE_CAPS ?
			cap->device_caps : cap->capabilities);
	char *cap_str;

	if (cap->capabilities & V4L2_CAP_DEVICE_CAPS) {
		cap_str = "device ";
		caps = cap->device_caps;
	} else {
		cap_str = "";
		caps = cap->capabilities;
	}

	log_debug("Video device capabilities:\n"
		"  bus: %s, card: %s, driver: %s, version: %u.%u.%u\n"
		"  %scapabilities: 0x%X\n"
		"    single-planar capture interface: %s\n"
		"    read/write io method: %s\n"
		"    streaming io(mmap) method: %s\n",
			cap->bus_info, cap->card, cap->driver,
			(cap->version >> 16) & 0xff, (cap->version >> 8) & 0xff,
			(cap->version >> 0) & 0xff,
			cap_str, caps,
			(caps & V4L2_CAP_VIDEO_CAPTURE ? "yes" : "no"),
			(caps & V4L2_CAP_READWRITE ? "yes" : "no"),
			(caps & V4L2_CAP_STREAMING ? "yes" : "no"));
}

void ex2_video_dump_parm(struct v4l2_streamparm *parm)
{
	log_debug("Video stream parameter: fps: %d / %d\n",
			parm->parm.capture.timeperframe.denominator,
			parm->parm.capture.timeperframe.numerator);
}

void ex2_video_dump_fmtdesc(struct v4l2_fmtdesc *desc)
{
	log_debug("Video format describe[%d]: %s\n"
			"  pixelformat: 0x%X(%c%c%c%c)\n", desc->index,
			desc->description, desc->pixelformat,
			(desc->pixelformat >> 0) & 0xff,
			(desc->pixelformat >> 8) & 0xff,
			(desc->pixelformat >> 16) & 0xff,
			(desc->pixelformat >> 24) & 0xff);
}

void ex2_video_dump_fmt(struct v4l2_format *fmt)
{
	log_debug("Video format:\n"
		"  stream: %s(%d)\n"
		"  image dimension: %d(%d bytes) x %d, size: %d, 4CC: %c%c%c%c\n"
		"  field: %s(%d)\n",
			((fmt->type == 1) ? "single-planar video capture" :
			"http://linuxtv.org/downloads/v4l-dvb-apis/buffer.html#v4l2-buf-type"),
			fmt->type, fmt->fmt.pix.width, fmt->fmt.pix.bytesperline,
			fmt->fmt.pix.height, fmt->fmt.pix.sizeimage,
			(fmt->fmt.pix.pixelformat >> 0) & 0xff,
			(fmt->fmt.pix.pixelformat >> 8) & 0xff,
			(fmt->fmt.pix.pixelformat >> 16) & 0xff,
			(fmt->fmt.pix.pixelformat >> 24) & 0xff,
			((fmt->fmt.pix.field == V4L2_FIELD_ANY) ? "Any" :
			(fmt->fmt.pix.field == V4L2_FIELD_NONE) ? "Progressive" :
			(fmt->fmt.pix.field == V4L2_FIELD_INTERLACED) ? "Interlaced" :
			"unknown"), fmt->fmt.pix.field);
}

void ex2_video_dump_sz(struct v4l2_frmsizeenum *sz)
{
	switch(sz->type) {
	case V4L2_FRMSIZE_TYPE_DISCRETE:
		log_debug("Video size[%d]: discrete, %d x %d\n",
				sz->index, sz->discrete.width,
				sz->discrete.height);
		break;
	case V4L2_FRMSIZE_TYPE_CONTINUOUS:
		sz->stepwise.step_width = sz->stepwise.step_height = 1;
	case V4L2_FRMSIZE_TYPE_STEPWISE:
		log_debug("Video size[%d]: step, [%d+%d..%d] x [%d+%d..%d]\n",
				sz->index,
				sz->stepwise.min_width,
				sz->stepwise.step_width,
				sz->stepwise.max_width,
				sz->stepwise.min_height,
				sz->stepwise.step_height,
				sz->stepwise.max_height);
		break;
	default:
		;
	}
}

void ex2_video_cap_free(ex2_video_cap_t *cap)
{
	fb_tailq_entry_t *fmt_ent, *sz_ent;
	ex2_video_fmt_t *fmt;
	ex2_video_sz_t *sz;

	while ((fmt_ent = TAILQ_FIRST(&cap->fmt_queue))) {
		TAILQ_REMOVE(&cap->fmt_queue, fmt_ent, entry);
		fmt = MOSS_CONTAINER_OF(fmt_ent, ex2_video_fmt_t, queue_entry);
		while ((sz_ent = TAILQ_FIRST(&fmt->sz_queue))) {
			TAILQ_REMOVE(&fmt->sz_queue, sz_ent, entry);
			sz = MOSS_CONTAINER_OF(sz_ent, ex2_video_sz_t, queue_entry);
			free(sz);
		}
		free(fmt);
	}
	if (cap->fd != -1) close(cap->fd);
	free(cap);
}

ex2_video_cap_t* ex2_video_cap(const char *path)
{
	int r;
	ex2_video_cap_t *cap;
	ex2_video_fmt_t *fmt;
	ex2_video_sz_t *sz;
	struct v4l2_fmtdesc v4l2_fmt;
	struct v4l2_frmsizeenum v4l2_sz;

	r = strlen(path);
	if ((cap = calloc(1, sizeof(*cap) + r + 1)) == NULL) {
		log_error("ex2 video: alloc ex2_video_cap_t\n");
		goto finally;
	}
	TAILQ_INIT(&cap->fmt_queue);
	cap->path = (char*)(cap + 1);
	memcpy(cap->path, path, r);
	cap->path[r] = '\0';
	cap->fd = -1;

	if ((cap->fd = open(path, O_RDWR | O_NONBLOCK, 0)) == -1) {
		r = errno;
		log_error("ex2 video: open %s, %s(%d)\n", path, strerror(r), r);
		goto finally;
	}

	if ((r = cam_ioctl(cap->fd, VIDIOC_QUERYCAP, &cap->val)) != 0) {
		log_error("ex2 video: VIDIOC_QUERYCAP, %s(%d)\n", strerror(r), r);
		goto finally;
	}
//	ex2_video_dump_cap(&cap->val);

	cap->val2.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if ((r = cam_ioctl(cap->fd, VIDIOC_G_PARM, &cap->val2)) != 0) {
		log_error("ex2 video: VIDIOC_G_PARM, %s(%d)\n", strerror(r), r);
		goto finally;
	}
//	ex2_video_dump_parm(&cap->val2);

	memset(&v4l2_fmt, 0, sizeof(v4l2_fmt));
	for (v4l2_fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
			(r = cam_ioctl(cap->fd, VIDIOC_ENUM_FMT, &v4l2_fmt)) == 0;
			v4l2_fmt.index++) {
//		ex2_video_dump_fmtdesc(&v4l2_fmt);

		if ((fmt = calloc(1, sizeof(*fmt))) == NULL) {
			log_error("ex2 video: alloc ex2_video_fmt_t\n");
			goto finally;
		}
		TAILQ_INIT(&fmt->sz_queue);
		TAILQ_INSERT_TAIL(&cap->fmt_queue, &fmt->queue_entry, entry);
		cap->fmt_cnt++;
		memcpy(&fmt->val, &v4l2_fmt, sizeof(v4l2_fmt));

		memset(&v4l2_sz, 0, sizeof(v4l2_sz));
		for (v4l2_sz.pixel_format = v4l2_fmt.pixelformat;
				(r = cam_ioctl(cap->fd, VIDIOC_ENUM_FRAMESIZES,
						&v4l2_sz)) == 0;
				v4l2_sz.index++) {
//			ex2_video_dump_sz(&v4l2_sz);

			if ((sz = calloc(1, sizeof(*sz))) == NULL) {
				log_error("ex2 video: alloc ex2_video_sz_t\n");
				goto finally;
			}
			TAILQ_INSERT_TAIL(&fmt->sz_queue, &sz->queue_entry, entry);
			fmt->sz_cnt++;
			memcpy(&sz->val, &v4l2_sz, sizeof(v4l2_sz));
		}
		if (fmt->sz_cnt <= 0) {
			r = EIO;
			goto finally;
		}
	}
	if (cap->fmt_cnt <= 0) {
		r = EIO;
		goto finally;
	}
	r = 0;
finally:
	if (r == 0) return cap;
	if (cap != NULL) ex2_video_cap_free(cap);
	return NULL;
}

static int ex2_video_crop(int fd)
{
	struct v4l2_cropcap v4l2_cap;
	struct v4l2_crop v4l2_crop;
	int r;

	memset(&v4l2_cap, 0, sizeof(v4l2_cap));
	v4l2_cap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if ((r = cam_ioctl(fd, VIDIOC_CROPCAP, &v4l2_cap)) != 0) {
		if (r == ENOTTY) {
			log_debug("ex2 video: ignore cropping\n");
			return r;
		}
		log_error("ex2 video: VIDIOC_CROPCAP, %s(%d)\n", strerror(r), r);
		return r;
	}

	memset(&v4l2_crop, 0, sizeof(v4l2_crop));
	v4l2_crop.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	v4l2_crop.c = v4l2_cap.defrect;
	if ((r = cam_ioctl(fd, VIDIOC_S_CROP, &v4l2_crop)) != 0) {
		log_error("ex2 video: VIDIOC_S_CROP, %s(%d)\n", strerror(r), r);
		return r;
	}
	return 0;
}

int ex2_video_format(int fd, int w, int h, int pf, struct v4l2_format *v4l2_fmt)
{
	int r;
	struct v4l2_format _v4l2_fmt;

	if (!v4l2_fmt) v4l2_fmt = &_v4l2_fmt;
	if ((r = ex2_video_crop(fd)) != 0 && r != ENOTTY) {
		log_error("ex2 video: cropping\n");
		goto finally;
	}

	memset(v4l2_fmt, 0, sizeof(*v4l2_fmt));
	v4l2_fmt->type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if ((r = cam_ioctl(fd, VIDIOC_G_FMT, v4l2_fmt)) != 0) {
		log_error("ex2 video: VIDIOC_G_FMT, %s(%d)\n", strerror(r), r);
		goto finally;
	}

	v4l2_fmt->fmt.pix.width = w;
	v4l2_fmt->fmt.pix.height = h;
	v4l2_fmt->fmt.pix.pixelformat = pf;
	if ((r = cam_ioctl(fd, VIDIOC_S_FMT, v4l2_fmt)) != 0) {
		log_error("ex2 video: VIDIOC_S_FMT, %s(%d)\n", strerror(r), r);
		goto finally;
	}

	memset(v4l2_fmt, 0, sizeof(*v4l2_fmt));
	v4l2_fmt->type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if ((r = cam_ioctl(fd, VIDIOC_G_FMT, v4l2_fmt)) != 0) {
		log_error("ex2 video: VIDIOC_G_FMT, %s(%d)\n", strerror(r), r);
		goto finally;
	}
//	ex2_video_dump_fmt(&v4l2_fmt);
	r = 0;
finally:
	return r;
}

ex2_video_buffer_info_t* ex2_video_start(int fd, int buf_cnt, int io_type)
{
	int r, i;
	struct v4l2_requestbuffers v4l2_bufreq;
	struct v4l2_buffer v4l2_buf;
	ex2_video_buffer_info_t *buf_info = NULL;
	enum v4l2_buf_type v4l2_type;

	switch(io_type) {
	case V4L2_MEMORY_MMAP:
		memset(&v4l2_bufreq, 0, sizeof(v4l2_bufreq));
		v4l2_bufreq.count = buf_cnt;
		v4l2_bufreq.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		v4l2_bufreq.memory = io_type;
		if ((r = cam_ioctl(fd, VIDIOC_REQBUFS, &v4l2_bufreq)) != 0) {
			log_error("ex2 video: VIDIOC_REQBUFS: %s(%d)\n",
					strerror(r), r);
			goto finally;
		}
		if (v4l2_bufreq.count < buf_cnt) {
			log_error("ex2 video: buffer not enough %d < %d\n",
					v4l2_bufreq.count, buf_cnt);
			r = EINVAL;
			goto finally;
		}
		if ((buf_info = calloc(1, sizeof(*buf_info) +
				sizeof(*buf_info->buf) * v4l2_bufreq.count)) ==
						NULL) {
			log_error("ex2 video: alloc ex2_video_buffer_info_t\n");
			r = ENOMEM;
			goto finally;
		}
		memcpy(&buf_info->val, &v4l2_bufreq, sizeof(v4l2_bufreq));
		buf_info->buf = (ex2_video_buffer_t*)(buf_info + 1);
		for (i = 0; i < buf_info->val.count; i++) {
		        memset(&v4l2_buf, 0, sizeof(v4l2_buf));
		        v4l2_buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		        v4l2_buf.memory = buf_info->val.memory;
		        v4l2_buf.index = i;
			if ((r = cam_ioctl(fd, VIDIOC_QUERYBUF, &v4l2_buf)) != 0) {
				log_error("ex2 video: VIDIOC_QUERYBUF mmap, %s(%d)\n", strerror(r), r);
				goto finally;
			}
			buf_info->buf[i].len = v4l2_buf.length;
			if ((buf_info->buf[i].start = mmap(NULL,
					buf_info->buf[i].len,
					PROT_READ | PROT_WRITE, MAP_SHARED,
					fd, v4l2_buf.m.offset)) == MAP_FAILED) {
				r = errno;
				log_error("ex2 video: mmap, %s(%d)\n", strerror(r), r);
				buf_info->buf[i].start = NULL;
				goto finally;
			}
		}

		for (i = 0; i < buf_info->val.count; i++) {
		        memset(&v4l2_buf, 0, sizeof(v4l2_buf));
		        v4l2_buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		        v4l2_buf.memory = buf_info->val.memory;
		        v4l2_buf.index = i;
			if ((r = cam_ioctl(fd, VIDIOC_QBUF, &v4l2_buf)) != 0) {
				log_error("ex2 video: VIDIOC_QBUF, %s(%d)\n", strerror(r), r);
				goto finally;
			}
			buf_info->buf[i].io_status = V4L2_BUF_FLAG_QUEUED;
		}
		v4l2_type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		if ((r = cam_ioctl(fd, VIDIOC_STREAMON, &v4l2_type)) != 0) {
			log_error("ex2 video: VIDIOC_STREAMON, %s(%d)\n", strerror(r), r);
			goto finally;
		}
		buf_info->stream_on = VIDIOC_STREAMON;
		break;
	default:
		log_error("ex2 video: unsupport io method\n");
		r = EINVAL;
		goto finally;
	}

	r = 0;
finally:
	if (r == 0) return buf_info;
	if (buf_info) ex2_video_stop(fd, buf_info);
	return NULL;
}

void ex2_video_stop(int fd, ex2_video_buffer_info_t *buf_info)
{
	int r, i;
	struct v4l2_requestbuffers v4l2_bufreq;
	enum v4l2_buf_type v4l2_type;

	switch(buf_info->val.memory) {
	case V4L2_MEMORY_MMAP:
		if (buf_info->stream_on) {
			v4l2_type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
			if ((r = cam_ioctl(fd, VIDIOC_STREAMOFF, &v4l2_type)) != 0) {
				log_error("ex2 video: VIDIOC_STREAMOFF, %s(%d)\n",
						strerror(r), r);
			}
		}
		for (i = 0; i < buf_info->val.count; i++) {
			if (buf_info->buf[i].start) {
				munmap(buf_info->buf[i].start, buf_info->buf[i].len);
			}
		}
		break;
	default:
		log_error("ex2 video: unsupport io method\n");
	}
	v4l2_bufreq.count = 0;
	v4l2_bufreq.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	v4l2_bufreq.memory = buf_info->val.memory;
	if ((r = cam_ioctl(fd, VIDIOC_REQBUFS, &v4l2_bufreq)) != 0) {
		log_error("ex2 video: VIDIOC_REQBUFS: %s(%d)\n",
				strerror(r), r);
	}
	free(buf_info);
}

int ex2_video_read(int fd, ex2_video_buffer_info_t *buf_info,
		void (*cb)(ex2_video_buffer_t *buf, void *arg), void *arg)
{
	int r;
	struct v4l2_buffer v4l2_buf;

	switch(buf_info->val.memory) {
	case V4L2_MEMORY_MMAP:
		memset(&v4l2_buf, 0, sizeof(v4l2_buf));
		v4l2_buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		v4l2_buf.memory = buf_info->val.memory;
		if ((r = cam_ioctl(fd, VIDIOC_DQBUF, &v4l2_buf)) != 0) {
			if ((r = errno) != EAGAIN) {
				log_error("read video: %s(%d)\n", strerror(r), r);
			}
			return r;
		}
		if (v4l2_buf.index >= buf_info->val.count) {
			log_error("ex2 video: out of range\n");
			return EIO;
		}
		if (cb) cb(&buf_info->buf[v4l2_buf.index], arg);
		if ((r = cam_ioctl(fd, VIDIOC_QBUF, &v4l2_buf)) != 0) {
			log_error("ex2 video: VIDIOC_QBUF, %s(%d)\n", strerror(r), r);
			return r;
		}
		return 0;
	default:
		log_error("ex2 video: unsupport io method\n");
		return EINVAL;
	}
}
