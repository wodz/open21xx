/*
 * dspmem.c 
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "ld21-lex.h"
#include "dspmem.h"

void memory_list_init( MEMORY_LIST *header )
{
    *header = NULL;
}

void memory_list_destroy( MEMORY_LIST *header )
{
    MEMORY_BLOCK *block;

    while (*header)
    {
        block = (*header)->next;
        free( *header );
        *header = block;
    }
    memory_list_init( header );
}

void add_memory_block( MEMORY_LIST *header,
                       const char *name,
                       MEMORY_SPACE space,
                       MEMORY_LOCUS locus,
                       int start,
                       int end,
                       int width)
{
    MEMORY_BLOCK **scan, **insert, *block;
    int compare;

    insert = NULL;
    for (scan = header ; *scan ; scan = &(*scan)->next)
    {
        compare = strcasecmp(name, (*scan)->name);
        if (compare == 0)
        {
            yyerror("Duplicate memory block name");
            return;
        }
        if (!insert && compare < 0)
        {
            insert = scan;
        }
        if ((*scan)->space == space &&
            ((start >= (*scan)->start && start <= (*scan)->end) ||
             (end >= (*scan)->start && end <= (*scan)->end)))
        {
            yyerror( "Overlapping memory block");
        }
    }
    if (!insert)
    {
        insert = scan;
    }
    assert(insert != NULL);
    block = (MEMORY_BLOCK *)malloc(sizeof(MEMORY_BLOCK) +
                                   strlen(name));
    assert(block);
    if (block)
    {
        strcpy( block->name, name );
        block->space = space;
        block->locus = locus;
        block->start_used = block->start = start;
        block->end = end;
        block->width = width;
        block->next = *insert;
        *insert = block;
    }
}

MEMORY_BLOCK *find_memory_block( MEMORY_LIST header,
                                 const char *name )
{
    int compare;

    for ( ; header ; header = header->next)
    {
        compare = strcasecmp(name, header->name);
        if (compare == 0)
        {
            return header;
        }
        if (compare < 0)
        {
            break;
        }
    }
    return NULL;
}

/* ------------------------- Debug Memory Functions --------------------- */
void memory_list_print( const MEMORY_BLOCK *block, int only_one )
{
    static const char *space_names[] = 
    {
        "PM",
        "DM"
     };
    static const char *locus_names[] =
    {
        "PORT",
        "RAM",
        "ROM"
    };

    for ( ; block ; block = only_one ? NULL :  block->next )
    {
        printf("%s: %s, %s, %lx(%lx)-%lx:%ld\n",
               block->name, space_names[block->space],
               locus_names[block->locus], block->start,
               block->start_used, block->end,
               block->width );
    }
}

