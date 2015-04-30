
#ifndef _H_GPIOCTL_UTIL
#define _H_GPIOCTL_UTIL

#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sys/tree.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <stdarg.h>
#include <stddef.h>
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

#define MOSS_CONTAINER_OF(_obj, _type, _member) \
	((_obj) ? (_type *)((char*)(_obj) - offsetof(_type, _member)) : NULL)
#define MOSS_FILE_MODE_DIR(_path) S_ISDIR(moss_file_mode(_path))
#define MOSS_XOR(_a, _b) (!!(_a) ^ !!(_b))

#ifdef __cplusplus
#define extern "C" {
#endif

char* moss_stripr(char *s);

int moss_file_mode(const char *path);

#define MOSS_TV_SET(_t, _s, _u) do { \
	(_t)->tv_sec = (_s); (_t)->tv_usec = (_u); \
} while(0)
void moss_tv_norm(struct timeval *tv);
int moss_tv_cmp(struct timeval *a, struct timeval *b);
void moss_tv_sub(struct timeval *a, struct timeval *b, struct timeval *c);

typedef struct moss_rb_entry_rec {
	RB_ENTRY(moss_rb_entry_rec) entry;
} moss_rb_entry_t;
typedef RB_HEAD(moss_rb_tree_rec, moss_rb_entry_rec) moss_rb_tree_t;
RB_PROTOTYPE(moss_rb_tree_rec, moss_rb_entry_rec, entry, );

typedef enum moss_ev_act_enum {
	MOSS_EV_ACT_RD = (1 << 0),
	MOSS_EV_ACT_WR = (1 << 1),
	MOSS_EV_ACT_EX = (1 << 2),
	MOSS_EV_ACT_TM = (1 << 3),
} moss_ev_act_t;

typedef struct moss_ev_rec moss_ev_t;
typedef void (*moss_ev_cb_t)(moss_ev_t *ev, unsigned act, void *arg);

typedef struct moss_evm_rec moss_evm_t;

int moss_ev_poll_timeout(moss_ev_t *ev, struct timeval *tv);
void moss_ev_poll_require(moss_ev_t *ev, unsigned req);
void moss_ev_poll_init(moss_ev_t *ev, int fd, unsigned req, moss_ev_cb_t cb, void *arg);
moss_ev_t* moss_ev_poll_alloc(int fd, unsigned req, moss_ev_cb_t cb, void *arg);
void moss_evm_poll_rm(moss_evm_t *evm, moss_ev_t *ev);
void moss_evm_poll_add(moss_evm_t *evm, moss_ev_t *ev);
int moss_evm_poll_run(moss_evm_t *evm);
int moss_evm_poll_loop(moss_evm_t *evm);
void moss_evm_poll_init(moss_evm_t *evm);
moss_evm_t* moss_evm_poll_alloc();

#ifdef __cplusplus
} // #define extern "C"
#endif

#endif /* _H_GPIOCTL_UTIL */
