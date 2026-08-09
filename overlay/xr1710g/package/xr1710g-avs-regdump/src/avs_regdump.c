// SPDX-License-Identifier: GPL-2.0
/*
 * avs_regdump - read/write AVS voltage control registers on XR1710G.
 *
 * Purpose: FIX-02 verification. STRICT_DEVMEM blocks user-space /dev/mem
 * access, so the only way to read the AVS DAC / OUT_EN registers from a
 * running system is an in-kernel ioremap. This module prints:
 *   - RG_AVS_OUT_EN (0x1fa202a0) bit0: must be 1 after 942 boots (942 sets
 *     it if it was 0; if it reads 0 here the boost never took effect)
 *   - RG_DATA_AVS_DAC (0x1fa202e0): the DAC value, expected inside
 *     [0x80, 0x350]; at 1400 MHz it should be baseline - delta (~29 LSB)
 *     if the 941/942 boost ran.
 *
 * Usage: insmod avs_regdump.ko [addr=0x1fa202a0] [count=2] ; dmesg
 * Optional: write=1 with value=N to set (use only for controlled tests).
 *
 * The register block lives in the chip-SCU region; the base used by the
 * cpufreq driver is 1fa20000 (devicetree "airoha,en7581-cpufreq" node).
 */
#include <linux/init.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/moduleparam.h>

#define AVS_REG_BASE		0x1fa20000UL
#define CPUPLL_AVS_OUT_EN	0x2a0	/* bit0 = AVS output enable */
#define CPUPLL_AVS_DAC		0x2e0	/* RG_DATA_AVS_DAC, bit16=CHG */
#define CPUPLL_AVS_DAC_MASK	0x3ff
#define PLLRG_PROTECT		0x268	/* guard register (941/942 use this) */

static unsigned long addr = AVS_REG_BASE + CPUPLL_AVS_OUT_EN;
static int count = 2;
static int write_val = -1;
module_param(addr, ulong, 0444);
module_param(count, int, 0444);
module_param(write_val, int, 0644);

static int __init avs_regdump_init(void)
{
	void __iomem *base;
	u32 val;
	int i;

	base = ioremap(0x1fa20000UL, 0x1000);
	if (!base) {
		pr_err("avs_regdump: ioremap failed\n");
		return -ENOMEM;
	}

	pr_info("avs_regdump: base 0x1fa20000 mapped\n");

	/* Read the guard register first to show protection state */
	pr_info("avs_regdump: PLLRG_PROTECT(0x1fa20268) = 0x%08x\n",
		readl(base + PLLRG_PROTECT));
	pr_info("avs_regdump: AVS_OUT_EN(0x1fa202a0)   = 0x%08x  (bit0=%u)\n",
		readl(base + CPUPLL_AVS_OUT_EN),
		readl(base + CPUPLL_AVS_OUT_EN) & 1u);
	pr_info("avs_regdump: AVS_DAC(0x1fa202e0)      = 0x%08x  (masked=0x%03x)\n",
		readl(base + CPUPLL_AVS_DAC),
		readl(base + CPUPLL_AVS_DAC) & CPUPLL_AVS_DAC_MASK);

	if (write_val >= 0) {
		/* For controlled tests: set DAC (with CHG latch toggle) */
		pr_info("avs_regdump: writing AVS_DAC = 0x%x\n", write_val);
		writel(write_val | BIT(16), base + CPUPLL_AVS_DAC);
		writel(write_val, base + CPUPLL_AVS_DAC);
	}

	for (i = 0; i < count; i++) {
		val = readl(base + CPUPLL_AVS_DAC);
		pr_info("avs_regdump: [%d] AVS_DAC = 0x%08x (masked=0x%03x)\n",
			i, val, val & CPUPLL_AVS_DAC_MASK);
	}

	iounmap(base);
	return 0;
}

static void __exit avs_regdump_exit(void)
{
}

module_init(avs_regdump_init);
module_exit(avs_regdump_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("XR1710G AVS register dump/verify (FIX-02)");
