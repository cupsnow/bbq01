/*
 * evb.h
 *
 *  Created on: Sep 28, 2014
 *      Author: joelai
 */

#ifndef _H_WEB01_EVB
#define _H_WEB01_EVB

typedef struct handle_rec handle_t;

handle_t* evb_init(int argc, char **argv);
void evb_destroy(handle_t *evb);
int evb_loop(handle_t *evb);
void evb_break(handle_t *evb);

typedef struct mod_rec {
	char name[16];
	void (*destroy)(void *arg);
	void *arg;
} mod_t;

handle_t* evb_mod_add(handle_t *evb, const mod_t *mod);

struct event_base;
struct event_base* evb_get_base(handle_t *evb);

#endif /* _H_WEB01_EVB */
