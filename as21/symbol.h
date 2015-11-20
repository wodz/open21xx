/*
 * symbol.h 
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
#if !defined(_SYMBOL_H)
#define _SYMBOL_H

#include <stddef.h>
#include <elf.h>
#include "outfile.h"
#include "bbtree.h"

typedef enum
{
    SYMBOL_LOCAL      = 0x00,
    SYMBOL_UNKNOWN    = SYMBOL_LOCAL,
    SYMBOL_GLOBAL     = 0x01,
    SYMBOL_EXTERN     = 0x02,
    SYMBOL_LAST_SCOPE = SYMBOL_EXTERN   /* must be last */
} symbol_scope_t;

typedef struct symbol_t *symbol_hdl;

typedef enum
{
    /* >= 0 indicate the occurence of that parameter number */
    MACRO_STRINGIZE = -1,
    MACRO_LABEL = -2,
    MACRO_EXPANSION = -3,
    MACRO_END = -4
} macro_offset_type_t;

/*
 * macro_offset_t holds the offset into macro text where something
 * special happens: an argument is inserted, a concatenation
 * operator is located etc.
 */
typedef struct macro_offset_t
{
    int type;
    int offset;
} macro_offset_t;

typedef struct macro_definition_t
{
    const char *value;
    int parameter_count;
    int reference_count;
    int offset_count;
    macro_offset_t *offsets;
} macro_definition_t;

void init_symtab();

void empty_symtab();

void define_macro( char *name,
                   int parameter_count,
                   macro_offset_t *offsets, int offset_count,
                   char *value, int value_length );

void define_simple_macro( char *name, char *value );

void undefine_macro( const char *name );

const macro_definition_t *find_macro( const char *name );

int find_keyword( const char *name );

symbol_hdl symbol_define( const char *name,
                          int length );

/*
 * If the symbool must already be defined, required is TRUE.
 * Otherwise its FALSE.
 */
symbol_hdl symbol_reference( const char *name,
                             int required, 
                             symbol_scope_t scope );

int symbol_get_size( symbol_hdl symbol );

void symbol_set_size( symbol_hdl symbol, int emitted_size );

void symbol_add_relocation( symbol_hdl symbol, int addend, int type );

memory_space_t symbol_space( symbol_hdl symbol );

void print_symtab(void);

void dump_symbol( symbol_hdl symbol );

void check_symtab(void);

#endif /* !defined(_SYMBOL_H) */




