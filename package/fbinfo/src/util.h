/*
 * util.h
 *
 *  Created on: Jun 8, 2015
 *      Author: joelai
 */

#ifndef _H_FBINFO_UTIL
#define _H_FBINFO_UTIL

typedef struct fb_tailq_entry_rec {
	TAILQ_ENTRY(fb_tailq_entry_rec) entry;
} fb_tailq_entry_t;
typedef TAILQ_HEAD(fb_tailq_rec, fb_tailq_entry_rec) fb_tailq_t;


#endif /* _H_FBINFO_UTIL */
