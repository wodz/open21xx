/*
 * outfile.h
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
#ifndef _OUTFILE_H
#define _OUTFILE_H
#include <stdio.h>
#include <elf.h>
#include <libelf.h>

/* only use this macro when the should never occur and you don't know how to
 * handle it if it does */
#define elfcheck(x)                                     \
    if (!(x))                                           \
        fprintf( stderr, "elfcheck in %s@%d - %s\n",    \
                 __FILE__, __LINE__, elf_errmsg(-1) ),  \
        exit(1)

typedef enum
{
    SECTION_NONE,
    SECTION_PROGRAM,
    SECTION_DATA
} memory_space_t;

typedef struct align_block_t *alignment_t;

int outfile_init( const char *outfile_name,
                  Elf32_Half machine,
                  int executable,
                  int code_size,
                  int data_size );

int outfile_term( int elf_flags );

void outfile_emit( unsigned long code );

unsigned long outfile_emit_bss( unsigned long size );

int outfile_select_section( const char *name,
                            Elf32_Word section_type,
                            memory_space_t memory_space );

int outfile_previous_section( void );

Elf32_Sym *outfile_add_symbol( const char *name, const char **where,
                               int *elf_index );

void outfile_globalize_symbol( Elf32_Sym *symbol );

void outfile_define_symbol( Elf32_Sym *elf_symbol, int size );

void outfile_add_relocation( int symbol_index, int addend, int type );

memory_space_t outfile_memory_space( void );

void outfile_memorize_section( Elf_Scn *section,
                               unsigned long *start_used,
                               unsigned long end,
                               unsigned long width ); 

int outfile_align( alignment_t *alignment, int by );

unsigned long outfile_offset( void );

unsigned long outfile_section_index( void );

memory_space_t outfile_walk( unsigned long section_index,
                             unsigned long *offset,
                             unsigned long *code );

int outfile_next_section( unsigned long *start,
                          unsigned long *length,
                          const char **name,
                          int program );

#endif /* _OUTFILE_H */
