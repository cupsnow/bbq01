/* $Id$ */

#include <linux/version.h>
#include <linux/types.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/device.h>
#include <linux/kernel.h>
#include <linux/fs.h>

#include <linux/sched.h>
#include <linux/cdev.h>
#include <linux/errno.h>
#include <linux/proc_fs.h>
#include <linux/delay.h>
#include <linux/gpio.h>

#define log(level, fmt, ...) do { \
	printk(level "%s #%d " fmt, __func__, __LINE__, ##__VA_ARGS__); \
} while(0)
#define log_error(fmt, ...) log("ERROR ", fmt, ##__VA_ARGS__)
#define log_debug(fmt, ...) log("Debug ", fmt, ##__VA_ARGS__)
#define log_info(fmt, ...) log("Info ", fmt, ##__VA_ARGS__)

#define CLASS_NAME "water"
#define DEV_NAME "hx711"

static int hx711_major = 0;
module_param(hx711_major, int, 0);
MODULE_PARM_DESC(hx711_major, DEV_NAME " device major number");

static int hx711_clk = 20;
module_param(hx711_clk, int, 0);
MODULE_PARM_DESC(hx711_clk, DEV_NAME " clock in GPIO");

static int hx711_dio = 21;
module_param(hx711_dio, int, 0);
MODULE_PARM_DESC(hx711_dio, DEV_NAME " data in GPIO");

static struct {
	struct class *cls;
	struct device *dev;
	struct cdev cdev;
	dev_t dev_num;
	struct gpio gpio_lut[2];

} impl;

static int dev_open(struct inode *ip, struct file *fp)
{
	int r;
	struct gpio lut[] = {
		{hx711_clk, GPIOF_OUT_INIT_LOW, "hx711 PD_SCK" },
		{hx711_dio, GPIOF_IN,  "hx711 DOUT" },
	};

	log_debug("hx711 gpio request PD_SCK: %d, DOUT: %d\n",
			hx711_clk, hx711_dio);

	if ((r = gpio_request_array(lut, ARRAY_SIZE(lut))) != 0) {
		log_error("request gpio\n");
		return r;
	}

	return 0;
}

static int dev_release(struct inode *ip, struct file *fp)
{
	struct gpio lut[] = {
		{hx711_clk, GPIOF_OUT_INIT_LOW, "hx711 PD_SCK" },
		{hx711_dio, GPIOF_IN,  "hx711 DOUT" },
	};

	gpio_free_array(lut, ARRAY_SIZE(lut));
	log_debug("hx711 gpio free PD_SCK: %d, DOUT: %d\n",
			hx711_clk, hx711_dio);
	return 0;
}

static ssize_t dev_read(struct file *fp, char *buf, size_t sz,
		loff_t *sf)
{
	log_debug("enter\n");

	gpio_set_value(hx711_clk, 0);

	return 0;
}

static ssize_t dev_write(struct file *fp, const char *buf, size_t sz,
		loff_t *sf)
{
	log_debug("enter\n");

	gpio_set_value(hx711_clk, 1);

	return sz;
}

static struct file_operations fops = {
	.open = dev_open,
	.read = dev_read,
	.write = dev_write,
	.release = dev_release,
};

static int __init drv_init(void)
{
	int r;

	memset(&impl, 0, sizeof(impl));
	if ((r = register_chrdev(hx711_major, DEV_NAME, &fops)) < 0) {
		log_error("register_chrdev\n");
		return r;
	}
	if (!hx711_major) hx711_major = r;
	impl.dev_num = MKDEV(hx711_major, 0);

	if (IS_ERR(impl.cls = class_create(THIS_MODULE, CLASS_NAME))) {
		log_error("class_create\n");
		unregister_chrdev(hx711_major, DEV_NAME);
		return PTR_ERR(impl.cls);
	}

	if (IS_ERR(impl.dev = device_create(impl.cls, NULL, impl.dev_num,
			NULL, DEV_NAME))) {
		log_error("device_create\n");
		class_unregister(impl.cls);
		class_destroy(impl.cls);
		unregister_chrdev(hx711_major, DEV_NAME);
		return PTR_ERR(impl.dev);
	}

	return 0;
}
module_init(drv_init);

static void __exit drv_exit(void)
{
	device_destroy(impl.cls, impl.dev_num);
	class_unregister(impl.cls);
	class_destroy(impl.cls);
	unregister_chrdev(hx711_major, DEV_NAME);
}
module_exit(drv_exit);


MODULE_DESCRIPTION("hx711 driver on raspberry pi 2");
MODULE_AUTHOR("Joe <joe@raylios.com>");
MODULE_LICENSE("GPL");
