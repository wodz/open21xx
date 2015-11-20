/*
 * grammar.c
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
 * grammar.c provides helper functions to the YACC grammars.
 */

#include <stdlib.h>
#include <string.h>
#include "../defs.h"
#include "grammar.h"

extern const int processor_list_size;
extern struct processor_list processor_list[];
extern int processor_flags;

int select_processor( const char *name )
{
    struct processor_list *list;
    int retval = TRUE;
    int i;

    list = processor_list;
    if ( name == NULL )
    {
        processor_flags = list->flags;
    }
    else
    {
        ++list;
        for ( i = 0 ;
              i < processor_list_size - 1 &&
              strcmp( name, list->name ) != 0 ; ++i )
        {
            ++list;
        }
        if ( i < processor_list_size - 1 )
        {
            processor_flags = list->flags;
        }
        else
        {
            retval = FALSE;
        }
    }
    return retval;
}
