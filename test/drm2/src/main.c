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

#include <gbm.h>

#include <xf86drm.h>
#include <xf86drmMode.h>

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>


#include <moss/util.h>

#define DRIFILE "/dev/dri/card0"

static struct {
	void *evm;
	int fd;

	struct {
		drmModeConnector *conn;
		drmModeEncoder *enc;
		drmModeModeInfo *mode;
	} kms;

	struct {
		struct gbm_device *dev;
		struct gbm_bo *buf_obj;
		union gbm_bo_handle buf_h;
		uint32_t buf_stride;
	} gbm;

	struct {
		PFNGLEGLIMAGETARGETRENDERBUFFERSTORAGEOESPROC glEGLImageTargetRenderbufferStorageOES;
	} glext;

    uint32_t drm_fb;

	EGLDisplay disp;
	EGLContext ctx;
	GLuint fb, color_rb, depth_rb;
	EGLImageKHR img;

} impl = {0};

static void draw(void)
{
	GLint compile_ok = GL_FALSE, link_ok = GL_FALSE;

	GLuint vs = glCreateShader(GL_VERTEX_SHADER);
	const char *vs_source =
//		"#version 100\n"  // OpenGL ES 2.0
		"#version 120\n"  // OpenGL 2.1
		"attribute vec2 coord2d;                  "
		"void main(void) {                        "
		"  gl_Position = vec4(coord2d, 0.0, 1.0); "
		"}";
	glShaderSource(vs, 1, &vs_source, NULL);
	glCompileShader(vs);
	glGetShaderiv(vs, GL_COMPILE_STATUS, &compile_ok);
	if (!compile_ok) {
		log_error("Error in vertex shader\n");
		goto finally;
	}

	GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);
	const char *fs_source =
//		"#version 100\n"  // OpenGL ES 2.0
			"#version 120\n"  // OpenGL 2.1
		"void main(void) {        "
		"  gl_FragColor[0] = 0.0; "
		"  gl_FragColor[1] = 0.0; "
		"  gl_FragColor[2] = 1.0; "
		"}";
	glShaderSource(fs, 1, &fs_source, NULL);
	glCompileShader(fs);
	glGetShaderiv(fs, GL_COMPILE_STATUS, &compile_ok);
	if (!compile_ok) {
		log_error("Error in fragment shader\n");
		goto finally;
	}

	GLuint program;
	program = glCreateProgram();
	glAttachShader(program, vs);
	glAttachShader(program, fs);
	glLinkProgram(program);
	glGetProgramiv(program, GL_LINK_STATUS, &link_ok);
	if (!link_ok) {
		log_error("Error in glLinkProgram\n");
		goto finally;
	}

	GLint attribute_coord2d;
	const char* attribute_name = "coord2d";
	attribute_coord2d = glGetAttribLocation(program, attribute_name);
	if (attribute_coord2d == -1) {
		log_error("Could not bind attribute %s\n", attribute_name);
		goto finally;
	}

	/* Clear the background as white */
	glClearColor(0.5, 0.5, 0.5, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);

	glUseProgram(program);
	glEnableVertexAttribArray(attribute_coord2d);
	GLfloat triangle_vertices[] = {
		0.0,  0.8,
	   -0.8, -0.8,
		0.8, -0.8,
	};
	/* Describe our vertices array to OpenGL (it can't guess its format automatically) */
	glVertexAttribPointer(
		attribute_coord2d, // attribute
		2,                 // number of elements per vertex, here (x,y)
		GL_FLOAT,          // the type of each element
		GL_FALSE,          // take our values as-is
		0,                 // no extra data between each position
		triangle_vertices  // pointer to the C array
	  );

	/* Push each element in buffer_vertices to the vertex shader */
	glDrawArrays(GL_TRIANGLES, 0, 3);
	glDisableVertexAttribArray(attribute_coord2d);

	glFinish();
finally:
	return;
}

static int kms_setup(int fd)
{
	int r = EIO, i, j;
	drmModeRes *drm_res;

	if ((drm_res = drmModeGetResources(fd)) == NULL) {
    	log_error("drmModeGetResources\n");
        goto finally;
    }
    log_debug("kms count crtc: %d, conn: %d, enc: %d\n", drm_res->count_crtcs,
    		drm_res->count_connectors, drm_res->count_encoders);

    for (i = 0; i < drm_res->count_connectors; i++) {
    	drmModeConnector *drm_conn;
        if ((drm_conn = drmModeGetConnector(fd,
        		drm_res->connectors[i])) == NULL) {
            continue;
        }
        if (drm_conn->connection == DRM_MODE_CONNECTED &&
        		drm_conn->count_modes > 0) {
        	impl.kms.conn = drm_conn;
        	break;
        }
        drmModeFreeConnector(drm_conn);
    }
    if (!impl.kms.conn) {
    	log_error("No currently active connector found.\n");
        goto finally;
    }
    log_debug("kms use conn%d, id: %d, count modes: %d\n", i,
    		impl.kms.conn->connector_id, impl.kms.conn->count_modes);

    for (i = 0; i < drm_res->count_encoders; i++) {
    	drmModeEncoder *drm_enc;
        if ((drm_enc = drmModeGetEncoder(fd,
        		drm_res->encoders[i])) == NULL) {
        	continue;
        }
        if (drm_enc->encoder_id == impl.kms.conn->encoder_id) {
        	impl.kms.enc = drm_enc;
        	break;
        }
        drmModeFreeEncoder(drm_enc);
    }
    if (!impl.kms.enc) {
    	log_error("No currently active encoder found.\n");
        goto finally;
    }
    log_debug("kms use enc%d, crtc_id: %d\n", i, impl.kms.enc->crtc_id);

//	for (i = 0; i < impl.kms.conn->count_modes; i++) {
//		log_debug("drm mode[%d]: %d x %d\n", i,
//				(int )impl.kms.conn->modes[i].hdisplay,
//				(int )impl.kms.conn->modes[i].vdisplay);
//	}
    for (i = 0, j = 0; i < impl.kms.conn->count_modes; i++) {
    	drmModeModeInfo *drm_mode = &impl.kms.conn->modes[i];
    	int drm_area = drm_mode->hdisplay * drm_mode->vdisplay;

    	if (drm_mode->type & DRM_MODE_TYPE_PREFERRED) {
    		impl.kms.mode = drm_mode;
    		break;
    	}
    	if (drm_area > j) {
    		impl.kms.mode = drm_mode;
    		j = drm_area;
    	}
    }
	log_debug("kms mode: %d x %d\n", (int)impl.kms.mode->hdisplay,
			(int)impl.kms.mode->vdisplay);

	if ((impl.gbm.dev = gbm_create_device(fd)) == NULL) {
		log_error("gbm_create_device\n");
		goto finally;
	}

    if ((impl.gbm.buf_obj = gbm_bo_create(impl.gbm.dev,
    		impl.kms.mode->hdisplay, impl.kms.mode->vdisplay,
			GBM_BO_FORMAT_XRGB8888,
			GBM_BO_USE_SCANOUT | GBM_BO_USE_RENDERING)) == NULL) {
    	log_error("gbm_bo_create\n");
    	goto finally;
    }
    impl.gbm.buf_h = gbm_bo_get_handle(impl.gbm.buf_obj);
    impl.gbm.buf_stride = gbm_bo_get_stride(impl.gbm.buf_obj);
	log_debug("gbm backend name: %s, %u x %u, stride: %u\n",
		gbm_device_get_backend_name(impl.gbm.dev),
		(unsigned)gbm_bo_get_width(impl.gbm.buf_obj),
		(unsigned)gbm_bo_get_height(impl.gbm.buf_obj),
		(unsigned)impl.gbm.buf_stride);
    r = 0;
finally:
	return r;
}

int main()
{
	EGLint major, minor;
	int i;

	memset(&impl, 0, sizeof(impl));
	impl.fd = -1;

	if ((impl.fd = open(DRIFILE, O_RDWR)) == -1) {
		log_error("open %s\n", DRIFILE);
		goto finally;
	}
	if (kms_setup(impl.fd) != 0) {
    	log_error("set_kms\n");
        goto finally;
	}
	if ((impl.disp = eglGetDisplay(impl.gbm.dev)) == EGL_NO_DISPLAY) {
		log_error("eglGetDisplay\n");
		goto finally;
	}
	if (!eglInitialize(impl.disp, &major, &minor)) {
		log_error("eglInitialize\n");
		goto finally;
	}
	{
		const char *ver, *ext, *ven, *clapi;

		if ((ext = eglQueryString(impl.disp, EGL_EXTENSIONS)) == NULL) {
			log_error("eglQueryString EGL_EXTENSIONS\n");
			goto finally;
		}
		if ((ver = eglQueryString(impl.disp, EGL_VERSION)) == NULL) {
			log_error("eglQueryString EGL_VERSION\n");
			goto finally;
		}
		if ((ven = eglQueryString(impl.disp, EGL_VENDOR)) == NULL) {
			log_error("eglQueryString  EGL_VENDOR\n");
			goto finally;
		}
		if ((clapi = eglQueryString(impl.disp, EGL_CLIENT_APIS)) == NULL) {
			log_error("eglQueryString  EGL_CLIENT_APIS\n");
			goto finally;
		}
		log_debug("EGL Version: %s\n"
				"  Extensions: %s\n"
				"  Vendor: %s\n"
				"  Client APIs: %s\n", ver, ext, ven, clapi);
		if (!strstr(ext, "EGL_KHR_surfaceless_context")) {
			log_error("no EGL_KHR_surfaceless_context\n");
			goto finally;
		}
		if (!strstr(clapi, "OpenGL_ES")) {
			log_error("no OpenGL_ES\n");
			goto finally;
		}
	}
	// EGL_OPENGL_API, EGL_OPENGL_ES_API
	if (!eglBindAPI(EGL_OPENGL_ES_API)) {
    	log_error("eglBindAPI\n");
    	goto finally;
	}
    if ((impl.ctx = eglCreateContext(impl.disp, NULL, EGL_NO_CONTEXT,
    		NULL)) == NULL) {
    	log_error("eglCreateContext\n");
    	goto finally;
    }

    if (!eglMakeCurrent(impl.disp, EGL_NO_SURFACE, EGL_NO_SURFACE, impl.ctx)) {
		log_error("eglMakeCurrent\n");
    	goto finally;
    }
	{
		const char *ver, *ext, *ven, *rend, *ver_sh;

		if ((ver = glGetString(GL_VERSION)) == NULL) {
			log_error("glGetString GL_VERSION\n");
			goto finally;
		}
		if ((ext = glGetString(GL_EXTENSIONS)) == NULL) {
			log_error("glGetString GL_EXTENSIONS\n");
			goto finally;
		}
		if ((ven = glGetString(GL_VENDOR)) == NULL) {
			log_error("glGetString GL_VENDOR\n");
			goto finally;
		}
		if ((rend = glGetString(GL_RENDERER)) == NULL) {
			log_error("glGetString GL_RENDERER\n");
			goto finally;
		}
		if ((ver_sh = glGetString(GL_SHADING_LANGUAGE_VERSION)) == NULL) {
			log_error("glGetString GL_SHADING_LANGUAGE_VERSION\n");
//			goto finally;
			ver_sh = "";
		}
		log_debug("GL Version: %s, GSLS: %s\n"
				"  Extensions: %s\n"
				"  Vendor: %s\n"
				"  Renderer: %s\n", ver, ver_sh, ext, ven, rend);
	}

#define GLEXT_LOAD(_type, _name) \
	if ((impl.glext._name = (_type)eglGetProcAddress(MOSS_STRINGIFY2(_name))) == NULL) { \
		log_error("no %s\n", MOSS_STRINGIFY2(_name)); \
		goto finally; \
	}
    GLEXT_LOAD(PFNGLEGLIMAGETARGETRENDERBUFFERSTORAGEOESPROC,
    		glEGLImageTargetRenderbufferStorageOES);

    glGenFramebuffers(1, &impl.fb);
    glBindFramebuffer(GL_FRAMEBUFFER, impl.fb);

    if ((impl.img = eglCreateImage(impl.disp, impl.ctx, EGL_NATIVE_PIXMAP_KHR,
    		impl.gbm.buf_obj, NULL)) == NULL) {
    	log_error("eglCreateImageKHR\n");
    	goto finally;
    }

    glGenRenderbuffers(1, &impl.color_rb);
    glBindRenderbuffer(GL_RENDERBUFFER, impl.color_rb);
    impl.glext.glEGLImageTargetRenderbufferStorageOES(GL_RENDERBUFFER, impl.img);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
    		GL_RENDERBUFFER, impl.color_rb);

    /* and depth buffer */
    glGenRenderbuffers(1, &impl.depth_rb);
    glBindRenderbuffer(GL_RENDERBUFFER, impl.depth_rb);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT,
    		impl.kms.mode->hdisplay, impl.kms.mode->vdisplay);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
    		GL_RENDERBUFFER, impl.depth_rb);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) !=
    		GL_FRAMEBUFFER_COMPLETE) {
    	log_error("glCheckFramebufferStatus\n");
        goto finally;
    }

    draw();
    /* Create a KMS framebuffer handle to set a mode with */
    drmModeAddFB(impl.fd, impl.kms.mode->hdisplay, impl.kms.mode->vdisplay,
    		24, 32, impl.gbm.buf_stride, impl.gbm.buf_h.u32, &impl.drm_fb);

    drmModeSetCrtc(impl.fd, impl.kms.enc->crtc_id, impl.drm_fb, 0, 0,
    		&impl.kms.conn->connector_id, 1, impl.kms.mode);

    log_debug("press 'Enter' to exit\n");
    log_debug("0x%d\n", getchar());

finally:
	;
	return 0;
}

