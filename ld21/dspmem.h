/*
 * dspmem.h 
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
#ifndef _DSPMEM_H
#define _DSPMEM_H

/* for convenience this is defined the same as memory_space_t in outfile.h */
typedef enum { NON_MEMORY, PROGRAM_MEMORY, DATA_MEMORY } MEMORY_SPACE;
typedef enum { PORT_LOCUS, RAM_LOCUS, ROM_LOCUS } MEMORY_LOCUS;

typedef struct MEMORY_BLOCK
{
    struct MEMORY_BLOCK *next;
    MEMORY_SPACE space;
    MEMORY_LOCUS locus;
    unsigned long start_used, start, end;
    unsigned long width;
    char name[1];
} MEMORY_BLOCK;

typedef MEMORY_BLOCK *MEMORY_LIST;

extern void memory_list_init( MEMORY_LIST *header );

extern void memory_list_destroy( MEMORY_LIST *header );

extern void add_memory_block( MEMORY_LIST *header,
                              const char *name,
                              MEMORY_SPACE space,
                              MEMORY_LOCUS locus,
                              int start,
                              int end,
                              int width);

extern MEMORY_BLOCK *find_memory_block( MEMORY_LIST header,
                                        const char *name );

extern void memory_list_print( const MEMORY_BLOCK *block, int only_one );

#endif

