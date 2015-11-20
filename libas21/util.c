/*
 * util21.c
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
#include "util.h"

extern void yyerror( const char *);

int int_divide( int left, int right )
{
    int result;
    
    if ( right == 0 )
    {
        if ( left < 0 )
        {
            result = INT_MIN;
        }
        else if ( left == 0 )
        {
            result = 0;
        }
        else
        {
            result = INT_MAX;
        }
    }
    else
    {
        result = left / right;
    }
    return result;
}

int int_mod( int left, int right )
{
    int result;
    
    if ( right == 0 )
    {
        result = 0;
    }
    else
    {
        result = left % right;
    }
    return result;
}

unsigned long check_yyccbo( int number )
{
    int bit;
    int mask;
    unsigned long result;

    if ( number == 0 )
    {
        return YOP_ZERO;
    }
    /* restrict to 16 bits */
    if ( number > 0xffff || number < -0x8000 )
    {
        return 0;
    }
    number &= 0xffff;
    if ( (number & (number - 1)) == 0 )
    {
        /* number with single bit set */
        result = BO_PLUS;
    }
    else
    {
        number = ~number & 0xffff;
        if ( (number & (number - 1)) == 0 )
        {
            /* number with single bit clear */
            result = BO_MINUS;
        }
        else
        {
            return 0; /* not a valid constant */
        }
    }
    for ( bit = 0, mask = 1 ; mask != number ; ++bit, mask <<= 1 )
    {
    }
    result |= (unsigned long)(BITNO_TO_YYCC(bit));
    return result;
}

