/*
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
/*
 * Board specific setup info
 *
 ******************************************************************************
 * ASPEED Technology Inc.
 * AST25x0 DDR3/DDR4 SDRAM controller initialization sequence
 *
 * Gary Hsu, <gary_hsu@aspeedtech.com>
 *
 * Version     : 18
 * Release date: 2017.10.27
 *
 * Priority of fix item:
 * [P1] = critical
 * [P2] = nice to have
 * [P3] = minor
 *
 * Change List :
 * V2 |2014.07.25 : 1.[P1] Modify HPLL config sequence
 * V2 |2014.07.30 : 1.[P1] Modify DDR3 AC parameters table
 *    |             2.[P1] Turn on ZQCS mode
 * V2 |2014.08.13 : 1.[P1] Add disable XDMA
 * V2 |2014.09.09 : 1.[P1] Disable CKE dynamic power down
 * V2 |2014.10.31 : 1.[P2] Enable VGA wide screen support (SCU40[0]=1)
 * V2 |2015.03.26 : 1.[P1] Revise AC timing table
 *    |             2.[P1] Add check code to bypass A0 patch
 *    |             3.[P1] Add MPLL parameter of A1
 *    |             4.[P1] Set X-DMA into VGA memory domain
 * V2 |2015.04.24 : 1.[P1] Add disabling all DRAM requests during PHY init
 *    |             2.[P1] Set MCR1C & MCR38
 * V3 |2015.05.13 : 1.[P1] Modify DDR4 PHY Vref training algorithm
 *    |             2.[P2] Enable CKE dynamic power down
 * V4 |2015.06.15 : 1.[P1] Add MAC timing setting
 * V5 |2015.07.09 : 1.[P1] Modify MHCLK divider ratio
 *    |             2.[P2] Add DDR read margin report
 * V6 |2015.08.13 : 1.[P3] Disable MMC password before exit
 * V6 |2015.08.24 : 1.[P1] Fix SCU160 parameter value for CLKIN=25MHz condition
 * V7 |2015.09.18 : 1.[P1] Clear AHB bus lock condition at power up time
 *    |             2.[P1] Add reset MMC controller to solve init DRAM again during VGA ON
 * V7 |2015.09.22 : 1.[P1] Add watchdog full reset for resolving reset incomplete issue at fast reset condition
 *    |             2.[P1] Add DRAM stress test after train complete, and redo DRAM initial if stress fail
 *    |             3.[P2] Enable JTAG master mode
 *    |             4.[P2] Add DDR4 Vref trainig retry timeout
 * V8 |2015.11.02 : 1.[P2] Clear software strap flag before doing watchdog full reset
 *    |2015.12.10 : 1.[P1] Add USB PHY initial code
 *    |2016.01.27 : 1.[P3] Modify the first reset from full chip reset to SOC reset
 *    |             2.[P3] Remove HPLL/MPLL patch code for revision A0
 *    |             3.[P2] Move the reset_mmc code to be after MPLL initialized
 * V9 |2016.02.19 : 1.[P3] Remove definition "CONFIG_FIRMWARE_2ND_BOOT"
 * V10|2016.04.21 : 1.[P1] Add USB PHY initial code - port B, to prevent wrong state on USB pins
 * V11|2016.05.10 : 1.[P3] Add DRAM Extended temperature range support
 * V12|2016.06.24 : 1.[P1] Modify LPC Reset input source when eSPI mode enabled
 *    |2016.07.12 : 2.[P1] Modify DDR4 read path ODT from 60 ohm to 48 ohm, at address 0x1e6e0204
 *    |           : 3.[P1] Modify DDR4 Ron calibration to manual mode to fix Vix issue, set Ron_pu = 0
 *    |           : 4.[P2] Modify read timing margin report policy, change DDR4 min value from 0.35 to 0.3. Add "Warning" while violated.
 * V13|2016.08.29 : 1.[P3] Add option to route debug message output port from UART5 to UART1
 *    |2016.09.02 : 2.[P2] Add range control for cache function when ECC enabled
 *    |2016.09.06 : 3.[P1] Enable full mask setting for first SOC reset, since the coverage of original default setting is not enough
 * V14|2016.10.25 : 1.[P2] Change Ron manual calibration to default OFF, customer can enable it to do fine-tuning of the Vix issue
 *    |2016.11.07 : 2.[P3] Add log information of DDR4 PHY Vref training
 * V15|2017.04.06 : 1.[P1] Modify USB portA initial sequence, this is to prevent DMA lock condition of USB Virtual Hub device for some chips.
 *    |2017.04.13 : 2.[P2] Add initial sequence for LPC controller
 * V16|2017.06.15 : 1.[P1] Add margin check/retry for DDR4 Vref training margin.
 *    |2017.06.15 : 2.[P1] Add margin check/retry for DDR3/DDR4 read timing training margin.
 *    |2017.06.19 : 3.[P2] Add initial sequence for LPC controller
 *    |2017.06.19 : 4.[P2] Add initial full-chip reset option
 *    |2017.06.19 : 5.[P3] Add 10ms delay after DDR reset
 * V17|2017.09.25 : 1.[P1] Modify DDR4 side ODT value from 60ohm to 48ohm.
 *    |2017.09.25 : 2.[P1] Add Hynix DDR4 frequency slow down option.
 * V18|2017.10.26 : 1.[P3] Include the modification of DDR4 side ODT value in V17 into the option of Hynix DDR4 configuration.
 *    |2017.10.26 : 2.[P2] Enhance initial sequence for LPC controller
 * Note: Read timing report is only a reference, it is not a solid rule for stability.
 *
 * Optional define variable
 * 1. DRAM Speed                  //
 *    CONFIG_DRAM_1333            //
 *    CONFIG_DRAM_1600            // (default)
 * 2. ECC Function enable
 *    CONFIG_DRAM_ECC             // define to enable ECC function
 *    CONFIG_DRAM_ECC_SIZE        // define the ECC protected memory size
 * 3. UART5 message output        //
 *    CONFIG_DRAM_UART_38400      // set the UART baud rate to 38400, default is 115200
 *    CONFIG_DRAM_UART_TO_UART1   // route UART5 to UART port1
 * 4. DRAM Type
 *    CONFIG_DDR3_8GSTACK         // DDR3 8Gbit Stack die
 *    CONFIG_DDR4_4GX8            // DDR4 4Gbit X8 dual part
 * 5. Firmware 2nd boot flash
 *    CONFIG_FIRMWARE_2ND_BOOT (Removed)
 * 6. Enable DRAM extended temperature range mode
 *    CONFIG_DRAM_EXT_TEMP
 * 7. Select WDT_Full mode for power up initial reset
 *    ASTMMC_INIT_RESET_MODE_FULL
 * 8. Hynix DDR4 options
 *    CONFIG_DDR4_SUPPORT_HYNIX   // Enable this when Hynix DDR4 included in the BOM
 *    CONFIG_DDR4_HYNIX_SET_1536
 *    CONFIG_DDR4_HYNIX_SET_1488
 *    CONFIG_DDR4_HYNIX_SET_1440  // Default
 ******************************************************************************
 */

#include <config.h>
#include <version.h>

/******************************************************************************
  r4 : return program counter
  r5 : DDR speed timing table base address
  Free registers:
  r0, r1, r2, r3, r6, r7, r8, r9, r10, r11
 ******************************************************************************/
#define ASTMMC_INIT_VER      0x12                @ 8bit verison number
#define ASTMMC_INIT_DATE     0x20171027          @ Release date

/******************************************************************************
  BMC side DDR IO driving manual mode fine-tuning, used to improve CK/CKN Vix violation.
  Default disabled, the driver setting is hardware auto tuned.

  ASTMMC_DDR4_MANUAL_RPU | ASTMMC_DDR4_MANUAL_RPD
  -----------------------+-----------------------
            No           |           x          : manual mode disabled
            Yes          |          No          : enable Rpu     manual setting
            Yes          |          Yes         : enable Rpu/Rpd manual setting
 ******************************************************************************/
//#define ASTMMC_DDR4_MANUAL_RPU 0x0             @ 0x0-0xF, larger value means weaker driving
//#define ASTMMC_DDR4_MANUAL_RPD 0x0             @ 0x0-0xF, larger value means stronger driving

/******************************************************************************
  Select initial reset mode as WDT_Full
  WDT_Full is a more complete reset mode than WDT_SOC.
  But if FW has other initial code executed before platform.S, then it should use WDT_SOC mode.
  Use WDT_Full may clear the initial result of prior initial code.
 ******************************************************************************/
//#define ASTMMC_INIT_RESET_MODE_FULL

/******************************************************************************
  There is a compatibility issue for Hynix DDR4 SDRAM.
  Hynix DDR4 SDRAM is more weak on noise margin compared to Micron and Samsung DDR4.
  To well support Hynix DDR4, it requlres to slow down the DDR4 operating frequency
  from 1600Mbps to 1536/1488/1440 Mbps. The target frequency that can be used depends
  on the MB layout. Customer can find the appropriate frequency for their products.
  Below are the new defined parameters for the Hynix DDR4 supporting.
 ******************************************************************************/
#define CONFIG_DDR4_SUPPORT_HYNIX              @ Enable this when Hynix DDR4 included in the BOM
//#define CONFIG_DDR4_HYNIX_SET_1536
//#define CONFIG_DDR4_HYNIX_SET_1488
#define CONFIG_DDR4_HYNIX_SET_1440

#define ASTMMC_REGIDX_010    0x00
#define ASTMMC_REGIDX_014    0x04
#define ASTMMC_REGIDX_018    0x08
#define ASTMMC_REGIDX_020    0x0C
#define ASTMMC_REGIDX_024    0x10
#define ASTMMC_REGIDX_02C    0x14
#define ASTMMC_REGIDX_030    0x18
#define ASTMMC_REGIDX_214    0x1C
#define ASTMMC_REGIDX_2E0    0x20
#define ASTMMC_REGIDX_2E4    0x24
#define ASTMMC_REGIDX_2E8    0x28
#define ASTMMC_REGIDX_2EC    0x2C
#define ASTMMC_REGIDX_2F0    0x30
#define ASTMMC_REGIDX_2F4    0x34
#define ASTMMC_REGIDX_2F8    0x38
#define ASTMMC_REGIDX_RFC    0x3C
#define ASTMMC_REGIDX_PLL    0x40

TIME_TABLE_DDR3_1333:
    .word   0x53503C37       @ 0x010
    .word   0xF858D47F       @ 0x014
    .word   0x00010000       @ 0x018
    .word   0x00000000       @ 0x020
    .word   0x00000000       @ 0x024
    .word   0x02101C60       @ 0x02C
    .word   0x00000040       @ 0x030
    .word   0x00000020       @ 0x214
    .word   0x02001000       @ 0x2E0
    .word   0x0C000085       @ 0x2E4
    .word   0x000BA018       @ 0x2E8
    .word   0x2CB92104       @ 0x2EC
    .word   0x07090407       @ 0x2F0
    .word   0x81000700       @ 0x2F4
    .word   0x0C400800       @ 0x2F8
    .word   0x7F5E3A27       @ tRFC
    .word   0x00005B80       @ PLL
TIME_TABLE_DDR3_1600:
    .word   0x64604D38       @ 0x010
    .word   0x29690599       @ 0x014
    .word   0x00000300       @ 0x018
    .word   0x00000000       @ 0x020
    .word   0x00000000       @ 0x024
    .word   0x02181E70       @ 0x02C
    .word   0x00000040       @ 0x030
    .word   0x00000024       @ 0x214
    .word   0x02001300       @ 0x2E0
    .word   0x0E0000A0       @ 0x2E4
    .word   0x000E001B       @ 0x2E8
    .word   0x35B8C105       @ 0x2EC
    .word   0x08090408       @ 0x2F0
    .word   0x9B000800       @ 0x2F4
    .word   0x0E400A00       @ 0x2F8
    .word   0x9971452F       @ tRFC
    .word   0x000071C1       @ PLL

TIME_TABLE_DDR4_1333:
    .word   0x53503D26       @ 0x010
    .word   0xE878D87F       @ 0x014
    .word   0x00019000       @ 0x018
    .word   0x08000000       @ 0x020
    .word   0x00000400       @ 0x024
    .word   0x00000200       @ 0x02C
    .word   0x00000101       @ 0x030
    .word   0x00000020       @ 0x214
    .word   0x03002200       @ 0x2E0
    .word   0x0C000085       @ 0x2E4
    .word   0x000BA01A       @ 0x2E8
    .word   0x2CB92106       @ 0x2EC
    .word   0x07060606       @ 0x2F0
    .word   0x81000700       @ 0x2F4
    .word   0x0C400800       @ 0x2F8
    .word   0x7F5E3A3A       @ tRFC
    .word   0x00005B80       @ PLL
TIME_TABLE_DDR4_1600:
    .word   0x63604E37       @ 0x010
    .word   0xE97AFA99       @ 0x014
    .word   0x00019000       @ 0x018
    .word   0x08000000       @ 0x020
    .word   0x00000400       @ 0x024
    .word   0x00000410       @ 0x02C
#ifdef CONFIG_DDR4_SUPPORT_HYNIX
    .word   0x00000501       @ 0x030             @ ODT = 48 ohm
#else
    .word   0x00000101       @ 0x030             @ ODT = 60 ohm
#endif
    .word   0x00000024       @ 0x214
    .word   0x03002900       @ 0x2E0
    .word   0x0E0000A0       @ 0x2E4
    .word   0x000E001C       @ 0x2E8
    .word   0x35B8C106       @ 0x2EC
    .word   0x08080607       @ 0x2F0
    .word   0x9B000900       @ 0x2F4
    .word   0x0E400A00       @ 0x2F8
    .word   0x99714545       @ tRFC
    .word   0x000071C1       @ PLL

    .macro init_delay_timer
    ldr   r0, =0x1e782024                        @ Set Timer3 Reload
    str   r2, [r0]

    ldr   r0, =0x1e6c0038                        @ Clear Timer3 ISR
    ldr   r1, =0x00040000
    str   r1, [r0]

    ldr   r0, =0x1e782030                        @ Enable Timer3
    mov   r2, #7
    mov   r1, r2, lsl #8
    str   r1, [r0]

    ldr   r0, =0x1e6c0090                        @ Check ISR for Timer3 timeout
    .endm

    .macro check_delay_timer
    ldr   r1, [r0]
    bic   r1, r1, #0xFFFBFFFF
    mov   r2, r1, lsr #18
    cmp   r2, #0x01
    .endm

    .macro clear_delay_timer
    ldr   r0, =0x1e78203C                        @ Disable Timer3
    mov   r2, #0xF
    mov   r1, r2, lsl #8
    str   r1, [r0]

    ldr   r0, =0x1e6c0038                        @ Clear Timer3 ISR
    ldr   r1, =0x00040000
    str   r1, [r0]
    .endm

    .macro init_spi_checksum
    ldr   r0, =0x1e620084
    ldr   r1, =0x20010000
    str   r1, [r0]
    ldr   r0, =0x1e62008C
    ldr   r1, =0x20000200
    str   r1, [r0]
    ldr   r0, =0x1e620080
    ldr   r1, =0x0000000D
    orr   r2, r2, r7
    orr   r1, r1, r2, lsl #8
    and   r2, r6, #0xF
    orr   r1, r1, r2, lsl #4
    str   r1, [r0]
    ldr   r0, =0x1e620008
    ldr   r2, =0x00000800
    .endm

    .macro print_hex_char
    and   r1, r1, #0xF
    cmp   r1, #9
    addgt r1, r1, #0x37
    addle r1, r1, #0x30
    str   r1, [r0]
    .endm

/******************************************************************************
 Calibration Macro End
 ******************************************************************************/

.globl lowlevel_init
lowlevel_init:

init_dram:
    /********************************************
       Initial Reset Procedure : Begin
     *******************************************/
    /* Clear AHB bus lock condition */
    ldr   r0, =0x1e600000
    ldr   r1, =0xAEED1A03
    str   r1, [r0]
    ldr   r0, =0x1e600084
    ldr   r1, =0x00010000
    str   r1, [r0]
    add   r0, r0, #0x4
    mov   r1, #0x0
    str   r1, [r0]

    ldr   r0, =0x1e6e2000
    ldr   r1, =0x1688a8a8
    str   r1, [r0]

    /* Reset again */
    ldr   r0, =0x1e6e2070                        @ check fast reset flag
    ldr   r2, =0x08000000
    ldr   r1, [r0]
    tst   r1, r2
    beq   bypass_first_reset

    ldr   r0, =0x1e785010
    ldr   r3, [r0]
    cmp   r3, #0x0
    beq   start_first_reset
    add   r0, r0, #0x04
    mov   r3, #0x77
    str   r3, [r0]
    ldr   r0, =0x1e720004                        @ Copy initial strap register to 0x1e720004
    str   r1, [r0]
    add   r0, r0, #0x04                          @ Copy initial strap register to 0x1e720008
    str   r1, [r0]
    add   r0, r0, #0x04                          @ Copy initial strap register to 0x1e72000c
    str   r1, [r0]
    ldr   r0, =0x1e6e207c                        @ clear fast reset flag
    str   r2, [r0]
    ldr   r0, =0x1e6e203c                        @ clear watchdog reset flag
    ldr   r1, [r0]
    and   r1, r1, #0x01
    str   r1, [r0]
    ldr   r0, =0x1e78501c                        @ restore normal mask setting
    ldr   r1, =0x023FFFF3                        @ added 2016.09.06
    str   r1, [r0]
    b     bypass_first_reset

start_first_reset:
#ifdef ASTMMC_INIT_RESET_MODE_FULL
    ldr   r0, =0x1e785004
    ldr   r1, =0x00000001
    str   r1, [r0]
    ldr   r0, =0x1e785008
    ldr   r1, =0x00004755
    str   r1, [r0]
    ldr   r0, =0x1e78500c                        @ enable Full reset
    ldr   r1, =0x00000033
    str   r1, [r0]
#else
    /***** Clear LPC status : Begin *****/
    mov   r2, #0                                 @ set r2 = 0, freezed
    ldr   r0, =0x1e787008
    mov   r1, #0x7
    str   r1, [r0]
    ldr   r0, =0x1e78700c
    mov   r1, #0x3
    str   r1, [r0]
    ldr   r0, =0x1e787020
    str   r2, [r0]
    ldr   r0, =0x1e787034
    str   r2, [r0]
    ldr   r0, =0x1e787004
    str   r2, [r0]
    ldr   r0, =0x1e787010
    str   r2, [r0]
    ldr   r0, =0x1e78701c
    str   r2, [r0]
    ldr   r0, =0x1e787014                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e787018                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e787008                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e78301c                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e78d01c                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e78e01c                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e78f01c                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e788020
    str   r2, [r0]
    ldr   r0, =0x1e788034
    str   r2, [r0]
    ldr   r0, =0x1e78800c
    str   r2, [r0]
    ldr   r0, =0x1e789008
    str   r2, [r0]
    ldr   r0, =0x1e789010
    mov   r1, #0x40
    str   r1, [r0]
    ldr   r0, =0x1e789024                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e789028                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e78902c                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e789114                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e789124                        @ read clear
    ldr   r1, [r0]
    ldr   r0, =0x1e78903c
    str   r2, [r0]
    ldr   r0, =0x1e789040
    str   r2, [r0]
    ldr   r0, =0x1e789044
    str   r2, [r0]
    ldr   r0, =0x1e78911c
    str   r2, [r0]
    ldr   r0, =0x1e78912c
    ldr   r1, =0x200
    str   r1, [r0]
    ldr   r0, =0x1e789104
    ldr   r1, =0xcc00
    str   r1, [r0]
    ldr   r0, =0x1e789108
    str   r2, [r0]
    ldr   r0, =0x1e78910c
    ldr   r1, =0x1f0
    str   r1, [r0]
    ldr   r0, =0x1e789170
    str   r2, [r0]
    ldr   r0, =0x1e789174
    str   r2, [r0]
    ldr   r0, =0x1e7890a0
    ldr   r1, =0xff00
    str   r1, [r0]
    ldr   r0, =0x1e7890a4
    str   r2, [r0]
    ldr   r0, =0x1e789080
    ldr   r1, =0x400
    str   r1, [r0]
    ldr   r0, =0x1e789084
    ldr   r1, =0x0001000f
    str   r1, [r0]
    ldr   r0, =0x1e789088
    ldr   r1, =0x3000fff8
    str   r1, [r0]
    ldr   r0, =0x1e78908c
    ldr   r1, =0xfff8f007
    str   r1, [r0]
    ldr   r0, =0x1e789098
    ldr   r1, =0x00000a30
    str   r1, [r0]
    ldr   r0, =0x1e78909c
    str   r2, [r0]
    ldr   r0, =0x1e789100
    str   r2, [r0]
    ldr   r0, =0x1e789130
    ldr   r1, =0x00000080
    str   r1, [r0]
    ldr   r0, =0x1e789138
    ldr   r1, =0x00010198
    str   r1, [r0]
    ldr   r0, =0x1e789140
    ldr   r1, =0x0000a000
    str   r1, [r0]
    ldr   r0, =0x1e789158
    ldr   r1, =0x00000080
    str   r1, [r0]
    ldr   r0, =0x1e789180
    ldr   r1, =0xb6db1bff
    str   r1, [r0]
    ldr   r0, =0x1e789184
    str   r2, [r0]
    ldr   r0, =0x1e789188
    str   r2, [r0]
    ldr   r0, =0x1e78918c
    str   r2, [r0]
    ldr   r0, =0x1e789190
    ldr   r1, =0x05020100
    str   r1, [r0]
    ldr   r0, =0x1e789194
    ldr   r1, =0x07000706
    str   r1, [r0]
    ldr   r0, =0x1e789198
    str   r2, [r0]
    ldr   r0, =0x1e78919c
    ldr   r1, =0x30
    str   r1, [r0]
    ldr   r0, =0x1e7891a0
    ldr   r1, =0x00008100
    str   r1, [r0]
    ldr   r0, =0x1e7891a4
    ldr   r1, =0x2000
    str   r1, [r0]
    ldr   r0, =0x1e7891a8
    ldr   r1, =0x3ff
    str   r1, [r0]
    ldr   r0, =0x1e7891ac
    str   r2, [r0]
    ldr   r0, =0x1e789240
    mov   r1, #0xff
    str   r1, [r0]
    ldr   r0, =0x1e789244
    str   r1, [r0]
    ldr   r0, =0x1e789248
    mov   r1, #0x80
    str   r1, [r0]
    ldr   r0, =0x1e789250
    str   r2, [r0]
    ldr   r0, =0x1e789254
    str   r2, [r0]
    /***** Clear LPC status : End *****/

    ldr   r0, =0x1e62009c                        @ clear software strap flag for doing again after reset
    ldr   r1, =0xAEEDFC20
    str   r1, [r0]
    ldr   r0, =0x1e785004
    ldr   r1, =0x00000001
    str   r1, [r0]
    ldr   r0, =0x1e785008
    ldr   r1, =0x00004755
    str   r1, [r0]
    ldr   r0, =0x1e78501c                        @ enable full mask of SOC reset
    ldr   r1, =0x03FFFFFF                        @ added 2016.09.06
    str   r1, [r0]
    ldr   r0, =0x1e78500c                        @ enable SOC reset
    ldr   r1, =0x00000013
    str   r1, [r0]
#endif
wait_first_reset:
    b     wait_first_reset

    /********************************************
       Initial Reset Procedure : End
     *******************************************/

bypass_first_reset:
    /* Enable Timer separate clear mode */
    ldr   r0, =0x1e782038
    mov   r1, #0xAE
    str   r1, [r0]

/* Test - DRAM initial time */
    ldr   r0, =0x1e78203c
    ldr   r1, =0x0000F000
    str   r1, [r0]

    ldr   r0, =0x1e782044
    ldr   r1, =0xFFFFFFFF
    str   r1, [r0]

    ldr   r0, =0x1e782030
    mov   r2, #3
    mov   r1, r2, lsl #12
    str   r1, [r0]
/* Test - DRAM initial time */

    /*Set Scratch register Bit 7 before initialize*/
    ldr   r0, =0x1e6e2000
    ldr   r1, =0x1688a8a8
    str   r1, [r0]

    ldr   r0, =0x1e6e2040
    ldr   r1, [r0]
    orr   r1, r1, #0x80
    str   r1, [r0]

    /* Change LPC reset source to PERST# when eSPI mode enabled */
    ldr   r0, =0x1e6e2070
    ldr   r1, [r0]
    ldr   r0, =0x1e6e207c
    ldr   r2, =0x02000000
    ldr   r3, =0x00004000
    tst   r1, r2
    strne r3, [r0]

    /* Configure USB ports to the correct pin state */
    ldr   r0, =0x1e6e200c                        @ enable portA clock
    ldr   r2, =0x00004000
    ldr   r1, [r0]
    orr   r1, r1, r2
    str   r1, [r0]
    ldr   r0, =0x1e6e2090                        @ set portA as host mode
    ldr   r1, =0x2000A000
    str   r1, [r0]
    ldr   r0, =0x1e6e2094                        @ set portB as host mode
    ldr   r1, =0x00004000
    str   r1, [r0]
    ldr   r0, =0x1e6e2070
    ldr   r2, =0x00800000
    ldr   r1, [r0]
    tst   r1, r2
    beq   bypass_USB_init
    ldr   r0, =0x1e6e207c
    str   r2, [r0]

    /* Delay about 1ms */
    clear_delay_timer
    ldr   r2, =0x000003E8                        @ Set Timer3 Reload = 1 ms
    init_delay_timer
wait_usb_init:
    check_delay_timer
    bne   wait_usb_init
    clear_delay_timer
    /* end delay 1ms */

    ldr   r0, =0x1e6e2070
    ldr   r1, =0x00800000
    str   r1, [r0]

bypass_USB_init:
    /* Enable AXI_P */
    ldr   r0, =0x00000016
    mrc   p15, 0, r1, c15, c2, 4
    mcr   p15, 0, r0, c15, c2, 4

/******************************************************************************
 Disable WDT2 for 2nd boot function
 ******************************************************************************/
/*
#ifndef CONFIG_FIRMWARE_2ND_BOOT
    ldr   r0, =0x1e78502c
    mov   r1, #0
    str   r1, [r0]
#endif
*/
/******************************************************************************
 Disable WDT3 for SPI Address mode (3 or 4 bytes) detection function
 ******************************************************************************/
    ldr   r0, =0x1e78504c
    mov   r1, #0
    str   r1, [r0]

    ldr   r0, =0x1e6e0000
    ldr   r1, =0xFC600309
    str   r1, [r0]
    
#ifdef CONFIG_SPL_BUILD
    /* SPL: leave the rest to U-Boot proper */
    mov   pc, lr
#endif
/******************************************************************************
 SPI Timing Calibration
 ******************************************************************************/
    mov   r2, #0x0
    mov   r6, #0x0
    mov   r7, #0x0
    init_spi_checksum
spi_checksum_wait_0:
    ldr   r1, [r0]
    tst   r1, r2
    beq   spi_checksum_wait_0
    ldr   r0, =0x1e620090
    ldr   r5, [r0]                               @ record golden checksum
    ldr   r0, =0x1e620080
    mov   r1, #0x0
    str   r1, [r0]

    ldr   r0, =0x1e620010                        @ set to fast read mode
    ldr   r1, =0x000B0041
    str   r1, [r0]

    ldr   r6, =0x00F7E6D0                        @ Init spiclk loop
    mov   r8, #0x0                               @ Init delay record

spi_cbr_next_clkrate:
    mov   r6, r6, lsr #0x4
    cmp   r6, #0x0
    beq   spi_cbr_end

    mov   r7, #0x0                               @ Init delay loop
    mov   r8, r8, lsl #4

spi_cbr_next_delay_s:
    mov   r2, #0x8
    init_spi_checksum
spi_checksum_wait_1:
    ldr   r1, [r0]
    tst   r1, r2
    beq   spi_checksum_wait_1
    ldr   r0, =0x1e620090
    ldr   r2, [r0]                               @ read checksum
    ldr   r0, =0x1e620080
    mov   r1, #0x0
    str   r1, [r0]
    cmp   r2, r5
    bne   spi_cbr_next_delay_e

    mov   r2, #0x0
    init_spi_checksum
spi_checksum_wait_2:
    ldr   r1, [r0]
    tst   r1, r2
    beq   spi_checksum_wait_2
    ldr   r0, =0x1e620090
    ldr   r2, [r0]                               @ read checksum
    ldr   r0, =0x1e620080
    mov   r1, #0x0
    str   r1, [r0]
    cmp   r2, r5
    bne   spi_cbr_next_delay_e

    orr   r8, r8, r7                             @ record passed delay
    b     spi_cbr_next_clkrate

spi_cbr_next_delay_e:
    add   r7, r7, #0x1
    cmp   r7, #0x6
    blt   spi_cbr_next_delay_s
    b     spi_cbr_next_clkrate

spi_cbr_end:
    ldr   r0, =0x1e620094
    str   r8, [r0]
    ldr   r0, =0x1e620010
    mov   r1, #0x0
    str   r1, [r0]

/******************************************************************************
 Miscellaneous Setting
 ******************************************************************************/
    /* Set UART DMA as AHB high priority master */
    ldr   r0, =0x1e600000
    ldr   r1, =0xAEED1A03
    str   r1, [r0]

    ldr   r0, =0x1e600080
    ldr   r2, =0x100
    ldr   r1, [r0]
    orr   r1, r1, r2
    str   r1, [r0]

    /* Enable UART3/4 clock and disable LHCLK */
    ldr   r0, =0x1e6e200c
    ldr   r1, [r0]
    ldr   r2, =0xF9FFFFFF
    and   r1, r1, r2
    ldr   r2, =0x10000000
    orr   r1, r1, r2
    str   r1, [r0]

    ldr   r0, =0x1e6e2008                        @ Set Video ECLK phase
    ldr   r1, [r0]
    ldr   r2, =0x0ffffff3
    and   r1, r1, r2
    str   r1, [r0]

    ldr r0, =0x1e6e2004                          @ Enable JTAG Master, solve ARM stucked by JTAG issue
    ldr r1, [r0]
    bic r1, r1, #0x00400000
    str r1, [r0]

/******************************************************************************
 Configure MAC timing
 ******************************************************************************/
    /* Enable D2PLL and set to 250MHz */
    ldr   r0, =0x1e6e213c
    ldr   r1, =0x00000585                        @ Reset D2PLL
    str   r1, [r0]

    ldr   r0, =0x1e6e202c
    ldr   r1, [r0]
    bic   r1, r1, #0x10                          @ Enable D2PLL
    ldr   r2, =0x00200000                        @ Set CRT = 40MHz
    orr   r1, r1, r2
    str   r1, [r0]

    ldr   r2, =0x8E00A17C                        @ Set to 250MHz

    ldr   r0, =0x1e6e2070                        @ Check CLKIN = 25MHz
    ldr   r1, [r0]
    mov   r1, r1, lsr #23
    tst   r1, #0x01
    beq   set_D2PLL
    ldr   r2, =0x8E00A177

set_D2PLL:
    ldr   r0, =0x1e6e201c
    str   r2, [r0]
    ldr   r0, =0x1e6e213c                        @ Enable D2PLL
    ldr   r1, =0x00000580
    str   r1, [r0]

    ldr   r0, =0x1e6e204c
    ldr   r1, [r0]
    bic   r1, r1, #0xFF0000
    ldr   r2, =0x00040000                        @ Set divider ratio
    orr   r1, r1, r2
    str   r1, [r0]

    ldr   r0, =0x1e6e2048                        @ Set MAC interface delay timing = 1G
    ldr   r1, =0x80082208                        @ Select internal 125MHz
    str   r1, [r0]
    ldr   r0, =0x1e6e20b8                        @ Set MAC interface delay timing = 100M
    str   r1, [r0]
    ldr   r0, =0x1e6e20bc                        @ Set MAC interface delay timing = 10M
    str   r1, [r0]

    ldr   r0, =0x1e6e2070                        @ Set MAC AHB bus clock
    ldr   r1, [r0]
    mov   r2, #0x04                              @ Default RMII, set MHCLK = HPLL/10
    tst   r1, #0xC0
    movne r2, #0x02                              @ if RGMII,     set MHCLK = HPLL/6
    ldr   r0, =0x1e6e2008
    ldr   r1, [r0]
    bic   r1, r1, #0x00070000
    orr   r1, r1, r2, lsl #16
    str   r1, [r0]

    ldr   r0, =0x1e6e21dc                        @ Set MAC duty
    ldr   r1, =0x00666400
    str   r1, [r0]

    ldr   r0, =0x1e6e2090                        @ Enable MAC interface pull low
    ldr   r1, [r0]
    bic   r1, r1, #0x0000F000
    bic   r1, r1, #0x20000000                    @ Set USB portA as Device mode
    str   r1, [r0]

    /* Disable Timer separate mode */
    ldr   r0, =0x1e782038
    ldr   r1, =0xEA
    str   r1, [r0]

    /* back to arch calling code */
    mov   pc, lr

