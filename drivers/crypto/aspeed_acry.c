// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * (C) Copyright ASPEED Technology Inc.
 */
#include <common.h>
#include <clk.h>
#include <dm/device.h>
#include <dm/fdtaddr.h>

struct aspeed_acry {
	struct clk clk;
};

static int aspeed_acry_probe(struct udevice *dev)
{
	struct aspeed_acry *acry = dev_get_priv(dev);
	int ret;

	ret = clk_get_by_index(dev, 0, &acry->clk);
	if (ret < 0) {
		debug("Can't get clock for %s: %d\n", dev->name, ret);
		return ret;
	}

	ret = clk_enable(&acry->clk);
	if (ret) {
		debug("Failed to enable acry clock (%d)\n", ret);
		return ret;
	}

	return ret;
}

static int aspeed_acry_remove(struct udevice *dev)
{
	struct aspeed_acry *acry = dev_get_priv(dev);

	clk_disable(&acry->clk);

	return 0;
}

static const struct udevice_id aspeed_acry_ids[] = {
	{ .compatible = "aspeed,ast2600-acry" },
	{ }
};

U_BOOT_DRIVER(aspeed_acry) = {
	.name = "aspeed_acry",
	.id = UCLASS_MISC,
	.of_match = aspeed_acry_ids,
	.probe = aspeed_acry_probe,
	.remove = aspeed_acry_remove,
	.priv_auto_alloc_size = sizeof(struct aspeed_acry),
	.flags = DM_FLAG_PRE_RELOC,
};
