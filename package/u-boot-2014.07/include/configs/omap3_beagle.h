/*
 * (C) Copyright 2006-2008
 * Texas Instruments.
 * Richard Woodruff <r-woodruff2@ti.com>
 * Syed Mohammed Khasim <x0khasim@ti.com>
 *
 * Configuration settings for the TI OMAP3530 Beagle board.
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */

#ifndef __CONFIG_H
#define __CONFIG_H

#define CONFIG_NR_DRAM_BANKS	2	/* CS1 may or may not be populated */

/*
 * 1MB into the SDRAM to allow for SPL's bss at the beginning of SDRAM
 * 64 bytes before this address should be set aside for u-boot.img's
 * header. That is 0x800FFFC0--0x80100000 should not be used for any
 * other needs.  We use this rather than the inherited defines from
 * ti_armv7_common.h for backwards compatibility.
 */
#define CONFIG_SYS_TEXT_BASE		0x80100000
#define CONFIG_SPL_BSS_START_ADDR	0x80000000
#define CONFIG_SPL_BSS_MAX_SIZE		(512 << 10)	/* 512 KB */
#define CONFIG_SYS_SPL_MALLOC_START	0x80208000
#define CONFIG_SYS_SPL_MALLOC_SIZE	0x100000

#include <configs/ti_omap3_common.h>

/*
 * Display CPU and Board information
 */
#define CONFIG_DISPLAY_CPUINFO		1
#define CONFIG_DISPLAY_BOARDINFO	1

#define CONFIG_MISC_INIT_R

#define CONFIG_REVISION_TAG		1
#define CONFIG_ENV_OVERWRITE

/* Status LED */
#define CONFIG_STATUS_LED		1
#define CONFIG_BOARD_SPECIFIC_LED	1
#define STATUS_LED_BIT			0x01
#define STATUS_LED_STATE		STATUS_LED_ON
#define STATUS_LED_PERIOD		(CONFIG_SYS_HZ / 2)
#define STATUS_LED_BIT1			0x02
#define STATUS_LED_STATE1		STATUS_LED_ON
#define STATUS_LED_PERIOD1		(CONFIG_SYS_HZ / 2)
#define STATUS_LED_BOOT			STATUS_LED_BIT
#define STATUS_LED_GREEN		STATUS_LED_BIT1

/* Enable Multi Bus support for I2C */
#define CONFIG_I2C_MULTI_BUS		1

/* Probe all devices */
#define CONFIG_SYS_I2C_NOPROBES		{{0x0, 0x0}}

/* USB */
#define CONFIG_MUSB_GADGET
#define CONFIG_USB_MUSB_OMAP2PLUS
#define CONFIG_MUSB_PIO_ONLY
#define CONFIG_USB_GADGET_DUALSPEED
#define CONFIG_TWL4030_USB		1
#define CONFIG_USB_ETHER
#define CONFIG_USB_ETHER_RNDIS
#define CONFIG_USB_GADGET
#define CONFIG_USB_GADGET_VBUS_DRAW	0
#define CONFIG_USBDOWNLOAD_GADGET
#define CONFIG_G_DNL_VENDOR_NUM		0x0451
#define CONFIG_G_DNL_PRODUCT_NUM	0xd022
#define CONFIG_G_DNL_MANUFACTURER	"TI"
#define CONFIG_CMD_FASTBOOT
#define CONFIG_ANDROID_BOOT_IMAGE
#define CONFIG_USB_FASTBOOT_BUF_ADDR	CONFIG_SYS_LOAD_ADDR
#define CONFIG_USB_FASTBOOT_BUF_SIZE	0x07000000

/* USB EHCI */
#define CONFIG_CMD_USB
#define CONFIG_USB_EHCI

#define CONFIG_USB_EHCI_OMAP
#define CONFIG_OMAP_EHCI_PHY1_RESET_GPIO	147

#define CONFIG_SYS_USB_EHCI_MAX_ROOT_PORTS 3
#define CONFIG_USB_HOST_ETHER
#define CONFIG_USB_ETHER_ASIX
#define CONFIG_USB_ETHER_MCS7830
#define CONFIG_USB_ETHER_SMSC95XX

/* GPIO banks */
#define CONFIG_OMAP3_GPIO_5		/* GPIO128..159 is in GPIO bank 5 */
#define CONFIG_OMAP3_GPIO_6		/* GPIO160..191 is in GPIO bank 6 */

/* commands to include */
#include <config_cmd_default.h>

#define CONFIG_CMD_ASKENV

#define CONFIG_CMD_CACHE

#define MTDIDS_DEFAULT			"nand0=nand"
#define MTDPARTS_DEFAULT		"mtdparts=nand:512k(x-loader),"\
					"1920k(u-boot),128k(u-boot-env),"\
					"4m(kernel),-(fs)"

#define CONFIG_USB_STORAGE	/* USB storage support		*/
#define CONFIG_CMD_NAND		/* NAND support			*/
#define CONFIG_CMD_LED		/* LED support			*/
#define CONFIG_CMD_SETEXPR	/* Evaluate expressions		*/
#define CONFIG_CMD_GPIO     /* Enable gpio command */
#define CONFIG_CMD_DHCP

#define CONFIG_VIDEO_OMAP3	/* DSS Support			*/

/*
 * TWL4030
 */
#define CONFIG_TWL4030_LED		1

/*
 * Board NAND Info.
 */
#define CONFIG_SYS_NAND_QUIET_TEST	1
#define CONFIG_NAND_OMAP_GPMC
#define CONFIG_SYS_MAX_NAND_DEVICE	1		/* Max number of NAND */
							/* devices */
#define CONFIG_EXTRA_ENV_SETTINGS \
	"bootaddr=0x80200000\0" \
	"bootfile=uImage\0" \
	"fdtaddr=0x88000000\0" \
	"fdtfile=dtb\0" \
	"initramfsaddr=0x81000000\0" \
	"initramfsfile=initramfs\0" \
	"console=ttyO2,115200n8\0" \
	"initmmc=mmc dev 0; mmc rescan\0" \
	"loadimage=fatload mmc 0:1 ${bootaddr} ${bootfile}\0" \
	"loadfdt=fatload mmc 0:1 ${fdtaddr} ${fdtfile}\0" \
	"loadinitramfs=fatload mmc 0:1 ${initramfsaddr} ${initramfsfile}\0" \
	"loadbootargs=setenv bootargs console=${console} root=/dev/ram0\0"

#define CONFIG_BOOTCOMMAND \
	"run initmmc; run loadimage; run loadfdt; run loadinitramfs;" \
	"run loadbootargs; bootm ${bootaddr} ${initramfsaddr} ${fdtaddr};"

/*
 * OMAP3 has 12 GP timers, they can be driven by the system clock
 * (12/13/16.8/19.2/38.4MHz) or by 32KHz clock. We use 13MHz (V_SCLK).
 * This rate is divided by a local divisor.
 */
#define CONFIG_SYS_PTV			2       /* Divisor: 2^(PTV+1) => 8 */

/*-----------------------------------------------------------------------
 * FLASH and environment organization
 */

/* **** PISMO SUPPORT *** */

/* Configure the PISMO */
#define PISMO1_NAND_SIZE		GPMC_SIZE_128M
#define PISMO1_ONEN_SIZE		GPMC_SIZE_128M

#if defined(CONFIG_CMD_NAND)
#define CONFIG_SYS_FLASH_BASE		PISMO1_NAND_BASE
#endif

/* Monitor at start of flash */
#define CONFIG_SYS_MONITOR_BASE		CONFIG_SYS_FLASH_BASE
#define CONFIG_SYS_ONENAND_BASE		ONENAND_MAP

#define CONFIG_ENV_IS_IN_NAND		1
#define CONFIG_ENV_SIZE			(128 << 10)	/* 128 KiB */
#define ONENAND_ENV_OFFSET		0x260000 /* environment starts here */
#define SMNAND_ENV_OFFSET		0x260000 /* environment starts here */

#define CONFIG_SYS_ENV_SECT_SIZE	(128 << 10)	/* 128 KiB */
#define CONFIG_ENV_OFFSET		SMNAND_ENV_OFFSET
#define CONFIG_ENV_ADDR			SMNAND_ENV_OFFSET

#define CONFIG_OMAP3_SPI

#define CONFIG_SYS_CACHELINE_SIZE	64

/* Defines for SPL */
#define CONFIG_SPL_OMAP3_ID_NAND

/* NAND boot config */
#define CONFIG_SYS_NAND_BUSWIDTH_16BIT	16
#define CONFIG_SYS_NAND_5_ADDR_CYCLE
#define CONFIG_SYS_NAND_PAGE_COUNT	64
#define CONFIG_SYS_NAND_PAGE_SIZE	2048
#define CONFIG_SYS_NAND_OOBSIZE		64
#define CONFIG_SYS_NAND_BLOCK_SIZE	(128*1024)
#define CONFIG_SYS_NAND_BAD_BLOCK_POS	0
#define CONFIG_SYS_NAND_ECCPOS		{2, 3, 4, 5, 6, 7, 8, 9,\
						10, 11, 12, 13}
#define CONFIG_SYS_NAND_ECCSIZE		512
#define CONFIG_SYS_NAND_ECCBYTES	3
#define CONFIG_NAND_OMAP_ECCSCHEME	OMAP_ECC_HAM1_CODE_HW
#define CONFIG_SYS_NAND_U_BOOT_OFFS	0x80000

#endif /* __CONFIG_H */
