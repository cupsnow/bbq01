/*
 * evb.c
 *
 *  Created on: Sep 28, 2014
 *      Author: joelai
 */
#include <signal.h>
#include <sys/queue.h>
#include <time.h>
#include <string.h>

#include <event.h>
#include <moss/util.h>

#include "evb.h"

typedef enum handle_type_enum {
	HANDLE_TYPE_EVB,
	HANDLE_TYPE_MOD,
} handle_type_t;

struct handle_rec {
	handle_type_t handle_type;
};

/* private for evb */
typedef struct evb_mod_rec {
	handle_t base;
	mod_t mod;
	TAILQ_ENTRY(evb_mod_rec) entry;
} evb_mod_t;

typedef TAILQ_HEAD(evb_mod_head_rec , evb_mod_rec) evb_mod_head_t;

typedef struct evb_rec {
	handle_t base;
	struct event_base *evb;
	struct event *ev_sigint;
	evb_mod_head_t mod_head;
} evb_t;

static void evb_sigint(int fd, short ev, void *arg)
{
	evb_break((handle_t*)arg);
}

handle_t* evb_init(int argc, char **argv)
{
	int r = -1;
	evb_t *evb = NULL;

	if ((evb = calloc(1, sizeof(*evb))) == NULL) {
		log_error("alloc evb\n");
		goto finally;
	}
	if ((evb->evb = event_base_new()) == NULL) {
		log_error("alloc evb\n");
		goto finally;
	}
	if ((evb->ev_sigint = evsignal_new(evb->evb, SIGINT,
			&evb_sigint, evb)) == NULL ||
			evsignal_add(evb->ev_sigint, NULL) != 0) {
		log_error("set sigint ev\n");
		goto finally;
	}
	evb->base.handle_type = HANDLE_TYPE_EVB;
	TAILQ_INIT(&evb->mod_head);
	r = 0;
finally:
	if (r == 0) return (handle_t*)evb;
	if (evb) {
		if (evb->ev_sigint) event_free(evb->ev_sigint);
		if (evb->evb) event_base_free(evb->evb);
		free(evb);
	}
	return NULL;
}

void evb_destroy(handle_t *_evb)
{
	evb_t *evb = (evb_t*)_evb;
	evb_mod_t *mod;

	while((mod = TAILQ_LAST(&evb->mod_head, evb_mod_head_rec))) {
		TAILQ_REMOVE(&evb->mod_head, mod, entry);
		if (mod->mod.destroy) (*mod->mod.destroy)(mod->mod.arg);
		free(mod);
	}
	event_free(evb->ev_sigint);
	event_base_free(evb->evb);
	free(evb);
}

int evb_loop(handle_t *_evb)
{
	evb_t *evb = (evb_t*)_evb;

	return event_base_dispatch(evb->evb);
}

void evb_break(handle_t *_evb)
{
	evb_t *evb = (evb_t*)_evb;
	struct timeval tv;

	tv.tv_sec = 0;
	tv.tv_usec = 0;
	if (event_base_loopexit(evb->evb, &tv) != 0) {
		log_error("evb loopexit\n");
		if (event_base_loopbreak(evb->evb) != 0) {
			log_error("evb loopbreak\n");
			exit(1);
		}
	}
}

handle_t* evb_mod_add(handle_t *_evb, const mod_t *_mod)
{
	evb_t *evb = (evb_t*)_evb;
	int r = -1;
	evb_mod_t *mod = NULL;

	if ((mod = calloc(1, sizeof(*mod))) == NULL) {
		log_error("alloc evb mod\n");
		goto finally;
	}
	mod->base.handle_type = HANDLE_TYPE_MOD;
	if (_mod) memcpy(&mod->mod, _mod, sizeof(*_mod));
	TAILQ_INSERT_TAIL(&evb->mod_head, mod, entry);
	r = 0;
finally:
	if (r == 0) return (handle_t*)mod;
	if (mod) {
		free(mod);
	}
	return NULL;
}

struct event_base* evb_get_base(handle_t *_evb)
{
	evb_t *evb = (evb_t*)_evb;

	return evb->evb;
}
