/*
 * mmregs.h 
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
#ifndef _MMREGS_H
#define _MMREGS_H

/* IDMA Control */
#define IDMA_CONTROL          0x3fe0

/* BDMA Internal Address */
#define BDMA_BIAD             0x3fe1

/* BDMA External Address */
#define BDMA_BEAD             0x3fe2

/* BDMA Control */
#define BDMA_CONTROL          0x3fe3
#define BDMA_BTYPE            0x0003
#define BDMA_BTYPE_SHIFT      0x0000
#define BDMA_BTYPE_PM24       0x0000
#define BDMA_BTYPE_DM16       0x0001
#define BDMA_BTYPE_DM8MSB     0x0002
#define BDMA_BTYPE_DM8LSB     0x0003
#define BDMA_BDIR_LOAD        0x0004
#define BDMA_BDIR_LOAD_SHIFT  0x0000
#define BDMA_BDIR_STORE       0x0004
#define BDMA_BCR              0x0008
#define BDMA_BCR_RUN          0x0000
#define BDMA_BCR_HALT         0x0008
#define BDMA_BMPAGE           0xff00
#define BDMA_BMPAGE_SHIFT     0x0008

/* BDMA Word Count */
#define BDMA_BWCOUNT          0x3fe4

/* Programmable Flag data */
#define PFDATA                0x3fe5

/* Programmable Flag and Composite Select Control */
#define PFCS_CONTROL          0x3fe6
#define PFCS_PFTYPE           0x00ff
#define PFCS_PFTYPE_SHIFT     0x0000
#define PFCS_CMSSEL           0x0f00
#define PFCS_CMSSEL_SHIFT     0x0800
#define PFCS_CMSSEL_PM        0x0100
#define PFCS_CMSSEL_DM        0x0200
#define PFCS_CMSSEL_BM        0x0400
#define PFCS_CMSSEL_IOM       0x0800
#define PFCS_BMWAIT           0x7000
#define PFCS_BMWAIT_SHIFT     0x000c

/* SPORT Autobuffer Control Register */
#define SPORT0_AUTO           0x3ff3
#define SPORT1_AUTO           0x3fef

/* SPORT general auto buffer control */
#define SPORT_AUTO_RBUF      0x0001
#define SPORT_AUTO_TBUF      0x0002
#define SPORT_AUTO_RMREG     0x000c
#define SPORT_AUTO_RMREG_SHIFT   0x0002
#define SPORT_AUTO_RIREG     0x0070
#define SPORT_AUTO_RIREG_SHIFT   0x0004
#define SPORT_AUTO_TMREG     0x0180
#define SPORT_AUTO_TMREG_SHIFT   0x0007
#define SPORT_AUTO_TIREG     0x0e00
#define SPORT_AUTO_TIREG_SHIFT   0x0009
#define SPORT_AUTO_RREG(i,m) \
    ((((i) << SPORT_AUTO_RIREG_SHIFT) & SPORT_AUTO_RIREG) | \
     (((m) << SPORT_AUTO_RMREG_SHIFT) & SPORT_AUTO_RMREG) | \
     SPORT_AUTO_RBUF)
#define SPORT_AUTO_TREG(i,m) \
    ((((i) << SPORT_AUTO_TIREG_SHIFT) & SPORT_AUTO_TIREG) | \
     (((m) << SPORT_AUTO_TMREG_SHIFT) & SPORT_AUTO_TMREG) | \
     SPORT_AUTO_TBUF)

/* SPORT specific control */
#define SPORT0_AUTO_BIASRND   0x1000
#define SPORT0_AUTO_CLKODIS   0x4000

#define SPORT1_AUTO_PUCR      0x1000
#define SPORT1_AUTO_PDFORCE   0x2000
#define SPORT1_AUTO_XTALDELAY 0x4000
#define SPORT1_AUTO_XTALDIS   0x8000

/* SPORT1 Receive Frame Sync Divide Modulus */
#define SPORT0_RFSDIV         0x3ff4
#define SPORT1_RFSDIV         0x3ff0

/* SPORT1 Serial Clock Divide Modulus */
#define SPORT0_SCLKDIV        0x3ff5
#define SPORT1_SCLKDIV        0x3ff1

/* SPORT Control Register */
#define SPORT1_CTRL           0x3ff2
#define SPORT0_CTRL           0x3ff6
#define SPORT_CTRL_SLEN       0x000f
#define SPORT_CTRL_SLEN_SHIFT 0x0000
#define SPORT_CTRL_SLEN_SET(n) \
    (((n)-1) & SPORT_CTRL_SLEN)
#define SPORT_CTRL_DTYPE      0x0030
#define SPORT_CTRL_DTYPE_SHIFT  0x0004
#define SPORT_CTRL_DTYPE_ZERO (0 << SPORT_CTRL_DTYPE_SHIFT)
#define SPORT_CTRL_DTYPE_EXTEND    (1 << SPORT_CTRL_DTYPE_SHIFT)
#define SPORT_CTRL_DTYPE_MU   (2 << SPORT_CTRL_DTYPE_SHIFT)
#define SPORT_CTRL_DTYPE_A    (3 << SPORT_CTRL_DTYPE_SHIFT)
#define SPORT_CTRL_INVRFS     0x0040
#define SPORT_CTRL_INVTFS     0x0080
#define SPORT_CTRL_IRFS       0x0100
#define SPORT_CTRL_ITFS       0x0200
#define SPORT_CTRL_TFSW       0x0400
#define SPORT_CTRL_TFSR       0x0800
#define SPORT_CTRL_RFSW       0x1000
#define SPORT_CTRL_RFSR       0x2000
#define SPORT_CTRL_ISCLK      0x4000

/* SPORT1 specific */
#define SPORT1_CTRL_FLAG_OUT  0x8000

/* SPORT0 Multichannel */
#define SPORT0_CTRL_MCE       0x8000
#define SPORT0_CTRL_MCL       0x0200
#define SPORT0_CTRL_MCL_24    0x0000
#define SPORT0_CTRL_MCL_32    SPORT0_CTRL_MCL
#define SPORT0_CTRL_MFD       0x3c00
#define SPORT0_CTRL_MFD_SHIFT 0x000a
#define SPORT0_CTRL_MFD_SET(n) \
    (((n) << SPORT0_CTRL_MFD_SHIFT) & SPORT0_CTRL_MFD)

/* SPORT0 Multichannel Word Enables */
#define SPORT0_TX_CHANS_LO    0x3ff7
#define SPORT0_TX_CHANS_HI    0x3ff8
#define SPORT0_RX_CHANS_LO    0x3ff9
#define SPORT0_RX_CHANS_HI    0x3ffa

/* TSCALE Scaling Register */
#define TSCALE                0x3ffb

/* TCOUNT Count Register */
#define TCOUNT                0x3ffc

/* TPERIOD Period Register */
#define TPERIOD               0x3ffd

/* Waitstate Control Register */
#define WAITSTATE             0x3ffe
#define WAITSTATE_IO0         0x0007
#define WAITSTATE_IO0_SHIFT   0x0000
#define WAITSTATE_IO1         0x0038
#define WAITSTATE_IO1_SHIFT   0x0003
#define WAITSTATE_IO2         0x01c0
#define WAITSTATE_IO2_SHIFT   0x0006
#define WAITSTATE_IO3         0x0e00
#define WAITSTATE_IO3_SHIFT   0x0009
#define WAITSTATE_D           0x7000
#define WAITSTATE_D_SHIFT     0x000c
#define WAITSTATE_SET(d,io3,io2,io1,io0) \
    ((((d) << WAITSTATE_D_SHIFT) & WAITSTATE_D) | \
     (((io3) << WAITSTATE_IO3_SHIFT) & WAITSTATE_IO3) | \
     (((io2) << WAITSTATE_IO2_SHIFT) & WAITSTATE_IO2) | \
     (((io1) << WAITSTATE_IO1_SHIFT) & WAITSTATE_IO1) | \
     (((io0) << WAITSTATE_IO0_SHIFT) & WAITSTATE_IO0))

/* System Control Register */
#define SYS_CTRL              0x3fff
#define SYS_PWAIT             0x0007
#define SYS_PWAIT_SHIFT       0x0000
#define SYS_SPORT1_CONFIG     0x0400
#define SYS_SPORT1_CONFIG_SERIAL  SYS_SPORT1_CONFIG
#define SYS_SPORT1_ENA        0x0800
#define SYS_SPORT0_ENA        0x1000

#endif
