// SPDX-License-Identifier: GPL-2.0+
/*
 * (C) Copyright ASPEED Technology Inc.
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */
#include <common.h>
#include <bootm.h>
#include <command.h>
#include <environment.h>
#include <errno.h>
#include <image.h>
#include <malloc.h>
#include <nand.h>
#include <asm/byteorder.h>
#include <linux/ctype.h>
#include <linux/err.h>
#include <u-boot/zlib.h>
#include <asm/arch/aspeed_verify.h>

DECLARE_GLOBAL_DATA_PTR;

int do_boots(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
	struct aspeed_secboot_header *sb_hdr =
		(struct aspeed_secboot_header *)CONFIG_ASPEED_KERNEL_FIT_DRAM_BASE - 1;

	if (aspeed_bl2_verify(sb_hdr, sb_hdr + 1, sb_hdr) != 0)
		return -EPERM;

	sprintf(argv[0], "%x", CONFIG_ASPEED_KERNEL_FIT_DRAM_BASE + sizeof(*sb_hdr));

	return do_bootm_states(cmdtp, flag, argc, argv, BOOTM_STATE_START |
		BOOTM_STATE_FINDOS | BOOTM_STATE_FINDOTHER |
		BOOTM_STATE_LOADOS |
		BOOTM_STATE_OS_PREP | BOOTM_STATE_OS_FAKE_GO |
		BOOTM_STATE_OS_GO, &images, 1);
}

U_BOOT_CMD(
	boots,	1,	1,	do_boots,
	"Aspeed secure boot with in-memory image",
	""
);
