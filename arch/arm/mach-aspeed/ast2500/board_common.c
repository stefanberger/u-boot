// SPDX-License-Identifier: GPL-2.0+
/*
 * Copyright (c) 2016 Google, Inc
 */
#include <common.h>
#include <dm.h>
#include <ram.h>
#include <timer.h>
#include <asm/io.h>
#include <asm/arch/timer.h>
#include <linux/err.h>
#include <dm/uclass.h>

DECLARE_GLOBAL_DATA_PTR;

/* LPC register offset */
#define LPC_BASE	0x1e789000
#define HICR0	0x000
#define 	HICR0_LPC3E		BIT(7)
#define LADR3H	0x014
#define LADR3L	0x018
#define HICR5	0x080
#define 	HICR5_EN_SNP0W	BIT(0)
#define SNPWADR	0x090
#define 	SNPWADR_ADDR0_MASK	GENMASK(15, 0)
#define 	SNPWADR_ADDR0_SHIFT	0
#define HICRB	0x100
#define 	HICRB_ENSNP0D	BIT(14)

__weak int board_init(void)
{
	struct udevice *dev;
	int i;
	int ret;

	gd->bd->bi_boot_params = CONFIG_SYS_SDRAM_BASE + 0x100;

	/*
	 * Loop over all MISC uclass drivers to call the comphy code
	 * and init all CP110 devices enabled in the DT
	 */
	i = 0;
	while (1) {
		/* Call the comphy code via the MISC uclass driver */
		ret = uclass_get_device(UCLASS_MISC, i++, &dev);

		/* We're done, once no further CP110 device is found */
		if (ret)
			break;
	}

	return 0;
}

#ifndef CONFIG_RAM
#define SDMC_CONFIG_VRAM_GET(x)		((x >> 2) & 0x3)
#define SDMC_CONFIG_MEM_GET(x)		(x & 0x3)

static const u32 ast2500_dram_table[] = {
	0x08000000,	//128MB
	0x10000000,	//256MB
	0x20000000,	//512MB
	0x40000000,	//1024MB
};

u32
ast_sdmc_get_mem_size(void)
{
	u32 size = 0;
	u32 size_conf = SDMC_CONFIG_MEM_GET(readl(0x1e6e0004));

	size = ast2500_dram_table[size_conf];

	return size;

}

static const u32 aspeed_vram_table[] = {
	0x00800000,	//8MB
	0x01000000,	//16MB
	0x02000000,	//32MB
	0x04000000,	//64MB
};

static u32
ast_sdmc_get_vram_size(void)
{
	u32 size_conf = SDMC_CONFIG_VRAM_GET(SDMC_CONFIG_VRAM_GET(readl(0x1e6e0004)));
	return aspeed_vram_table[size_conf];
}
#endif

__weak int dram_init(void)
{
#ifdef CONFIG_RAM
	struct udevice *dev;
	struct ram_info ram;
	int ret;

	ret = uclass_get_device(UCLASS_RAM, 0, &dev);
	if (ret) {
		debug("DRAM FAIL1\r\n");
		return ret;
	}

	ret = ram_get_info(dev, &ram);
	if (ret) {
		debug("DRAM FAIL2\r\n");
		return ret;
	}

	gd->ram_size = ram.size;
#else
	u32 vga = ast_sdmc_get_vram_size();
	u32 dram = ast_sdmc_get_mem_size();
	gd->ram_size = (dram - vga);
#endif
	return 0;
}

static void init_snoop_port80h(void)
{
	uint32_t reg;

	reg = readl(LPC_BASE + SNPWADR);
	reg &= ~SNPWADR_ADDR0_MASK;
	reg |= 0x80;
	writel(reg, LPC_BASE + SNPWADR);

	reg = readl(LPC_BASE + HICRB);
	reg |= HICRB_ENSNP0D;
	writel(reg, LPC_BASE + HICRB);

	reg = readl(LPC_BASE + HICR5);
	reg |= HICR5_EN_SNP0W;
	writel(reg, LPC_BASE + HICR5);
}

static void init_kcs_portCA2h(void)
{
	uint32_t reg;

	writel(0xA2, LPC_BASE + LADR3L);
	writel(0xC, LPC_BASE + LADR3H);

	reg = readl(LPC_BASE + HICR0);
	reg |= HICR0_LPC3E;
	writel(reg, LPC_BASE + HICR0);
}

int arch_early_init_r(void)
{
	/*
	 * AST2500/AST2600 SW workaround:
	 * When eSPI-LPC bridge HW stays in the LPC I/O port
	 * decoding error state, controllers behind the bridge
	 * cannot be enabled. Thereby, these controller should
	 * be enabled early to avoid the decoding error.
	 *
	 * This workaround enables only the controllers which
	 * commonly interacts with Host at the early stage.
	 * Namely, the debug@80h and the KCS@CA2h.
	 */
	init_snoop_port80h();
	init_kcs_portCA2h();

#ifdef CONFIG_DM_PCI
	/* Trigger PCIe devices detection */
	pci_init();
#endif

	return 0;
}
