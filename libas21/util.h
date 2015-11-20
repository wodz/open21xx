/*
 * util.h
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

#ifndef UTIL_H
#define UTIL_H

#define BITNO_TO_YYCC(bitno)  (((bitno & 0xc) << 9) | ((bitno & 0x3) << 6))
#define CCBO_MASK             0x0000f0
#define YYCCBO_MASK           (CCBO_MASK | 0x001800)

enum
{
    YOP_OFFSET = 11,
    YOP_ZERO = 0x3 << YOP_OFFSET,
    BO_BIT = 0x10,	    /* BO for "bit n" */
    BO_NOT_BIT = 0x30,  /* BO for "!bit n" */
    BO_PLUS = 0x10,     /* BO for a positive constant */
    BO_MINUS = 0x30,    /* BO for a negative constant */
    DEFAULT_YYCCBO =BO_PLUS,
    BO_MASK = 0x30,
    AMF_OFFSET = 13,
    AMF_MASK = 0x1f << AMF_OFFSET,
};

int int_divide( int left, int right );

int int_mod( int left, int right );

unsigned long check_yyccbo( int number );

#endif
