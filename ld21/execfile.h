/*
 * execfile.h 
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

#ifndef _EXECFILE_H
#include <elf.h>
#include "namelist.h"
#include "dspmem.h"

enum
{
    MAP_GEN_XREF = 1,
    MAP_INCLUDE_LOCALS = 2
};
void map_file( const char *name, int flags );

void objects_init(void);

void objects_destroy(void);

int exec_open(NAME_LIST *file, Elf32_Half machine,
              int code_size, int data_size);

int exec_close(void);

int select_exec_section( const char *name );

int add_object_sections(NAME_LIST *sections);

void memorize( const char *to_section,
               Elf32_Word section_type,
               MEMORY_BLOCK *block);

void new_input_sections( void );

void new_file_list( void );

void add_one_object( const char *name );

void add_objects( const NAME_LIST *list );

void objects_link( void );    // the final link

void objects_print( void );

void links_print( void );

#endif
