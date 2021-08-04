/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * Copyright (C) ASPEED Technology Inc.
 *
 */

#ifndef __CONFIG_H
#define __CONFIG_H

#include <configs/aspeed-common.h>

#define CONFIG_SYS_MEMTEST_START	(CONFIG_SYS_SDRAM_BASE + 0x300000)
#define CONFIG_SYS_MEMTEST_END		(CONFIG_SYS_MEMTEST_START + 0x5000000)

#define CONFIG_SYS_UBOOT_BASE		CONFIG_SYS_TEXT_BASE

/* Memory Info */
#define CONFIG_SYS_LOAD_ADDR		0x83000000

/* SPL */
#define CONFIG_SPL_TEXT_BASE		0x00000000
#define CONFIG_SPL_MAX_SIZE		0x00010000
#define CONFIG_SPL_STACK		0x10016000
#define CONFIG_SPL_BSS_START_ADDR	0x90000000
#define CONFIG_SPL_BSS_MAX_SIZE		0x00100000
#define CONFIG_SPL_LOAD_FIT_ADDRESS	0x00010000

/* Extra ENV for Boot Command */
#define STR_HELPER(n)	#n
#define STR(n)		STR_HELPER(n)

#undef CONFIG_EXTRA_ENV_SETTINGS
#define CONFIG_EXTRA_ENV_SETTINGS	\
	"loadaddr=" STR(CONFIG_SYS_LOAD_ADDR) "\0"	\
	"bootspi=fdt addr 20100000 && fdt header get fitsize totalsize && cp.b 20100000 ${loadaddr} ${fitsize} && bootm; echo Error loading kernel FIT image\0"	\
	"verify=yes\0"	\
	"usbtty=cdc_acm\0"	\
	""

#ifdef CONFIG_SPL_TINY
#ifdef CONFIG_SPL_BUILD
#define CONFIG_SYS_NS16550_REG_SIZE 2
#endif
#endif

#define CONFIG_USB_DEVICE		1
#define CONFIG_USB_TTY			1
#define CONFIG_USBD_HS			1
#define CONFIG_SYS_CONSOLE_IS_IN_ENV	1
#define CONFIG_USBD_MANUFACTURER	"Aspeed"
#define CONFIG_USBD_PRODUCT_NAME	"cdc-acm device"
#define CONFIG_USBD_VENDORID		0x4153
#define CONFIG_USBD_PRODUCTID		0x2600

#endif	/* __CONFIG_H */
