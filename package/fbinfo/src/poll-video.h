/*
 * poll-video.h
 *
 *  Created on: May 4, 2015
 *      Author: joelai
 */

#ifndef TEST_EX2_SRC_TEST_POLL_VIDEO_H_
#define TEST_EX2_SRC_TEST_POLL_VIDEO_H_

#include <sys/queue.h>

#include <linux/videodev2.h>

#include <moss/util.h>
#include "util.h"

typedef struct ex2_video_sz_rec {
	struct v4l2_frmsizeenum val;
	fb_tailq_entry_t queue_entry;

} ex2_video_sz_t;

typedef struct ex2_video_fmt_rec {
	struct v4l2_fmtdesc val;
	int sz_cnt;
	fb_tailq_t sz_queue;
	fb_tailq_entry_t queue_entry;

} ex2_video_fmt_t;

typedef struct ex2_video_cap_rec {
	struct v4l2_capability val;
	struct v4l2_streamparm val2;
	int fmt_cnt;
	fb_tailq_t fmt_queue;
	int fd;
	char *path;

} ex2_video_cap_t;

void ex2_video_cap_free(ex2_video_cap_t *cap);
ex2_video_cap_t* ex2_video_cap(const char *path);

void ex2_video_dump_cap(struct v4l2_capability *cap);
void ex2_video_dump_fmtdesc(struct v4l2_fmtdesc *desc);
void ex2_video_dump_sz(struct v4l2_frmsizeenum *sz);

int ex2_video_format(int fd, int w, int h, int pf, struct v4l2_format *v4l2_fmt);

void ex2_video_dump_fmt(struct v4l2_format *fmt);

typedef struct ex2_video_buffer_rec {
	void *start;
	size_t len;
	int io_status;
} ex2_video_buffer_t;

typedef struct ex2_video_buffer_info_rec {
	struct v4l2_requestbuffers val;
	int stream_on;
	ex2_video_buffer_t *buf;

} ex2_video_buffer_info_t;

void ex2_video_stop(int fd, ex2_video_buffer_info_t *buf_info);
ex2_video_buffer_info_t* ex2_video_start(int fd, int buf_cnt, int io_type);

int ex2_video_read(int fd, ex2_video_buffer_info_t *buf_info,
		void (*cb)(ex2_video_buffer_t *buf, void *arg), void *arg);

#endif /* TEST_EX2_SRC_TEST_POLL_VIDEO_H_ */
