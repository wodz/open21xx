/*
 * symbol.c 
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
#include <ctype.h>
#include "defs.h"
#include "symbol.h"
#include "outfile.h"
#include "bbtree.h"
#include "listing.h"
#include "keyword.h"

static bbtree_t tree;

enum
{
    SYMBOL_DEFINED    = SYMBOL_LAST_SCOPE << 1,
    SYMBOL_REFERENCED = SYMBOL_LAST_SCOPE << 2,
    SYMBOL_MACRO      = SYMBOL_LAST_SCOPE << 3
};

#define SYMBOL_COMMON   \
    bbtree_node_t node; \
    const char *name;   \
    int flags           \

typedef struct symbol_t
{
    SYMBOL_COMMON;
    Elf32_Sym *elf_symbol;
    int elf_index;
    memory_space_t space;
} symbol_t;

typedef struct macro_t
{
    SYMBOL_COMMON;
    macro_definition_t definition;
} macro_t;

static int comparefn( const void *key, const bbtree_node_t *element )
{ 
    return strcmp((char *)key, ((symbol_t *)element)->name);
}

static void print_node( bbtree_t *tree, bbtree_node_t *node, void *user )
{
    symbol_t *symbol = (symbol_t *)node;
    char space;
    int value, size;

    if ((symbol->flags & SYMBOL_MACRO) == 0)
    {
        switch (symbol->space)
        {
            case SECTION_PROGRAM:
                space = 'P';
                break;
            case SECTION_DATA:
                space = 'D';
                break;
            default:
                space = 'U';
                break;
        }
        if (symbol->elf_symbol)
        {
            value = symbol->elf_symbol->st_value;
            size = symbol->elf_symbol->st_size;
        }
        else
        {
            value = size = 0;
        }

        printf( "Symbol: %-32s %08X %c %d\n", symbol->name,
                value, space,
                size );
    }
    else
    {
        macro_t *macro = (macro_t *)node;
        int end;
        int i;

        end = tree->height;
        for ( i = 0 ; i < end ; ++i )
            printf( " " );
        printf( "Macro: %s params=%d  ", macro->name,
                macro->definition.offset_count );
        end = macro->definition.offset_count;
        for( i = 0 ; i < end ; ++i )
        {
            printf( "%d:%d ", macro->definition.offsets[i].offset,
                    macro->definition.offsets[i].type );
        }
        end = macro->definition.offsets
            [macro->definition.offset_count - 1].offset;
        for ( i = 0 ; i < end ; ++i )
        {
            putchar( macro->definition.value[i] );
        }
        putchar( '\n' );
    }
}

static void check_symbol( bbtree_t *tree, bbtree_node_t *node, void *user )
{
    symbol_t *symbol = (symbol_t *)node;

    if ((symbol->flags & SYMBOL_MACRO) == 0)
    {
        if ((symbol->flags & (SYMBOL_EXTERN | SYMBOL_DEFINED)) == 0)
        {
            yyerror( "symbol \"%s\" is undefined",
                     symbol->name );
        }
        else if ((symbol->flags & (SYMBOL_EXTERN | SYMBOL_DEFINED)) ==
                 (SYMBOL_EXTERN | SYMBOL_DEFINED))
        {
            if ( (symbol->flags & SYMBOL_GLOBAL) == 0 )
            {
                yyerror( "external symbol \"%s\" is local",
                         symbol->name );
            }
        }
    }
}


void init_symtab()
{
    bbtree( &tree, comparefn, 0 );
}

void symbol_deletefn( bbtree_node_t *node )
{
    macro_t *macro = (macro_t *)node;

    if ( macro->flags & SYMBOL_MACRO )
    {
        free( (void *)macro->name );
        free( (void *)macro->definition.offsets );
    }  
    /* else its just a symbol */
    free( node );
}

void empty_symtab()
{ 
    bbtree_destroy( &tree, symbol_deletefn );
}

void print_symtab(void)
{
    bbtree_leftright_walk( &tree, tree.root, print_node, NULL );
}

void check_symtab()
{ 
    bbtree_leftright_walk( &tree, tree.root, check_symbol, NULL );
}

symbol_hdl symbol_define( const char *name,
                         int size )
{
    bbtree_node_t *parent;
    symbol_t *symbol = NULL;
    int compare;

    parent = bbtree_preinsert( &tree, name, &compare );
    if (!parent || compare != 0)
    {
        symbol = (symbol_t *)malloc(sizeof(*symbol));
        if (symbol)
        {
            symbol->elf_symbol =
                outfile_add_symbol( name, &symbol->name, &symbol->elf_index );
            symbol->space = outfile_memory_space();
            symbol->flags = SYMBOL_DEFINED;
            outfile_define_symbol( symbol->elf_symbol, size );
            bbtree_insert( &tree, parent, &symbol->node,
                           compare );
        }
        else
        {
            yyerror("Can't allocate memory for symbol table entry");
        }
    }
    else if (parent && compare == 0)
    {
        symbol = (symbol_t *)parent;
        if ((symbol->flags & SYMBOL_MACRO) != 0)
        {
            symbol = NULL;
            yyerror("Redefining a macro");
        }
        else if ((symbol->flags & SYMBOL_DEFINED) == 0)
        {
            outfile_define_symbol( symbol->elf_symbol, size );
            symbol->flags |= SYMBOL_DEFINED;
        }
        else
        {
            symbol = NULL;
            yyerror("Symbol multiply defined");
        }
    } 
    return symbol;
}

/*
 * Only code can have a forward reference. In other words, I can jump or call a symbol
 * thats undefined, but I cannot otherwise reference a symbol thats undefined.
 * The Analog Devices documentation doesn't comment on this but its consistent with
 * high level languages and a whole lot easier.
 */
symbol_hdl symbol_reference( const char *name, int required,
                             symbol_scope_t scope )
{
    symbol_t *symbol = NULL;
    int compare;
    bbtree_node_t *parent;

    parent = bbtree_preinsert( &tree, name, &compare );
    if ((!required && !parent) || compare != 0)
    {
        symbol = (symbol_t *)malloc(sizeof(*symbol));
        if (symbol)
        {
            symbol->elf_symbol =
                outfile_add_symbol( name, &symbol->name, &symbol->elf_index );
            if (scope != SYMBOL_LOCAL)
                outfile_globalize_symbol( symbol->elf_symbol );
            symbol->flags = SYMBOL_REFERENCED | scope;
            /* only code symbols are not required to be previously defined */
            symbol->space = SECTION_PROGRAM;
            bbtree_insert( &tree, parent, &symbol->node,
                           compare );
        }
    }
    else if (parent && compare == 0)
    {
        symbol = (symbol_t *)parent;
        if ((symbol->flags & SYMBOL_MACRO) != 0)
        {
            symbol = NULL;
            yyerror("Referencing a macro as a symbol");
        }
        else
        {
            if (scope != SYMBOL_LOCAL)
                outfile_globalize_symbol( symbol->elf_symbol );
            symbol->flags |= SYMBOL_REFERENCED | scope;
            if (required && (symbol->flags & SYMBOL_DEFINED) == 0)
            {
                symbol = NULL;
            }
        }
    }
    return symbol;
}

int symbol_get_size( symbol_hdl symbol )
{
    assert( symbol != NULL );
    if ((symbol->flags & SYMBOL_MACRO) == 0 &&
        symbol->elf_symbol)
    {
        return symbol->elf_symbol->st_size;
    }
    return 0;
}

void symbol_set_size( symbol_hdl symbol, int emitted_size )
{
    Elf32_Sym *elf_symbol;

    assert( symbol != NULL );
    if ((symbol->flags & SYMBOL_MACRO) == 0)
    {
        elf_symbol = symbol->elf_symbol;
        if (elf_symbol != NULL )
        {
            if (elf_symbol->st_size == 0)
            { 
                elf_symbol->st_size = emitted_size;
                if (emitted_size == 0)
                    yywarn("Zero size array emitted");
            }
            else if (emitted_size > elf_symbol->st_size)
                yyerror("Array is longer then specified size");
            else if ( emitted_size < elf_symbol->st_size )
            {
                emit_bss( elf_symbol->st_size - emitted_size );
            }
        }
    }
}

void symbol_add_relocation(
    symbol_hdl symbol,
    int addend,
    int type
)
{
    int symbol_index;

    if (symbol == NULL ||
        (symbol && (symbol->flags & SYMBOL_MACRO) == 0))
    {
        if ( symbol == NULL )
        {
            symbol_index = STN_UNDEF;
        }
        else
        {
            symbol_index = symbol->elf_index;
        }
        outfile_add_relocation( symbol_index, addend, type );
    }
}

memory_space_t symbol_space( symbol_hdl symbol )
{
    if ((symbol->flags & SYMBOL_MACRO) == 0)
    {
        return symbol->space;
    }
    return SECTION_NONE;
}

void dump_symbol( symbol_hdl symbol )
{
    print_node( &tree, (bbtree_node_t *)symbol, NULL );
}

void define_macro( char *name,
                   int parameter_count,
                   macro_offset_t *offsets, int offset_count,
                   char *value, int value_length )
{
    int name_size;
    macro_t *macro = NULL;
    macro_offset_t *macro_offsets;
    int compare;
    char *start_text;
    bbtree_node_t *parent;

    parent = bbtree_preinsert( &tree, name, &compare );
    if (!parent || compare != 0)
    {
        name_size = strlen( name ) + 1;
        macro = (macro_t *)malloc( sizeof(*macro) );
        start_text = (char *)malloc( name_size + value_length );
        macro_offsets = (macro_offset_t *)malloc( offset_count * sizeof(*offsets) );
        if ( macro && start_text && macro_offsets )
        {
            macro->definition.offsets = macro_offsets;
            memmove( macro_offsets, offsets,
                     offset_count * sizeof( *offsets ) );
            strcpy( start_text, name );
            macro->name = start_text;
            macro->definition.parameter_count = parameter_count;
            macro->definition.reference_count = 0;
            start_text += name_size;
            memmove( start_text, value, value_length );
            macro->flags = SYMBOL_MACRO;
            macro->definition.value = start_text;
            macro->definition.offset_count = offset_count;
            bbtree_insert( &tree, parent, &macro->node,
                           compare );
        }
        else
        {
            fprintf( stderr, "Failed to allocate memory for macro %s\n",
                     name );
            abort(); 
        }
    }
    else if (parent && compare == 0)
    {
        macro = (macro_t *)parent;
        if ((macro->flags & SYMBOL_MACRO) == 0)
        {
            yyerror("Referencing a symbol as a macro");
        }
        else
        {
            /* compare new definition with old, error if not equal */
            /* name is obviously equal */
            compare = offset_count == macro->definition.offset_count;
            compare = compare && strcmp( macro->definition.value, 
                                         value) == 0;
            if ( !compare )
            {
                yyerror("Attempt to redefine a macro");
            }
        }
    } 
}

void define_simple_macro( char *name, char *value )
{
    macro_offset_t offset;

    offset.type = MACRO_END;
    offset.offset = strlen( value );
    define_macro( name, 0, &offset, 1, value, offset.offset );
}

const macro_definition_t *find_macro( const char *name )
{
    macro_t *macro = NULL;
    int compare;
    bbtree_node_t *parent;

    parent = bbtree_preinsert( &tree, name, &compare );
    if (parent && compare == 0)
    {
        macro = (macro_t *)parent;
        if ((macro->flags & SYMBOL_MACRO) != 0)
        {
            ++macro->definition.reference_count;
            return &macro->definition;
        }
    }
    return NULL;
}

void undefine_macro( const char *name )
{
    macro_t *macro = NULL;
    int compare;
    bbtree_node_t *parent;
    bbtree_node_t *node;

    parent = bbtree_preinsert( &tree, name, &compare );
    if (parent && compare == 0)
    {
        macro = (macro_t *)parent;
        if ((macro->flags & SYMBOL_MACRO) != 0)
        {
            node = bbtree_remove( &tree, parent );
            assert( node == parent );
            free( node );
        }
    }
}

