/*
 * adielf.h 
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

/*
 * ADI extension to the standard ELF file
 */
#ifndef _ADIELF_H
#define _ADIELF_H

/* Machine field additions */
#define EM_ADSP218X         (0x6423)
#define EM_ADSP219X         (0x6424)

#define EF_ADSP2100         (0x0001)
#define EF_ADSP217X         (0x0002)
#define EF_ADSP218X         (0x0004)

#if 0

#define R_ADSP218x_NONE     0

/* address of relocations */
#define R_ADSP218X_IMM14    1
#define R_ADSP218X_IMM16    2
#define R_ADSP218X_DATADM   3
#define R_ADSP218X_DATAPM   4
#define R_ADSP218X_DATA24   5

/* PAGE() of the above relocations */
#define R_ADSP218X_IMM14PG  6
#define R_ADSP218X_IMM16PG  7
#define R_ADSP218X_DATADMPG 8
#define R_ADSP218X_DATAPMPG 9
#define R_ADSP218X_DATA24PG 10

/* relocations for which PAGE() doesn't make sense */
#define R_ADSP218X_FLAGIN   11
#define R_ADSP218X_PM14     12
#define R_ADSP218X_DM14     13

#define R_ADSP218X_PAGE(page,rel) \
    (page) ? (rel) + (R_ADSP218X_IMM14PG - R_ADSP218X_IMM14) : \
    (rel)

#define R_ADSP219x_NONE     0

/* address of relocations */
#define R_ADSP219X_IMM12    1
#define R_ADSP219X_IMM16    2
#define R_ADSP219X_DATADM   3
#define R_ADSP219X_DATAPM   4
#define R_ADSP219X_DATA24   5
#define R_ADSP219X_DMLOAD   6
#define R_ADSP219X_PMLOAD   7

/* PAGE() of the above relocations */
#define R_ADSP219X_IMM12PG  8
#define R_ADSP219X_IMM16PG  9
#define R_ADSP219X_DATADMPG 10
#define R_ADSP219X_DATAPMPG 11
#define R_ADSP219X_DATA24PG 12
#define R_ADSP219X_DMLOADPG 13
#define R_ADSP219X_PMLOADPG 14

/* relocations for which PAGE() doesn't make sense */
#define R_ADSP219X_DO       15
#define R_ADSP219X_REL      16
#define R_ADSP219X_LONG     17
#define R_ADSP219X_DM16     18

#define R_ADSP219X_PAGE(page,rel) \
    (page) ? (rel) + (R_ADSP219X_IMM12PG - R_ADSP219X_IMM12) : \
    (rel)

#else
enum REL_TYPE
{
    SYMBOL_SHIFT          = 0,
    SYMBOL_MASK           = 0x07 << SYMBOL_SHIFT,
    SYMBOL_SYMBOL         = 0x00 << SYMBOL_SHIFT,
    SYMBOL_LENGTH_OF      = 0x01 << SYMBOL_SHIFT,
    /* 21xx specific */
    SYMBOL_ADDRESS_OF     = 0x02 << SYMBOL_SHIFT,
    SYMBOL_PAGE_OF        = 0x03 << SYMBOL_SHIFT,
    
    /* relocation types with the msb are part of an expression and don't modify code */
    EXPRESSION_SHIFT          = 0x3,
    EXPRESSION_MASK           = 0x1f << EXPRESSION_SHIFT,
    EXPRESSION_PUSH           = 0 << EXPRESSION_SHIFT,
    EXPRESSION_NEGATE         = 1 << EXPRESSION_SHIFT,
    EXPRESSION_LOGICAL_NOT    = 2 << EXPRESSION_SHIFT,
    EXPRESSION_BITWISE_NOT    = 3 << EXPRESSION_SHIFT,
    EXPRESSION_LAST_UNARY     = EXPRESSION_BITWISE_NOT,
    EXPRESSION_MULTIPLY       = 4 << EXPRESSION_SHIFT,
    EXPRESSION_DIVIDE         = 5 << EXPRESSION_SHIFT,
    EXPRESSION_MOD            = 6 << EXPRESSION_SHIFT,
    EXPRESSION_ADD            = 7 << EXPRESSION_SHIFT,
    EXPRESSION_SUBTRACT       = 8 << EXPRESSION_SHIFT,
    EXPRESSION_SHIFT_UP       = 9 << EXPRESSION_SHIFT,
    EXPRESSION_SHIFT_DOWN     = 10 << EXPRESSION_SHIFT,
    EXPRESSION_LESS           = 11 << EXPRESSION_SHIFT,
    EXPRESSION_LESS_EQUAL     = 12 << EXPRESSION_SHIFT,
    EXPRESSION_GREATER        = 13 << EXPRESSION_SHIFT,
    EXPRESSION_GREATER_EQUAL  = 14 << EXPRESSION_SHIFT,
    EXPRESSION_EQUAL          = 15 << EXPRESSION_SHIFT,
    EXPRESSION_NOT_EQUAL      = 16 << EXPRESSION_SHIFT,
    EXPRESSION_BITWISE_AND    = 17 << EXPRESSION_SHIFT,
    EXPRESSION_BITWISE_XOR    = 18 << EXPRESSION_SHIFT,
    EXPRESSION_BITWISE_OR     = 19 << EXPRESSION_SHIFT,
    EXPRESSION_LOGICAL_AND    = 20 << EXPRESSION_SHIFT,
    EXPRESSION_LOGICAL_OR     = 21 << EXPRESSION_SHIFT,
    /* reverse operators */
    EXPRESSION_RDIVIDE        = 22 << EXPRESSION_SHIFT,
    EXPRESSION_RMOD           = 23 << EXPRESSION_SHIFT,
    EXPRESSION_RSUBTRACT      = 24 << EXPRESSION_SHIFT,
    EXPRESSION_RSHIFT_UP      = 25 << EXPRESSION_SHIFT,
    EXPRESSION_RSHIFT_DOWN    = 26 << EXPRESSION_SHIFT,
    EXPRESSION_LAST           = EXPRESSION_RSHIFT_DOWN,
    /* internal relocation types - they must never appear in the output */
    EXPRESSION_SYMBOLIC       = 0x1f << EXPRESSION_SHIFT,
    
    /* ADSP218x relocation types */
    R_ADSP218X_NONE           = 0 << EXPRESSION_SHIFT,
    R_ADSP218X_IMM14          = 1 << EXPRESSION_SHIFT,
    R_ADSP218X_IMM16          = 2 << EXPRESSION_SHIFT,
    R_ADSP218X_DATADM         = 3 << EXPRESSION_SHIFT,
    R_ADSP218X_DATAPM         = 4 << EXPRESSION_SHIFT,
    R_ADSP218X_DATA24         = 5 << EXPRESSION_SHIFT,
    R_ADSP218X_FLAGIN         = 6 << EXPRESSION_SHIFT,
    R_ADSP218X_PM14           = 7 << EXPRESSION_SHIFT,
    R_ADSP218X_DM14           = 8 << EXPRESSION_SHIFT,
    R_ADSP218X_IOADDR         = 9 << EXPRESSION_SHIFT,
    R_ADSP218X_YYCCBO         = 10 << EXPRESSION_SHIFT,
    R_ADSP218X_YYCCBO_BITNO   = 11 << EXPRESSION_SHIFT,
    R_ADSP218X_SHIFT_IMMEDIATE    = 12 << EXPRESSION_SHIFT,
    
    /* ADSP219x relocation types */    
    R_ADSP219X_NONE           = 0 << EXPRESSION_SHIFT,
    R_ADSP219X_IMM12          = 1 << EXPRESSION_SHIFT,
    R_ADSP219X_IMM16          = 2 << EXPRESSION_SHIFT,
    R_ADSP219X_DATADM         = 3 << EXPRESSION_SHIFT,
    R_ADSP219X_DATAPM         = 4 << EXPRESSION_SHIFT,
    R_ADSP219X_DATA24         = 5 << EXPRESSION_SHIFT,
    R_ADSP219X_DMLOAD         = 6 << EXPRESSION_SHIFT,
    R_ADSP219X_PMLOAD         = 7 << EXPRESSION_SHIFT,
    R_ADSP219X_DO             = 8 << EXPRESSION_SHIFT,
    R_ADSP219X_REL            = 9 << EXPRESSION_SHIFT,
    R_ADSP219X_LONG           = 10 << EXPRESSION_SHIFT,
    R_ADSP219X_DM16           = 11 << EXPRESSION_SHIFT,
    R_ADSP219X_IOADDR         = 12 << EXPRESSION_SHIFT,
    R_ADSP219X_YYCCBO         = 13 << EXPRESSION_SHIFT,
    R_ADSP219X_YYCCBO_BITNO   = 14 << EXPRESSION_SHIFT,
                                
    R_ADSP219X_SHIFT_IMMEDIATE  = 15 << EXPRESSION_SHIFT,
    R_ADSP219X_MODIFY_IMMEDIATE = 16 << EXPRESSION_SHIFT,
};

#endif

#endif /* _ADIELF_H */
