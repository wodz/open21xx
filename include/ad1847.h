/*
 * ad1847.h 
 * 
 * Part of the Open21xx assembler toolkit
 * 
 * Copyright (C) 2002 by Keith B. Clifford 
 * 
 * The Open21xx toolkit is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as published
 * by the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * The Open21xx toolkit is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Open21xx toolkit; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
#ifndef _AD1847_H
#define _AD1847_H

/* control word */
#define AD1847_CTRL_CLOR        0x8000
#define AD1847_CTRL_MCE         0x4000
#define AD1847_CTRL_RREQ        0x2000
#define AD1847_CTRL_IA          0x0f00
#define AD1847_CTRL_IA_SHIFT    0x0008
#define AD1847_CTRL_DATA        0x00ff
#define AD1847_CTRL_DATA_SHIFT  0x0000

/* status word */
#define AD1847_STAT_RREQ        0x2000
#define AD1847_STAT_ID          0x0f00
#define AD1847_STAT_ID_SHIFT    0x0008
#define AD1847_STAT_ORR         0x0030
#define AD1847_STAT_ORL         0x000c
#define AD1847_STAT_ACI         0x0002
#define AD1847_STAT_INIT        0x0001

/* index readback */
#define AD1847_IRB_CLOR         0x8000
#define AD1847_IRB_MCE          0x4000
#define AD1847_IRB_RREQ         0x2000
#define AD1847_IRB_IA           0x0f00
#define AD1847_IRB_IA_SHIFT     0x0008
#define AD1847_IRB_DATA         0x00ff
#define AD1847_IRB_DATA_SHIFT   0x0000

/* indirect mapped registers */
#define AD1847_INL              0x0000
#define AD1847_INR              0x0100
#define AD1847_AUX1L            0x0200
#define AD1847_AUX1R            0x0300
#define AD1847_AUX2L            0x0400
#define AD1847_AUX2R            0x0500
#define AD1847_DACL             0x0600
#define AD1847_DACR             0x0700
#define AD1847_DFMT             0x0800
#define AD1847_IFACE            0x0900
#define AD1847_PIN              0x0a00
#define AD1847_MISC             0x0c00
#define AD1847_DMIX             0x0d00
#define AD1847_NOREG            0x0f00

/* left and right input control registers */
/* source select */
#define AD1847_IN_SS            0xc0
#define AD1847_IN_SS_LINE1      0x00
#define AD1847_IN_SS_AUX1       0x40
#define AD1847_IN_SS_LINE2      0x80
#define AD1847_IN_SS_LINE1LB    0xc0

/* 
 * for all GAIN_SET macros use gain x 10
 * ie. for 1.5db use GAIN_SET(15)
 */

/* input gain select */
#define AD1847_IN_GAIN          0x0f
#define AD1847_IN_GAIN_SET(x)  \
     (((x)/15) & AD1847_IN_GAIN)

/* Mute for all aux and DAC control registers */
#define AD1847_MUTE             0x80

/* left and right aux 1 and 2 input control registers */
#define AD1847_AUX_GAIN         0x1f
#define AD1847_AUX_GAIN_SET(x) \
    (((-(x)+120)/15) & AD1847_AUX_GAIN)

/* left and right DAC control registers */
#define AD1847_DAC_ATTN         0x3f
#define AD1847_DAC_ATTN_SET(x) \
    ((-(x)/15) & AD1847_DAC_ATTN)

/* data format register */
#define AD1847_DFMT_XTAL1       0x00
#define AD1847_DFMT_XTAL2       0x01
#define AD1847_DFMT_CFS_3072    0x00
#define AD1847_DFMT_CFS_1536    0x02
#define AD1847_DFMT_CFS_896     0x04
#define AD1847_DFMT_CFS_768     0x06
#define AD1847_DFMT_CFS_448     0x08
#define AD1847_DFMT_CFS_384     0x0a
#define AD1847_DFMT_CFS_512     0x0c
#define AD1847_DFMT_CFS_2560    0x0e
#define AD1847_DFMT_MONO        0x00
#define AD1847_DFMT_STEREO      0x10
#define AD1847_DFMT_ALAW        0x60
#define AD1847_DFMT_MULAW       0x20
#define AD1847_DFMT_LINEAR8     0x00
#define AD1847_DFMT_LINEAR16    0x40
#define AD1847_DFMT_COMPAND     0x20

/* sampling rates using the standard crystal frequencies of
 * 24.567 MHz and 16.9344 MHz for XTAL1 and XTAL2 respectivly */
#define AD1847_DFMT_5K5125      (AD1847_DFMT_XTAL2 | AD1847_DFMT_CFS_3072)
#define AD1847_DFMT_6K615       (AD1847_DFMT_XTAL2 | AD1847_DFMT_CFS_2560)
#define AD1847_DFMT_8K          (AD1847_DFMT_XTAL1 | AD1847_DFMT_CFS_3072)
#define AD1847_DFMT_9K6         (AD1847_DFMT_XTAL1 | AD1847_DFMT_CFS_2560)
#define AD1847_DFMT_11K025      (AD1847_DFMT_XTAL2 | AD1847_DFMT_CFS_1536)
#define AD1847_DFMT_16K         (AD1847_DFMT_XTAL1 | AD1847_DFMT_CFS_1536)
#define AD1847_DFMT_18K9        (AD1847_DFMT_XTAL2 | AD1847_DFMT_CFS_896)
#define AD1847_DFMT_22K05       (AD1847_DFMT_XTAL2 | AD1847_DFMT_CFS_768)
#define AD1847_DFMT_27K42857    (AD1847_DFMT_XTAL1 | AD1847_DFMT_CFS_896)
#define AD1847_DFMT_32K         (AD1847_DFMT_XTAL1 | AD1847_DFMT_CFS_768)
#define AD1847_DFMT_33K075      (AD1847_DFMT_XTAL2 | AD1847_DFMT_CFS_512)
#define AD1847_DFMT_37K8        (AD1847_DFMT_XTAL2 | AD1847_DFMT_CFS_448)
#define AD1847_DFMT_44K1        (AD1847_DFMT_XTAL2 | AD1847_DFMT_CFS_384)
#define AD1847_DFMT_48K         (AD1847_DFMT_XTAL1 | AD1847_DFMT_CFS_512)

/* interface configuration register */
#define AD1847_IFACE_PEN        0x01
#define AD1847_IFACE_ACAL       0x08

/* pin control register */
#define AD1847_PIN_CLKTS        0x20
#define AD1847_PIN_XCTL1        0x80
#define AD1847_PIN_XCTL0        0x40

/* miscellaneous information register */
#define AD1847_MISC_FRS         0x80
#define AD1847_MISC_32_SLOT     0x00
#define AD1847_MISC_16_SLOT     AD1847_MISC_FRS
#define AD1847_MISC_TSSEL       0x40
#define AD1847_MISC_1_WIRE      0x00
#define AD1847_MISC_2_WIRE      AD1847_MISC_TSSEL

/* digital mix control register */
#define AD1847_DMIX_ENA         0x01
#define AD1847_DMIX_DIS         0x00
#define AD1847_DMIX_ATTN        0xfc
#define AD1847_DMIX_ATTN_SET(x)   \
    (((-(x)/15) << 2) & AD1847_DMIX_ATTN)

.extern ad1847Init, ad1847RxInt, ad1847TxInt;

#endif
