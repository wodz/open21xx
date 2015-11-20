/*
 * registers.h 
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
#ifndef _REGISTERS_H
#define _REGISTERS_H

/* arithmetic status bits */
#define ASTAT_AZ                0x01
#define ASTAT_AN                0x02
#define ASTAT_AV                0x04
#define ASTAT_AC                0x08
#define ASTAT_AS                0x10
#define ASTAT_AQ                0x20
#define ASTAT_MV                0x40
#define ASTAT_SS                0x80

/* Stack status bits */
#define SSTAT_PC_EMPTY          0x01
#define SSTAT_PC_OVERFLOW       0x02
#define SSTAT_COUNT_EMPTY       0x04
#define SSTAT_COUNT_OVERFLOW    0x08
#define SSTAT_STATUS_EMPTY      0x10
#define SSTAT_STATUS_OVERFLOW   0x20
#define SSTAT_LOOP_EMPTY        0x40
#define SSTAT_LOOP_OVERFLOW     0x80

/* Mode status bits */
#define MSTAT_BANK              0x01
#define MSTAT_BANK_PRIMARY      0x00
#define MSTAT_BANK_SECONDARY    0x01
#define MSTAT_BIT_REVERSE       0x02
#define MSTAT_ALU_OVERFLOW      0x04
#define MSTAT_AR_SAT            0x08
#define MSTAT_MAC_PLACE         0x10
#define MSTAT_TIMER_ENA         0x20
#define MSTAT_GO_ENA            0x40

/* Interrupt control */
#define ICNTL_IRQ0              0x01
#define ICNTL_IRQ0_LEVEL        0x00
#define ICNTL_IRQ0_EDGE         0x01
#define ICNTL_IRQ1              0x02
#define ICNTL_IRQ1_LEVEL        0x00
#define ICNTL_IRQ1_EDGE         0x02
#define ICNTL_IRQ2              0x04
#define ICNTL_IRQ2_LEVEL        0x00
#define ICNTL_IRQ2_EDGE         0x04
#define ICNTL_NESTING_ENA       0x10

/* Interrupt Mask bits */
#define IMASK_TIMER             0x001
#define IMASK_SPORT1_RX         0x002
#define IMASK_IRQ0              0x002
#define IMASK_SPORT1_TX         0x004
#define IMASK_IRQ1              0x004
#define IMASK_BDMA              0x008
#define IMASK_IRQE              0x010
#define IMASK_SPORT0_RX         0x020
#define IMASK_SPORT0_TX         0x040
#define IMASK_IRQL0             0x080
#define IMASK_IRQL1             0x100
#define IMASK_IRQ2              0x200

#define IFC_CLEAR_TIMER         0x0001
#define IFC_CLEAR_SPORT1_RX     0x0002
#define IFC_CLEAR_IRQ0          0x0002
#define IFC_CLEAR_SPORT1_TX     0x0004
#define IFC_CLEAR_IRQ1          0x0004
#define IFC_CLEAR_BDMA          0x0008
#define IFC_CLEAR_IRQE          0x0010
#define IFC_CLEAR_SPORT0_RX     0x0020
#define IFC_CLEAR_SPORT0_TX     0x0040
#define IFC_CLEAR_IRQ2          0x0080
#define IFC_CLEAR_ALL \
    (IFC_CLEAR_TIMER | IFC_CLEAR_SPORT1_RX | \
     IFC_CLEAR_IRQ0 | IFC_CLEAR_SPORT1_TX |  \
     IFC_CLEAR_IRQ1 | IFC_CLEAR_BDMA |       \
     IFC_CLEAR_IRQE | IFC_CLEAR_SPORT0_RX |  \
     IFC_CLEAR_SPORT0_TX | IFC_CLEAR_IRQ2 )

#define IFC_FORCE_TIMER         0x0100
#define IFC_FORCE_SPORT1_RX     0x0200
#define IFC_FORCE_IRQ0          0x0200
#define IFC_FORCE_SPORT1_TX     0x0400
#define IFC_FORCE_IRQ1          0x0400
#define IFC_FORCE_BDMA          0x0800
#define IFC_FORCE_IRQE          0x1000
#define IFC_FORCE_SPORT0_RX     0x2000
#define IFC_FORCE_SPORT0_TX     0x4000
#define IFC_FORCE_IRQ2          0x8000

#endif
