/*
 * expression.c
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

#include <stdlib.h> 
#include <limits.h>
#include <ctype.h>


#include "../defs.h"
#include "symbol.h"
#include "listing.h"
#include "expression.h"

expression_t unary_op( expression_t *input, int addend,
                            enum REL_TYPE reltype )
{
    expression_t result;
    int input_type;
    
    result = *input;
    input_type = input->type & EXPRESSION_MASK;
    if ( input_type == EXPRESSION_PUSH && input->symbol == STN_UNDEF )
    {
        result.addend = addend;
    }
    else
    {
        if ( input_type == EXPRESSION_PUSH )
        {
            symbol_add_relocation( input->symbol, input->addend,
                                   (input->type & SYMBOL_MASK) | EXPRESSION_PUSH );
        }
        symbol_add_relocation( NULL, 0, SYMBOL_SYMBOL | reltype );
        result.addend = 0;
        result.type = EXPRESSION_SYMBOLIC;
        result.symbol = STN_UNDEF;
    }

    return result;
}

expression_t binary_op( expression_t *left, expression_t *right,
                             int addend, enum REL_TYPE reltype )
{
    expression_t result;
    int left_type, right_type;
    
    result = *left;
    if ( (left->type & EXPRESSION_MASK) == EXPRESSION_PUSH &&
         (right->type & EXPRESSION_MASK) == EXPRESSION_PUSH &&
         left->symbol == STN_UNDEF && right->symbol == STN_UNDEF )
    {
        result.addend = addend;
    }
    else
    {
        /* add relocation for inputs and result takes on reltype */
        left_type = left->type & EXPRESSION_MASK;
        right_type = right->type & EXPRESSION_MASK;
        if ( left_type == EXPRESSION_PUSH )
        {
            symbol_add_relocation( left->symbol, left->addend, 
                                   (left->type & SYMBOL_MASK) | EXPRESSION_PUSH );
        }
        if ( right_type == EXPRESSION_PUSH )
        {
            symbol_add_relocation( right->symbol, right->addend,
                                   (right->type & SYMBOL_MASK) | EXPRESSION_PUSH );
        }
        if ( left_type == EXPRESSION_PUSH &&
             right_type == EXPRESSION_SYMBOLIC )
        {
            /* reverse the operator */
            switch( reltype )
            {
                case EXPRESSION_DIVIDE:
                    reltype = EXPRESSION_RDIVIDE;
                    break;
                case EXPRESSION_MOD:
                    reltype = EXPRESSION_RMOD;
                    break;
                case EXPRESSION_SUBTRACT:
                    reltype = EXPRESSION_RSUBTRACT;
                    break;
                case EXPRESSION_SHIFT_UP:
                    reltype = EXPRESSION_RSHIFT_UP;
                    break;
                case EXPRESSION_SHIFT_DOWN:
                    reltype = EXPRESSION_RSHIFT_DOWN;
                    break;
                case EXPRESSION_LESS:
                    reltype = EXPRESSION_GREATER;
                    break;
                case EXPRESSION_LESS_EQUAL:
                    reltype = EXPRESSION_GREATER_EQUAL;
                    break;
                case EXPRESSION_GREATER:
                    reltype = EXPRESSION_LESS;
                    break;
                case EXPRESSION_GREATER_EQUAL:
                    reltype = EXPRESSION_LESS_EQUAL;
                    break;
                default:
                    break;
            }
        }
        symbol_add_relocation( NULL, 0, SYMBOL_SYMBOL | reltype );
        result.addend = 0;
        result.type = EXPRESSION_SYMBOLIC;
        result.symbol = STN_UNDEF;
    }

    return result;
}
