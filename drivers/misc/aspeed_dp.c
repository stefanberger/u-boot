// SPDX-License-Identifier: GPL-2.0+
/*
 * Copyright (C) ASPEED Technology Inc.
 */

#include <common.h>
#include <clk.h>
#include <dm.h>
#include <errno.h>
#include <reset.h>
#include <fdtdec.h>
#include <asm/io.h>
#include "dp_mcu_firmware.h"

#define USE_SI2C

struct aspeed_dp_priv {
	void *ctrl_base;
};

static int aspeed_dp_probe(struct udevice *dev)
{
	struct aspeed_dp_priv *dp = dev_get_priv(dev);
	struct reset_ctl dp_reset_ctl, dpmcu_reset_ctrl;
	int i, ret = 0;
	int i2c_port = -1;

	/* Get the controller base address */
	dp->ctrl_base = (void *)devfdt_get_addr_index(dev, 0);

	debug("%s(dev=%p) \n", __func__, dev);

	ret = reset_get_by_index(dev, 0, &dp_reset_ctl);
	if (ret) {
		printf("%s(): Failed to get dp reset signal\n", __func__);
		return ret;
	}

	ret = reset_get_by_index(dev, 1, &dpmcu_reset_ctrl);
	if (ret) {
		printf("%s(): Failed to get dp mcu reset signal\n", __func__);
		return ret;
	}

	/* release reset for DPTX and DPMCU */
	reset_assert(&dp_reset_ctl);
	reset_assert(&dpmcu_reset_ctrl);
	reset_deassert(&dp_reset_ctl);
	reset_deassert(&dpmcu_reset_ctrl);

	/* select HOST or BMC as display control master
	enable or disable sending EDID to Host	*/
	writel(readl(dp->ctrl_base + 0xB8) & ~(BIT(24) | BIT(28)), dp->ctrl_base + 0xB8);

	/* DPMCU */
	/* clear display format and enable region */
	writel(0, 0x18000de0);
	
	/* load DPMCU firmware to internal instruction memory */
	writel(0x10550010, 0x180100e0);
	writel(0x10440010, 0x180100e0);
	writel(0x10000010, 0x180100e0);
	writel(0x10000011, 0x180100e0);

	for (i = 0; i < ARRAY_SIZE(firmware_ast2600_dp); i++)
		writel(firmware_ast2600_dp[i], 0x18020000 + (i * 4));

	// update configs for re-driver
	i2c_port = dev_read_s32_default(dev, "i2c-port", -1);
	if (i2c_port == -1) {
		printf("%s(): Failed to get dp i2c_port for re-driver\n", __func__);
		writel(0xdeadbeef, 0x18000e00);
	} else {
		const u32 *cell;
		u32 i2c_base;
		u32 dev_addr = -1;
		int len, i;

		dev_addr = dev_read_s32_default(dev, "dev-addr", -1);
		if (dev_addr == -1)
			dev_addr = 0x70;
		debug("%s(): i2c_port(%d) for re-driver(%#x)\n", __func__, i2c_port, dev_addr);

		writel(0xcafe, 0x18000e00);
		cell = dev_read_prop(dev, "eq-table", &len);
		for (i = 0; i < len / sizeof(u32); ++i)
			writel(fdt32_to_cpu(cell[i]), 0x18000e04 + i * 4);
#ifdef USE_SI2C
		i2c_port %= 4;
		i2c_base = 0x1e7a8000;
#else
		i2c_base = 0x1e78a000;
#endif
		writel(i2c_base + 0x80 + 0x80 * i2c_port, 0x18000e28);
		writel(i2c_base + 0xc00 + 0x20 * i2c_port, 0x18000e2c);
		writel(dev_addr, 0x18000e30);

		// i2c global init
		writel(0x16, i2c_base + 0x0c);
		writel(0x041230C6, i2c_base + 0x10);

		// i2c port init
		i2c_base = i2c_base + 0x80 + 0x80 * i2c_port;
		writel(0x0, i2c_base);
		mdelay(1);
		writel(0x28001, i2c_base);
		writel(0x344001, i2c_base + 0x04);
		writel(0xFFFFFFFF, i2c_base + 0x14);
		writel(0x0, i2c_base + 0x10);
		mdelay(10);
	}

	/* release DPMCU internal reset */
	writel(0x10000010, 0x180100e0);
	writel(0x10001110, 0x180100e0);
	//disable dp interrupt
	writel(0x00ff0000, 0x180100e8);
	//set vga ASTDP with DPMCU FW handling scratch
	writel(readl(0x1e6e2100) | (0x7 << 9), 0x1e6e2100);	

	return 0;
}

static int dp_aspeed_ofdata_to_platdata(struct udevice *dev)
{
	struct aspeed_dp_priv *dp = dev_get_priv(dev);

	/* Get the controller base address */
	dp->ctrl_base = (void *)devfdt_get_addr_index(dev, 0);

	return 0;
}

static const struct udevice_id aspeed_dp_ids[] = {
	{ .compatible = "aspeed,ast2600-displayport" },
	{ }
};

U_BOOT_DRIVER(aspeed_dp) = {
	.name		= "aspeed_dp",
	.id			= UCLASS_MISC,
	.of_match	= aspeed_dp_ids,
	.probe		= aspeed_dp_probe,
	.ofdata_to_platdata   = dp_aspeed_ofdata_to_platdata,
	.priv_auto_alloc_size = sizeof(struct aspeed_dp_priv),
};
