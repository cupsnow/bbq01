/*
 * main.c
 *
 *  Created on: May 2, 2016
 *      Author: joelai
 */


#include <linux/fb.h>
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

#include <moss/util.h>

inline uint32_t pixel_color(uint8_t r, uint8_t g, uint8_t b, struct fb_var_screeninfo *vinfo)
{
	return (r<<vinfo->red.offset) | (g<<vinfo->green.offset) | (b<<vinfo->blue.offset);
}

int main(int argc, char **argv)
{
	struct fb_fix_screeninfo finfo;
	struct fb_var_screeninfo vinfo;
	int r, fb_fd = -1;

	if ((fb_fd = open("/dev/fb0",O_RDWR)) < 0) {
		r = errno;
		log_error("open fb: %s(%d)\n", strerror(r), r);
		goto finally;
	}

	//Get variable screen information
	if ((ioctl(fb_fd, FBIOGET_VSCREENINFO, &vinfo)) != 0) {
		r = errno;
		log_error("FBIOGET_VSCREENINFO: %s(%d)\n", strerror(r), r);
		goto finally;
	}
	vinfo.grayscale=0;
	vinfo.bits_per_pixel=32;
	ioctl(fb_fd, FBIOPUT_VSCREENINFO, &vinfo);
	ioctl(fb_fd, FBIOGET_VSCREENINFO, &vinfo);
	ioctl(fb_fd, FBIOGET_FSCREENINFO, &finfo);
	long screensize = vinfo.yres_virtual * finfo.line_length;
	log_debug("fb alloc: %d x %d, %d\n", vinfo.xres, vinfo.yres, screensize);

	uint8_t *fbp = mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fb_fd, (off_t)0);

	int x,y, cl = 0x00ff00ff;

	if (argc > 1) {
		 cl = strtol(argv[1], NULL, 0);
	}

	log_debug("set color: 0x%x\n", cl);

	for (x=0;x<vinfo.xres;x++)
		for (y=0;y<vinfo.yres;y++)
		{
			long location = (x+vinfo.xoffset) * (vinfo.bits_per_pixel/8) + (y+vinfo.yoffset) * finfo.line_length;
			*((uint32_t*)(fbp + location)) = pixel_color(
					(cl & 0xff), (cl >> 8) & 0xff, (cl >> 16) & 0xff, &vinfo);
		}
finally:
	if (fb_fd != -1) close(fb_fd);
	return 0;
}

