#include <event.h>
#include <moss/util.h>

#include "evb.h"

typedef struct bootstrap_rec {
	mod_t base;
	struct event *ev;
	struct event_base *evb;
} bootstrap_t;

static void bootstrap_destroy(void *arg)
{
	bootstrap_t *bootstrap = (bootstrap_t*)arg;

	log_debug("destroy %s\n", bootstrap->base.name);

	if (bootstrap->ev) event_free(bootstrap->ev);
	free(bootstrap);
}

static void bootstrap_init2(int fd, short ev, void *arg)
{
	bootstrap_t *bootstrap = (bootstrap_t*)arg;

	log_debug("run %s\n", bootstrap->base.name);
}

static int bootstrap_init(handle_t *_evb)
{
	int r = -1;
	bootstrap_t *bootstrap = NULL;
	struct timeval tv;

	if ((bootstrap = calloc(1, sizeof(*bootstrap))) == NULL) {
		log_error("alloc bootstrap\n");
		goto finally;
	}
	if ((bootstrap->evb = evb_get_base(_evb)) == NULL) {
		log_error("bootstrap get evb\n");
		goto finally;
	}
	tv.tv_sec = 0;
	tv.tv_usec = 0;
	if ((bootstrap->ev = evtimer_new(bootstrap->evb,
			&bootstrap_init2, bootstrap)) == NULL ||
			evtimer_add(bootstrap->ev, &tv) != 0) {
		log_error("bootstrap schedule init\n");
		goto finally;
	}
	snprintf(bootstrap->base.name, sizeof(bootstrap->base.name),
			"bootstrap");
	bootstrap->base.name[sizeof(bootstrap->base.name) - 1] = '\0';
	bootstrap->base.destroy = &bootstrap_destroy;
	bootstrap->base.arg = bootstrap;

	if (evb_mod_add(_evb, &bootstrap->base) == NULL) {
		log_error("bootstrap register to evb\n");
		goto finally;
	}
	r = 0;
finally:
	if (r == 0) return 0;
	if (bootstrap) {
		if (bootstrap->ev) event_free(bootstrap->ev);
		free(bootstrap);
	}
	return r;
}

int main(int argc, char **argv)
{
	int i, r = -1;
	handle_t *evb;

	for (i = 0; i < argc; i++) {
		log_debug("argv[%d/%d]: %s\n", i + 1, argc, argv[i]);
	}

	if ((evb = evb_init(argc, argv)) == NULL) {
		log_error("event base init\n");
		goto finally;
	}

	if (bootstrap_init(evb) != 0) {
		log_error("bootstrap init\n");
		goto finally;
	}

	r = evb_loop(evb);
finally:
	if (evb) evb_destroy(evb);
	log_debug("done\n");
	return 0;
}
