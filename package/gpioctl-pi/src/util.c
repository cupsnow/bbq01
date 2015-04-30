
#include "util.h"

char* moss_stripr(char *s)
{
	int len = s ? strlen(s) : 0;

	while(--len >= 0 && isspace(s[len]));
	if (s) s[len + 1] = '\0';
	return s;
}

int moss_file_mode(const char *path)
{
	struct stat st;

	if (stat(path, &st) != 0) return 0;
	return st.st_mode;
}

void moss_tv_norm(struct timeval *tv)
{
	if (!tv || tv->tv_usec < 1000000) return;
	tv->tv_sec += tv->tv_usec / 1000000;
	tv->tv_usec %= 1000000;
}

/* !!a - !!b */
int moss_tv_cmp(struct timeval *a, struct timeval *b)
{
	if (a->tv_sec > b->tv_sec) return 1;
	if (a->tv_sec < b->tv_sec) return -1;
	if (a->tv_usec > b->tv_usec) return 1;
	if (a->tv_usec < b->tv_usec) return -1;
	return 0;
}

/* c = a - b */
void moss_tv_sub(struct timeval *a, struct timeval *b, struct timeval *c)
{
	if (moss_tv_cmp(a, b) <= 0) {
		MOSS_TV_SET(c, 0, 0);
		return;
	}

	if (a->tv_usec < b->tv_usec) {
		MOSS_TV_SET(c, a->tv_sec - b->tv_sec - 1,
				1000000 + a->tv_usec - b->tv_usec);
		return;
	}
	MOSS_TV_SET(c, a->tv_sec - b->tv_sec,
			a->tv_usec - b->tv_usec);
}

static int moss_rb_cmp(moss_rb_entry_t *a, moss_rb_entry_t *b)
{
	return a - b;
}

RB_GENERATE(moss_rb_tree_rec, moss_rb_entry_rec, entry, moss_rb_cmp)

struct moss_ev_rec {
	moss_rb_entry_t req_entry, act_entry;
	unsigned req, act;
	int fd;
	moss_ev_cb_t cb;
	void *arg;
	struct timeval *tp, _tp;

};

struct moss_evm_rec {
	moss_rb_tree_t req_tree, act_tree;

};

int moss_ev_poll_timeout(moss_ev_t *ev, struct timeval *tv)
{
	int r;

	ev->tp = NULL;
	if (!tv) return 0;
	moss_tv_norm(tv);
	if (gettimeofday(&ev->_tp, NULL) != 0) {
		r = errno;
		log_error("ev: gettimeofday, %s(%d)\n", strerror(r), r);
		return r;
	}
	ev->_tp.tv_sec += tv->tv_sec;
	ev->_tp.tv_usec += tv->tv_usec;
	moss_tv_norm(&ev->_tp);
	ev->tp = &ev->_tp;
	return 0;
}

void moss_ev_poll_require(moss_ev_t *ev, unsigned req)
{
	ev->req = req;
}

void moss_ev_poll_init(moss_ev_t *ev, int fd, unsigned req, moss_ev_cb_t cb, void *arg)
{
	ev->fd = fd;
	ev->cb = *cb;
	ev->arg = arg;
	moss_ev_poll_require(ev, req);
}

moss_ev_t* moss_ev_poll_alloc(int fd, unsigned req, moss_ev_cb_t cb, void *arg)
{
	moss_ev_t *ev;

	if ((ev = calloc(1, sizeof(*ev))) == NULL) {
		log_error("ev: alloc\n");
		return NULL;
	}
	moss_ev_poll_init(ev, fd, req, cb, arg);
	return ev;
}

void moss_evm_poll_rm(moss_evm_t *evm, moss_ev_t *ev)
{
	if (RB_FIND(moss_rb_tree_rec, &evm->req_tree, &ev->req_entry)) {
		RB_REMOVE(moss_rb_tree_rec, &evm->req_tree, &ev->req_entry);
	}
	if (RB_FIND(moss_rb_tree_rec, &evm->act_tree, &ev->act_entry)) {
		RB_REMOVE(moss_rb_tree_rec, &evm->act_tree, &ev->act_entry);
	}
}

void moss_evm_poll_add(moss_evm_t *evm, moss_ev_t *ev)
{
	if (!RB_FIND(moss_rb_tree_rec, &evm->req_tree, &ev->req_entry)) {
		RB_INSERT(moss_rb_tree_rec, &evm->req_tree, &ev->req_entry);
	}
}

int moss_evm_poll_run(moss_evm_t *evm)
{
#define EV_ACT_ALL (MOSS_EV_ACT_RD | MOSS_EV_ACT_WR | MOSS_EV_ACT_EX | MOSS_EV_ACT_TM)
	int r, fdnum;
	moss_rb_entry_t *entry;
	moss_ev_t *ev;
	fd_set rdset, wrset, exset;
	struct timeval tp, _tv, *tv;

	FD_ZERO(&rdset); FD_ZERO(&wrset); FD_ZERO(&exset);
	ev = NULL;
	tv = NULL;
	fdnum = -1;
	RB_FOREACH(entry, moss_rb_tree_rec, &evm->req_tree) {
		ev = MOSS_CONTAINER_OF(entry, moss_ev_t, req_entry);
		if (ev->fd != -1) {
			if (ev->req & MOSS_EV_ACT_RD) FD_SET(ev->fd, &rdset);
			if (ev->req & MOSS_EV_ACT_WR) FD_SET(ev->fd, &wrset);
			if (ev->req & MOSS_EV_ACT_EX) FD_SET(ev->fd, &exset);
			if (ev->fd > fdnum) fdnum = ev->fd;
		}

		if (ev->tp && (!tv || moss_tv_cmp(ev->tp, tv) < 0)) {
			tv = ev->tp;
		}
	}
	if (ev == NULL) return 0;
	if (tv) {
		if (gettimeofday(&tp, NULL) != 0) {
			r = errno;
			log_error("ev: gettimeofday, %s(%d)\n", strerror(r), r);
			return r;
		}
		moss_tv_sub(tv, &tp, &_tv);
		tv = &_tv;
	}

	if ((r = select(fdnum + 1, &rdset, &wrset, &exset, tv)) == -1) {
		r = errno;
		log_error("evm: select, %s(%d)\n", strerror(r), r);
		return r;
	}
	fdnum = r;
	if (tv && gettimeofday(&tp, NULL) != 0) {
		r = errno;
		log_error("ev: gettimeofday, %s(%d)\n", strerror(r), r);
		return r;
	}
	RB_FOREACH(entry, moss_rb_tree_rec, &evm->req_tree) {
		ev = MOSS_CONTAINER_OF(entry, moss_ev_t, req_entry);
		ev->act &= (~EV_ACT_ALL);
		if (fdnum > 0 && ev->fd != -1) {
			if (FD_ISSET(ev->fd, &exset)) {
				ev->act |= MOSS_EV_ACT_EX;
				fdnum--;
			}
			if (FD_ISSET(ev->fd, &rdset)) {
				ev->act |= MOSS_EV_ACT_RD;
				fdnum--;
			}
			if (FD_ISSET(ev->fd, &wrset)) {
				ev->act |= MOSS_EV_ACT_WR;
				fdnum--;
			}
		}
		if (ev->tp) {
			if (ev->act) {
				ev->tp = NULL;
			} else if (moss_tv_cmp(ev->tp, &tp) <= 0) {
				ev->tp = NULL;
				ev->act |= MOSS_EV_ACT_TM;
			}
		}
		if (ev->act & EV_ACT_ALL) {
			RB_INSERT(moss_rb_tree_rec, &evm->act_tree, &ev->act_entry);
		}
	}
	while((entry = RB_MIN(moss_rb_tree_rec, &evm->act_tree))) {
		ev = MOSS_CONTAINER_OF(entry, moss_ev_t, act_entry);
		RB_REMOVE(moss_rb_tree_rec, &evm->act_tree, &ev->act_entry);
		(ev->cb)(ev, ev->act, ev->arg);
	}
	return 0;
}

int moss_evm_poll_loop(moss_evm_t *evm)
{
	int r;

	while((r = moss_evm_poll_run(evm) == 0)) ;
	return r;
}

void moss_evm_poll_init(moss_evm_t *evm)
{
	RB_INIT(&evm->req_tree);
	RB_INIT(&evm->act_tree);
}

moss_evm_t* moss_evm_poll_alloc()
{
	moss_evm_t *evm;

	if ((evm = calloc(1, sizeof(*evm))) == NULL) {
		log_error("evm: alloc\n");
		return NULL;
	}
	moss_evm_poll_init(evm);
	return evm;
}
