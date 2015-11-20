/*
 * expression.h
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

#ifndef EXPRESSION_H
#define EXPRESSION_H

#include "../adielf.h"
#include "symbol.h"

/* to access the parts of the register group value */
#define REGISTER_GROUP(x)     (((x) & 0x30) >> 4)
#define REGISTER(x)           ((x) & 0xf)
#define REG_MOVE_GROUPS(x)    ((x) & 0xf00)
#define I_REGISTER(x)         ((x) & 0x3)
#define I_DAG(x)              ((x) >> 2)
#define M_REGISTER(x)         I_REGISTER(x)
#define M_DAG(x)              I_DAG(x)

#define SHIFT_FUNCTION(x)     (((x) >> SF_OFFSET) & 0xf)

#define IS_CONSTANT(x)        ((x).symbol == NULL && (x).type == EXPRESSION_PUSH)


enum
{
    COND_OFFSET = 0,
    TERM_OFFSET = 0,
    ADDRESS_OFFSET = 4,
    XOP_OFFSET = 8,
    Z_OFFSET = 18,
};

typedef struct expression_t
{
    int type;
    symbol_hdl symbol;
    int addend;
} expression_t;

expression_t unary_op( expression_t *, int computed, enum REL_TYPE );

expression_t binary_op( expression_t *, expression_t *,
                             int computed, enum REL_TYPE );
#endif
