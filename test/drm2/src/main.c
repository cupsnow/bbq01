/*
 * main.c
 *
 *  Created on: Mar 4, 2016
 *      Author: joelai
 */

#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

#include <xf86drm.h>
#include <xf86drmMode.h>

#include <gbm.h>

#include <GLES2/gl2.h>

#include <EGL/egl.h>
#include <EGL/eglext.h>

#include <moss/util.h>

#define DRIFILE "/dev/dri/card0"

static struct {
	void *evm;
	int fd;

    drmModeRes *drm_res;
    drmModeConnector *drm_conn;
    drmModeEncoder *drm_enc;
    drmModeModeInfo *drm_mode;
    uint32_t drm_fb;

	struct gbm_device *gbm;
    struct gbm_bo *gbm_bo;
    uint32_t gbm_handle, gbm_stride;

	EGLDisplay disp;
	EGLContext ctx;
	GLuint fb, color_rb, depth_rb;
	EGLImageKHR img;


} impl = {0};

int main()
{
	int i;

	memset(&impl, 0, sizeof(impl));
	impl.fd = -1;

	if ((impl.fd = open(DRIFILE, O_RDWR)) == -1) {
		log_error("open %s\n", DRIFILE);
		goto finally;
	}
	if ((impl.gbm = gbm_create_device(impl.fd)) == NULL) {
		log_error("gbm_create_device\n");
		goto finally;
	}
	if ((impl.disp = eglGetDisplay(impl.gbm)) == NULL) {
		log_error("eglGetDisplay\n");
		goto finally;
	}
	{
		EGLint major, minor;
		const char *ver, *extensions;

		eglInitialize(impl.disp, &major, &minor);
		if ((ver = eglQueryString(impl.disp, EGL_VERSION)) == NULL) {
			log_error("eglQueryString EGL_VERSION\n");
			goto finally;
		}
		if ((extensions = eglQueryString(impl.disp, EGL_EXTENSIONS)) == NULL) {
			log_error("eglQueryString EGL_EXTENSIONS\n");
			goto finally;
		}
		log_debug("egl ver: %s\n"
				"egl ext: %s\n", ver, extensions);
	}

    if ((impl.drm_res = drmModeGetResources(impl.fd)) == NULL) {
    	log_error("drmModeGetResources\n");
        goto finally;
    }
    log_debug("drm count crtc: %d, conn: %d, enc: %d\n",
    		impl.drm_res->count_crtcs, impl.drm_res->count_connectors,
			impl.drm_res->count_encoders);


    for (i = 0; i < impl.drm_res->count_connectors; i++) {
    	drmModeConnector *drm_conn;
        if ((drm_conn = drmModeGetConnector(impl.fd,
        		impl.drm_res->connectors[i])) == NULL) {
            continue;
        }

        if (drm_conn->connection == DRM_MODE_CONNECTED &&
        		drm_conn->count_modes > 0) {
        	impl.drm_conn = drm_conn;
        	break;
        }
        drmModeFreeConnector(impl.drm_conn);
    }
    if (!impl.drm_conn) {
    	log_error("No currently active connector found.\n");
        goto finally;
    }

    log_debug("drm use conn%d, count modes: %d\n", i,
    		impl.drm_conn->count_modes);

    for (i = 0; i < impl.drm_res->count_encoders; i++) {
    	drmModeEncoder *drm_enc;
        if ((drm_enc = drmModeGetEncoder(impl.fd,
        		impl.drm_res->encoders[i])) == NULL) {
        	continue;
        }
        if (drm_enc->encoder_id == impl.drm_conn->encoder_id) {
        	impl.drm_enc = drm_enc;
        	break;
        }
        drmModeFreeEncoder(drm_enc);
    }

    if (!impl.drm_enc) {
    	log_error("No currently active encoder found.\n");
        goto finally;
    }

    log_debug("drm use enc%d, crtc_id: %d\n", i, impl.drm_enc->crtc_id);

    for (i = 0; i < impl.drm_conn->count_modes; i++) {
        log_debug("drm mode[%d]: %d x %d\n", i,
        		(int)impl.drm_conn->modes[i].hdisplay,
				(int)impl.drm_conn->modes[i].vdisplay);
    }
    impl.drm_mode = &impl.drm_conn->modes[0];

    EGLContext ctx;

    eglBindAPI(EGL_OPENGL_API);
    if ((impl.ctx = eglCreateContext(impl.disp, NULL, EGL_NO_CONTEXT, NULL)) == NULL) {
    	log_error("eglCreateContext\n");
    	goto finally;
    }
    eglMakeCurrent(impl.disp, EGL_NO_SURFACE, EGL_NO_SURFACE, impl.ctx);

    if ((impl.gbm_bo = gbm_bo_create(impl.gbm,
    		impl.drm_mode->hdisplay, impl.drm_mode->vdisplay,
			GBM_BO_FORMAT_XRGB8888,
			GBM_BO_USE_SCANOUT | GBM_BO_USE_RENDERING)) == NULL) {
    	log_error("gbm_bo_create\n");
    	goto finally;
    }

    glGenFramebuffers(1, &impl.fb);
    glBindFramebuffer(GL_FRAMEBUFFER_EXT, impl.fb);

    impl.gbm_handle = gbm_bo_get_handle(impl.gbm_bo).u32;
    impl.gbm_stride = gbm_bo_get_stride(impl.gbm_bo);

    if ((impl.img = eglCreateImage(impl.disp, NULL,
    		EGL_NATIVE_PIXMAP_KHR, impl.gbm_bo, NULL)) == NULL) {
    	log_error("eglCreateImageKHR\n");
    	goto finally;
    }

    glGenRenderbuffers(1, &impl.color_rb);
    glBindRenderbuffer(GL_RENDERBUFFER_EXT, impl.color_rb);
    glEGLImageTargetRenderbufferStorageOES(GL_RENDERBUFFER, impl.img);
    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
    		GL_RENDERBUFFER_EXT, impl.color_rb);

    /* and depth buffer */
    glGenRenderbuffers(1, &impl.depth_rb);
    glBindRenderbuffer(GL_RENDERBUFFER_EXT, impl.depth_rb);
    glRenderbufferStorage(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT,
    		impl.drm_mode->hdisplay, impl.drm_mode->vdisplay);
    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
    		GL_RENDERBUFFER_EXT, impl.depth_rb);

    if (glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT) !=
    		GL_FRAMEBUFFER_COMPLETE) {
    	log_error("something bad happened\n");
        goto finally;
    }

    uint32_t crtc;

    /* Create a KMS framebuffer handle to set a mode with */
    drmModeAddFB(impl.fd, impl.drm_mode->hdisplay, impl.drm_mode->vdisplay,
    		24, 32, impl.gbm_stride, impl.gbm_handle, &impl.drm_fb);

    drmModeSetCrtc(impl.fd, impl.drm_enc->crtc_id, impl.drm_fb, 0, 0,
    		impl.drm_conn->connector_id, 1, impl.drm_mode);

finally:
	;
}
