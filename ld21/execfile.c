/*
 * execfile.c 
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
#include <unistd.h>
#include <assert.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <time.h>
#include <elf.h>
#include <libelf.h>
#include <limits.h>
#include "outfile.h"
#include "bbtree.h"
#include "array.h"
#include "util.h"
#include "../defs.h"
#include "../adielf.h"
#include "ld21-lex.h"
#include "fixup.h"
#include "execfile.h"

extern char version[];

#define SHF_REFERENCED    (0x10000000)

/*
 * Every once in a while test these with very small value
 */
#define SCNS_PER_PAGE     128
#define OBJECTS_PER_PAGE  32

static char *map_file_name;
static int map_flags;
static char *out_file_name;
static Elf32_Half out_file_machine;
static int max_symbols;
static fixup_code_fn fixup_code;

typedef struct OBJECT_FILE
{
    struct OBJECT_FILE *next_object;      // for the list of open object files
    const char *name;
    int fd;
    Elf *elf;
    Elf32_Ehdr *ehdr;
    const char *strings;
    Elf32_Sym *symbols;
    int symbol_count;
    int first_global;
    Elf32_Word string_index;
} OBJECT_FILE;

static OBJECT_FILE *objects = NULL;        // all open object files
static bbtree_t globals;
static array_t scn_array;
static array_t link_array;

/* if this function encounters an error it never returns */
static void exec_getsection(
    Elf *elf, size_t index,
    Elf32_Shdr **shdr,
    Elf_Data **data,
    int line
)
#define exec_getsection(a,b,c,d) \
    exec_getsection(a,b,c,d,__LINE__)
{
    Elf_Scn *section;
    char *location;

    location = NULL;
    section = elf_getscn( elf, index );
    if ( section )
    {
        if ( shdr )
        {
            *shdr = elf32_getshdr(section);
            if ( *shdr == NULL )
            {
                location = "elf32_getshdr";
            }
        }
        if ( location == NULL && data )
        {
            *data = elf_getdata(section, NULL);
            if ( *data == NULL )
            {
                location = "elf_getdata";
            }
            else if ( (*data)->d_buf == NULL )
            {
                location = "d_buf";
            }
        }
        if ( location == NULL )
        {
            return;
        }
    }
    else
    {
        location = "elf_getscn";
    }
    fprintf( stderr, "exec_getsection: %s@%d - %s\n", location, line,
             elf_errmsg( -1 ) );
    exit( 1 );
}

/* if this function encounters an error it never returns */
static Elf_Data *exec_getdata( Elf_Scn *scn, int line )
#define exec_getdata(a) \
    exec_getdata(a,__LINE__)
{
    Elf_Data *data;
    char *location;

    location = NULL;
    data = elf_getdata(scn, NULL);
    if ( data != NULL )
    {
        if ( data->d_buf != NULL )
        {
            return data;
        }
        else
        {
            location = "d_buf";
        }
    }
    else
    {
        location = "elf_data";
    }
    fprintf( stderr, "exec_getdata: %s@%d - %s\n", location, line,
             elf_errmsg( -1 ) );
    exit( 1 );
}

static OBJECT_FILE *object_open( const char *file_name )
{
    OBJECT_FILE *file;
    Elf_Scn *section;
    Elf_Data *symtab;
    Elf32_Shdr *shdr;
    int compare;

    // search for the file in the list of already open objects
    for (file = objects ; file ; file = file->next_object)
    {
        compare = strcmp( file_name, file->name );
        if ( compare == 0 ) // if we found it
        {
            return file;
        }
        else if ( compare < 0 )  // if we didn't find it
        {
            break;
        }
    }

    // try to add a new file to the list of open objects
    file = (OBJECT_FILE *)malloc( sizeof(OBJECT_FILE) );
    assert(file);
    if ( file )
    {
        memset( file, 0, sizeof(*file) );
        if ((file->fd = open(file_name, O_RDONLY | O_BINARY)) != -1)
        {
            file->elf = elf_begin(file->fd, ELF_C_READ, NULL);
            if (file->elf)
            {
                file->ehdr = elf32_getehdr(file->elf);
                if (file->ehdr)
                {
                    if ( file->ehdr->e_machine == out_file_machine )
                    {
                        Elf_Data *string_data;
                        OBJECT_FILE **scan;
                        int compare;

                        exec_getsection( file->elf, file->ehdr->e_shstrndx,
                                         NULL, &string_data );
                        file->strings = (char *)string_data->d_buf;
                        file->name = strdup( file_name );

                        section = NULL;
                        while ((section =
                                elf_nextscn(file->elf, section)) != 0)
                        {
                            shdr = elf32_getshdr(section);
                            elfcheck( shdr != NULL );
                            if (shdr->sh_type == SHT_SYMTAB)
                            {
                                symtab = exec_getdata(section);
                                file->symbols = symtab->d_buf;
                                file->symbol_count = symtab->d_size /
                                    sizeof(Elf32_Sym);
                                file->first_global = shdr->sh_info;
                                file->string_index = shdr->sh_link;
                                if ( file->symbol_count > max_symbols )
                                {
                                    max_symbols = file->symbol_count;
                                }
                                break;
                            }
                        }

                        // ordered insert into the file list
                        assert( file->name );
                        for ( scan = &objects ; *scan ;
                              scan = &(*scan)->next_object )
                        {
                            compare = strcmp(file_name, (*scan)->name );
                            // if this file already exists we should have found
                            // it instead of creating it
                            assert( compare != 0 );
                            if (compare < 0)
                            {
                                break;
                            }
                        }
                        file->next_object = *scan;
                        *scan = file;
                        return file;
                    }
                    else
                    {
                        yyerror(
                            "Input file machine type doesn't match architecture" );
                    }
                }
                else
                {
                    yyerror( "File %s is not a valid ELF file: %s",
                             file_name, elf_errmsg(-1) );
                }
                elf_end(file->elf);
            }
            else
            {
                yyerror( "Elf_begin on %s failed: %s",
                         file_name, elf_errmsg(-1) );
            }
            close( file->fd );
        }
        else
        {
            yyerror( "File %s not found", file_name );
        }
        free( file );
        file = NULL;
    }
    return file;
}

static void object_close( OBJECT_FILE *file )
{
    elf_end( file->elf );
    close( file->fd );
    free( (char *)file->name );
    free( file );
}

void map_file( const char *name, int flags )
{
    if ( map_file_name == NULL )
    {
        map_file_name = strdup(name);
        map_flags = flags;
    }
}

void objects_init(void)
{
    map_file_name = NULL;
    objects = NULL;
    max_symbols = 0;
    array_init( &scn_array, sizeof( Elf_Scn * ), SCNS_PER_PAGE );
    array_init( &link_array, sizeof( OBJECT_FILE * ), OBJECTS_PER_PAGE );
}

void objects_destroy(void)
{
    OBJECT_FILE *file;

    for ( file = objects ; file ; )
    {
        file = objects->next_object;
        object_close( objects );
        objects = file;
    }

    array_destroy( &scn_array );
    array_destroy( &link_array );
    if ( map_file_name )
    {
        free( map_file_name );
    }
}

int exec_open( NAME_LIST *fnames, Elf32_Half machine,
               int code_size, int data_size )
{
    if (!fnames)
    {
        yyerror("No output file specified");
    }
    else if (fnames->next)
    {
        yyerror("Multiple output files specified");
    }
    else if (elf_version(EV_CURRENT) == EV_NONE)
    {
        yyerror( "Elf library is out of date" );
    }
    else
    {
        outfile_init( fnames->name, machine, TRUE,
                      code_size, data_size );
        out_file_machine = machine;
        out_file_name = strdup( fnames->name );
        if ( !fixup_code_map( machine, &fixup_code ) )
        {
            yyerror( "Relocations for this machine type are not supported" );
            return FALSE;
        }
        return TRUE;
    }
    return FALSE;
}

int exec_close( void )
{
    OBJECT_FILE *file;
    Elf32_Word flags;

    flags = 0;
    file = objects;
    while ( file )
    {
        flags |= file->ehdr->e_flags;
        file = file->next_object;
    }
    outfile_term( flags );
    if ( error_count > 0 )
    {
        remove( out_file_name );
    }
    free( out_file_name );
    return 0;
}

int add_object_sections(NAME_LIST *section_name_list)
{
    OBJECT_FILE **current;
    Elf_Scn *elf_section;
    Elf32_Shdr *shdr;
    NAME_LIST *section_name;
    Elf_Scn **array;
    int scns_available;
    int scns_added;
    array_index_t link_index;
    int page_links;
    const char *input_name;

    scns_added = scns_available = 0;
    array = NULL;
    array_index_init( &link_index, &link_array );
    current = (OBJECT_FILE **)array_index_next_page(
        &link_index, &page_links );
    while (current)
    {
        elf_section = NULL;
        while ((elf_section = elf_nextscn((*current)->elf, elf_section)) != 0)
        {
            shdr = elf32_getshdr(elf_section);
            elfcheck( shdr != NULL );
            if ( shdr->sh_type == SHT_PROGBITS ||
                 shdr->sh_type == SHT_NOBITS )
            {
                input_name = (*current)->strings+shdr->sh_name;
                for ( section_name = section_name_list ; section_name ;
                      section_name = section_name->next )
                {
                    if (strcmp( input_name, section_name->name) == 0)
                    {
                        if ((shdr->sh_flags & SHF_REFERENCED) == 0)
                        {
                            if ( scns_added >= scns_available )
                            {
                                array_update( &scn_array, scns_added );
                                scns_added = 0;
                                array = array_alloc( &scn_array,
                                                     &scns_available );
                            }
                            *array++ = elf_section;
                            ++scns_added;
//                            elf_flagshdr( elf_section, ELF_C_SET, SHF_REFERENCED );
                            shdr->sh_flags |= SHF_REFERENCED;
                        }
                        else
                        {
                            yyerror( "Input section is referenced twice" );
                        }
                        break;
                    }
                }
            }
        }
        ++current;
        if ( --page_links == 0 )
        {
            current = (OBJECT_FILE **)array_index_next_page(
                &link_index, &page_links );
        }
    }
    array_update( &scn_array, scns_added );
    return 1;
}

#if 0

static void update_shdrs( unsigned long offset )
{
    int i;
    SHDR_PAGE *page;

    page = shdr_page_list;
    for ( i = 0 ; page && i < shdr_page_index ; ++i )
    {
        if ((i & SHDR_PAGE_MASK) == 0 && i > 0)
        { 
            page = page->next;
        }
        page->shdrs[i & SHDR_PAGE_MASK]->sh_addr += offset;
    }
}
#endif

void memorize( const char *to_name,
               Elf32_Word section_type,
               MEMORY_BLOCK *memory)
{
    array_index_t index;
    Elf_Scn **scn_page;
    int i;
    int elements;
    int made_section;

    if (memory)
    {
        made_section = FALSE;
        array_index_init( &index, &scn_array );
        while ( (scn_page = array_index_next_page( &index,
                                                   &elements )) != NULL )
        {
            if ( !made_section && elements > 0 )
            {
                made_section = TRUE;
                outfile_select_section(
                    to_name,
                    section_type,
                    SECTION_NONE );
            }
            for( i = 0 ; i < elements ; ++i )
            {
                outfile_memorize_section(
                    scn_page[i],
                    &memory->start_used,
                    memory->end,
                    memory->width );
            }
        }
    }
}

void new_input_sections( void )
{
    array_clear( &scn_array );
}

void new_file_list( void )
{
    array_clear( &link_array );
}

void add_one_object( const char *name )
{
    OBJECT_FILE *file;
    OBJECT_FILE **save;
    int available;

    file = object_open( name );
    if (file)
    {
        save = array_alloc( &link_array, &available );
        *save = file;
        array_update( &link_array, 1 );
    }
}

void add_objects( const NAME_LIST *list )
{
    while (list)
    {
        add_one_object( list->name );
        list = list->next;
    }
}

void objects_print( void )
{
    OBJECT_FILE *file;

    for ( file = objects ; file ; file = file->next_object )
    {
        printf( "ELF file %s\n", file->name );
    }
}

void links_print( void )
{
    array_index_t index;
    OBJECT_FILE **current;
    int page_links;

    array_index_init( &index, &link_array );
    current = (OBJECT_FILE **)array_index_next_page(
        &index, &page_links );
    while ( current )
    {
        printf("Link file %s\n", (*current)->name );
        ++current;
        if ( --page_links == 0 )
        {
            current = (OBJECT_FILE **)array_index_next_page(
                &index, &page_links );
        }
    }
}

/* --------- Final Linking of the Elf Object files ---------- */

typedef struct
{
    bbtree_node_t node;
    char *name;
    OBJECT_FILE *file;
    Elf32_Sym *symbol;
} global_t;

static int comparefn( const void *key, const bbtree_node_t *element )
{
    global_t *global = (global_t *)element;

    return strcasecmp( (char *)key, global->name );
}


static void fixup_symbols( void )
{
    bbtree_node_t *parent;
    OBJECT_FILE *file;
    Elf_Scn *section;
    Elf32_Shdr *shdr;
    Elf32_Sym *symbol;
    global_t *global_sym;
    int i;
    int compare;
    char *sym_name;

    file = objects;
    while (file)
    {
        section = NULL;
        while ((section = elf_nextscn(file->elf, section)) != 0)
        {
            shdr = elf32_getshdr(section);
            elfcheck( shdr != NULL );
            if ( (shdr->sh_type == SHT_PROGBITS ||
                  shdr->sh_type == SHT_NOBITS) &&
                 (shdr->sh_flags & SHF_REFERENCED) == 0)
            {
                yyerror( "Section %s in file %s is not referenced\n",
                         file->strings + shdr->sh_name, file->name );
            }
        }
        symbol = file->symbols + 1;
        for ( i = 1 ; i < file->symbol_count ; ++i )
        {
            sym_name = elf_strptr( file->elf, file->string_index,
                                   symbol->st_name);
            if (symbol->st_shndx != SHN_UNDEF)
            {
                exec_getsection( file->elf, symbol->st_shndx,
                                 &shdr, NULL );
                symbol->st_value += shdr->sh_addr;
                if (i >= file->first_global)
                {
                    parent = bbtree_preinsert( &globals, sym_name,
                                               &compare );
                    if (!parent || compare != 0)
                    {
                        global_sym = (global_t *)malloc(sizeof(*global_sym));
                        if (global_sym)
                        {
                            global_sym->file = file;
                            global_sym->name = sym_name;
                            global_sym->symbol = symbol;
                            bbtree_insert( &globals, parent, &global_sym->node,
                                           compare );
                        }
                        else
                        {
                            yyerror( "Failed to allocate memory\n" );
                        }

                    }
                    else
                    {
                        yyerror( "Global symbol \"%s\" multiply defined\n",
                                 sym_name );
                    }
                }
            }
            else if (i < file->first_global)
            {
                yyerror( "Symbol \"%s\" is undefined but local\n",
                         sym_name );
            }
            ++symbol;
        }
        file = file->next_object;
    }
}

#if 0
static void resolve_globals( void )
{
    OBJECT_FILE *file;
    global_t *global_sym;
    Elf32_Sym *symbol;
    int i;
    int compare;
    char *sym_name;

    file = objects;
    while (file)
    {
        symbol = file->symbols + file->first_global;
        for ( i = file->first_global ; i < file->symbol_count ; ++i )
        {
            sym_name = elf_strptr( file->elf, file->string_index,
                                   symbol->st_name);
            if (symbol->st_shndx == SHN_UNDEF)
            {
                global_sym = (global_t *)bbtree_preinsert( &globals, sym_name,
                                                           &compare );
                if (compare == 0)
                {
                    symbol->st_value = global_sym->symbol->st_value;
                    /* set to any section other than SHN_UNDEF */
                    symbol->st_shndx = 1;
                }
                /* not an error until a symbol is referenced */
            }
            ++symbol;
        }
        file = file->next_object;
    }
}
#endif

struct expression_stack
{
    int *stackp;
    int stack[32];
};

#define DEBUG_EXPRESSION 0

void relocation_push( 
    struct expression_stack *stack,
    Elf32_Rela *rel,
    OBJECT_FILE *file
)
{
    global_t *global_sym;
    Elf32_Sym *symbol;
    char *sym_name;
    int compare;
    int sym_index;
    
    symbol = NULL;
    sym_index = ELF32_R_SYM( rel->r_info );
    if ( sym_index )
    {
        symbol = file->symbols + sym_index;
        if ( symbol->st_shndx == SHN_UNDEF )
        {
            /* symbol must be global so find it */
            sym_name = elf_strptr( file->elf, file->string_index,
                                symbol->st_name );
            global_sym = (global_t *)bbtree_preinsert( &globals, sym_name,
                                                        &compare );
            if (compare == 0)
            {
                symbol = global_sym->symbol;
            }
            else
            {
                yyerror( "Unresolved external: \"%s\" (%s)\n",
                        sym_name, file->name );
            }
        }
        /* else symbol is local and we already have it */
    }
    /* else push r_addend as a constant */
    if ( symbol )
    {
        switch( ELF32_R_TYPE(rel->r_info) & SYMBOL_MASK )
        {
            case SYMBOL_SYMBOL:
                *stack->stackp = symbol->st_value + rel->r_addend;
                break;
            case SYMBOL_LENGTH_OF:
                *stack->stackp = symbol->st_size + rel->r_addend;
                break;
            case SYMBOL_PAGE_OF:
                *stack->stackp = (symbol->st_value >> 16) + rel->r_addend;
                break;
            case SYMBOL_ADDRESS_OF:
                *stack->stackp = (symbol->st_value & 0xffff) + rel->r_addend;
                break;
        }
    }
    else
    {
        /* pust a constant or symbol not found */
        *stack->stackp = rel->r_addend;
    }
#if DEBUG_EXPRESSION
    printf( "push = %d\n", *stack->stackp );
#endif
    ++stack->stackp;
}

int relocation_expression(
    Elf32_Rela *rel,
    Elf32_Rela *relend,
    OBJECT_FILE *file
)
{
    struct expression_stack stack;
    int reltype;
    
    stack.stackp = stack.stack;
    if ( rel == relend )
    {
        relocation_push( &stack, rel, file );
    }
    else
    {
        while ( rel < relend )
        {
            reltype = ELF32_R_TYPE(rel->r_info) & EXPRESSION_MASK;
            if ( reltype == EXPRESSION_PUSH )
            {
                relocation_push( &stack, rel, file );
            }
            else
            {
                if ( reltype <= EXPRESSION_LAST_UNARY )
                {
                    switch( reltype )
                    {
                        case EXPRESSION_NEGATE:
                            *(stack.stackp - 1) = -*(stack.stackp - 1);
                            break;
                        case EXPRESSION_LOGICAL_NOT:
                            *(stack.stackp - 1) = !*(stack.stackp - 1);
                            break;
                        case EXPRESSION_BITWISE_NOT:
                            *(stack.stackp - 1) = ~*(stack.stackp - 1);
                            break;
                    }
#if DEBUG_EXPRESSION
                    printf( "unop = %d\n", *(stack.stackp - 1) );
#endif
                }
                else
                {
                    --stack.stackp;
                    switch( reltype )
                    {
                        case EXPRESSION_MULTIPLY:
                            *(stack.stackp - 1) *= *stack.stackp;
                            break;
                        case EXPRESSION_DIVIDE:
                            *(stack.stackp - 1) =
                                int_divide( *(stack.stackp - 1), *stack.stackp );
                            break;
                        case EXPRESSION_RDIVIDE:
                            *(stack.stackp - 1) =
                                int_divide( *stack.stackp, *(stack.stackp - 1) );
                            break;
                        case EXPRESSION_MOD:
                            *(stack.stackp - 1) =
                                int_mod( *(stack.stackp - 1), *stack.stackp );
                            break;
                        case EXPRESSION_RMOD:
                            *(stack.stackp - 1) =
                                int_mod( *stack.stackp, *(stack.stackp - 1) );
                            break;
                        case EXPRESSION_ADD:
                            *(stack.stackp - 1) += *stack.stackp;
                            break;
                        case EXPRESSION_SUBTRACT:
                            *(stack.stackp - 1) -= *stack.stackp;
                            break;
                        case EXPRESSION_RSUBTRACT:
                            *(stack.stackp - 1) = *stack.stackp - *(stack.stackp - 1);
                            break;
                        case EXPRESSION_SHIFT_UP:
                            *(stack.stackp - 1) <<= *stack.stackp;
                            break;
                        case EXPRESSION_RSHIFT_UP:
                            *(stack.stackp - 1) =
                                *stack.stackp << *(stack.stackp - 1);
                            break;
                        case EXPRESSION_SHIFT_DOWN:
                            *(stack.stackp - 1) >>= *stack.stackp;
                            break;
                        case EXPRESSION_RSHIFT_DOWN:
                            *(stack.stackp - 1) =
                                *stack.stackp >> *(stack.stackp - 1);
                            break;
                        case EXPRESSION_LESS:
                            *(stack.stackp - 1) =
                                *(stack.stackp - 1) < *stack.stackp;
                            break;
                        case EXPRESSION_LESS_EQUAL:
                            *(stack.stackp - 1) = *(stack.stackp - 1) <= *stack.stackp;
                            break;
                        case EXPRESSION_GREATER:
                            *(stack.stackp - 1) = *(stack.stackp - 1) > *stack.stackp;
                            break;
                        case EXPRESSION_GREATER_EQUAL:
                            *(stack.stackp - 1) = *(stack.stackp - 1) >= *stack.stackp;
                            break;
                        case EXPRESSION_EQUAL:
                            *(stack.stackp - 1) = *(stack.stackp - 1) == *stack.stackp;
                            break;
                        case EXPRESSION_NOT_EQUAL:
                            *(stack.stackp - 1) = *(stack.stackp - 1) != *stack.stackp;
                            break;
                        case EXPRESSION_BITWISE_AND:
                            *(stack.stackp - 1) = *(stack.stackp - 1) & *stack.stackp;
                            break;
                        case EXPRESSION_BITWISE_XOR:
                            *(stack.stackp - 1) = *(stack.stackp - 1) ^ *stack.stackp;
                            break;
                        case EXPRESSION_BITWISE_OR:
                            *(stack.stackp - 1) = *(stack.stackp - 1) | *stack.stackp;
                            break;
                        case EXPRESSION_LOGICAL_AND:
                            *(stack.stackp - 1) = *(stack.stackp - 1) && *stack.stackp;
                            break;
                        case EXPRESSION_LOGICAL_OR:
                            *(stack.stackp - 1) = *(stack.stackp - 1) || *stack.stackp;
                            break;
                        default:
                            yyerror( "Invalid operator %d\n",
                                    ELF32_R_TYPE(rel->r_info) );
                            break;
                    }
#if DEBUG_EXPRESSION
                    printf( "binop = %d\n", *(stack.stackp - 1) );
#endif
                }
            }
            ++rel;
        }
    }
    assert( stack.stackp == stack.stack + 1 );
    return stack.stack[0];
}

static void relocate( void )
{
    OBJECT_FILE *file;
    Elf_Scn *rel_scn;
    Elf32_Shdr *rel_shdr, *code_shdr;
    Elf_Data *rel_data, *code_data;
    Elf32_Rela *relcurrent;
    Elf32_Rela *relscan;
    Elf32_Rela *relend;
    const char *fixup_error;
    int fixup;

    file = objects;
    while (file)
    {
        rel_scn = NULL;
        while ((rel_scn = elf_nextscn(file->elf, rel_scn)) != 0)
        {
            rel_shdr = elf32_getshdr(rel_scn);
            elfcheck( rel_shdr != NULL );
            if (rel_shdr->sh_type == SHT_RELA)
            {
                rel_data = exec_getdata(rel_scn);
                relcurrent = rel_data->d_buf;
                relend = relcurrent + rel_data->d_size/sizeof(Elf32_Rela);
                exec_getsection( file->elf, rel_shdr->sh_info,
                                 &code_shdr, &code_data );
                assert( fixup_code != NULL );
                while ( relcurrent < relend )
                {
                    relscan = relcurrent + 1;
                    while ( relscan < relend &&
                            relscan->r_offset == relcurrent->r_offset )
                    {
                        ++relscan;
                    }
                    fixup = relocation_expression( relcurrent, relscan - 1, file );
                    fixup_error = (*fixup_code)(
                        ELF32_R_TYPE( (relscan - 1)->r_info ) & EXPRESSION_MASK,
                        fixup, (relscan - 1)->r_offset,
                        code_shdr, code_data->d_buf );
                    if ( fixup_error )
                    {
                        yyerror( "%s in %s:\n"
                                 "\tsection %s @ 0x%08x: 0x%x",
                                 fixup_error, file->name,
                                 elf_strptr( file->elf, file->string_index,
                                             code_shdr->sh_name ),
                                 relcurrent->r_offset/code_shdr->sh_entsize,
                                 fixup );
                    }
                    relcurrent = relscan;
                }
            }
        }
        file = file->next_object;
    }
}

static const char headerfmt1[] =
"  %s sections:\n";
static const char headerfmt2[] =
"    Start  Size  Name\n";
static const char listfmt[] =
"    %04lX   %04lX  %s\n";
static const char none_text[] = "    None\n";
static const char * const section_type[] =
{
    "Program",
    "Data"
};

typedef struct symbol_control symbol_control_t;
typedef struct symbol_ref symbol_ref_t;
typedef struct xref xref_t;

struct symbol_control
{
    FILE *file;
    int print_count;
};

/*** IF symbol_ref CHANGES, FIX SWAP IN MAP_DUPLICATE ****/
struct symbol_ref
{
    bbtree_node_t node;
    symbol_ref_t *dup_list;
    Elf32_Sym *symbol;
    Elf32_Shdr *shdr;
    OBJECT_FILE *file;
    xref_t *xrefs;
};

struct xref
{
    xref_t *next;
    Elf32_Rela *relocation;
    Elf32_Shdr *code_shdr;
    OBJECT_FILE *file;
};

static void print_node( bbtree_t *tree, bbtree_node_t *node,
                        void *control )
{
    OBJECT_FILE *file;
    Elf32_Sym *symbol;
    Elf32_Addr offset;
    symbol_control_t *symbol_control = control;
    symbol_ref_t *symbol_ref = (symbol_ref_t *)node;
    int global;
    xref_t *xref;

    while ( symbol_ref )
    {
        symbol = symbol_ref->symbol;
        file = symbol_ref->file;
        global = ELF32_ST_BIND( symbol->st_info ) == STB_GLOBAL;
        if ( symbol->st_shndx != SHN_UNDEF )
        {
            fprintf( symbol_control->file,
                     "  %-16s @%c %-16s %04X  %04X  %04X  %s\n",
                     file->strings + symbol->st_name,
                     global ? ' ' : '*',
                     symbol_ref->shdr->sh_name + file->strings,
                     symbol->st_value,
                     symbol->st_value - symbol_ref->shdr->sh_addr,
                     symbol->st_size,
                     file->name );
            ++symbol_control->print_count;
        }
        xref = symbol_ref->xrefs;
        while ( xref )
        { 
            offset = xref->relocation->r_offset /
                xref->code_shdr->sh_entsize;
            fprintf( symbol_control->file,
                     "  %-16s  %c %-16s %04X  %04X        %s\n",
                     file->strings + symbol->st_name,
                     global ? ' ' : '*',
                     xref->code_shdr->sh_name + xref->file->strings,
                     offset + xref->code_shdr->sh_addr,
                     offset,
                     xref->file->name );
            xref = xref->next;
        }
        symbol_ref = symbol_ref->dup_list;
    }
}

static OBJECT_FILE *exec_next_object( const char *current )
{
    OBJECT_FILE *found, *scan;

    found = NULL;
    scan = objects;
    while ( scan )
    {
        if ( found == NULL )
        {
            if ( strcasecmp( scan->name, current ) > 0 )
            {
                found = scan;
            }
        }
        else if ( strcasecmp( scan->name, found->name ) < 0 &&
                  strcasecmp( scan->name, current ) > 0 )
        {
            found = scan;
        }
        scan = scan->next_object;
    }
    return found;
}

static int symbolcmpfn( const void *key, const bbtree_node_t *element )
{ 
    symbol_ref_t *symbol_ref = (struct symbol_ref *)element;

    return strcasecmp( (char *)key, 
                       symbol_ref->file->strings + symbol_ref->symbol->st_name );
}

static void map_duplicate( symbol_ref_t *parent, symbol_ref_t *child )
{
    symbol_ref_t swap;
    symbol_ref_t *scan;
    symbol_ref_t *last_scan;
    Elf32_Sym *symbol;
    OBJECT_FILE *file;
    int compare;
    unsigned char symbol_bind;
    unsigned char scan_bind;

    scan = parent;
    last_scan = NULL;
    symbol = child->symbol;
    file = child->file;
    compare = 1;
    while ( compare > 0 )
    {
        if ( scan )
        {
            compare = strcmp( scan->file->strings + scan->symbol->st_name,
                              file->strings + symbol->st_name );
            if ( compare == 0 )
            {
                compare = scan->symbol->st_value -
                    symbol->st_value;
                if ( compare == 0 )
                {
                    symbol_bind = ELF32_ST_BIND( symbol->st_info );
                    scan_bind = ELF32_ST_BIND( scan->symbol->st_info );
                    if ( symbol_bind == scan_bind )
                    {
                        if ( symbol_bind == STB_GLOBAL )
                        {
                            if ( symbol->st_shndx != scan->symbol->st_shndx )
                            {
                                if ( symbol->st_shndx == SHN_UNDEF )
                                {
                                    compare = 1;
                                }
                                else
                                {
                                    compare = -1;
                                }
                            }
                        }
                        if ( compare == 0 )
                        {
                            compare = strcmp( scan->file->name,
                                              file->name );
                        }
                    }
                    else if ( symbol_bind == STB_GLOBAL )
                    {
                        /* scan must be local */
                        compare = -1;
                    }
                    else
                    {
                        compare = 1;
                    }
                }
            }
        }
        else
        { 
            compare = -1;
        }
        if ( compare <= 0 )
        {
            /* swap the parent with the child */
            if ( last_scan == NULL )
            {
                memmove( &swap.dup_list, &scan->dup_list,
                         sizeof( swap ) - sizeof( swap.node ) );
                memmove( &scan->dup_list, &child->dup_list,
                         sizeof( *scan ) - sizeof( scan->node ) );
                memmove( &scan->dup_list, &swap.dup_list,
                         sizeof( *scan ) - sizeof( scan->node ) );
                scan->dup_list = child;
            }
            else
            {
                child->dup_list = last_scan->dup_list;
                last_scan->dup_list = child;
            }
        }
        last_scan = scan;
        if ( scan )
        {
            scan = scan->dup_list;
        }
    }
}

static void write_output_sections( FILE *map_file )
{
    int i;
    unsigned long start;
    unsigned long length;
    const char *name;
    int find_program;

    fprintf( map_file, "Output Sections\n" );
    find_program = TRUE;
    for ( i = 0 ; i < 2 ; ++i )
    {
        fprintf( map_file, headerfmt1, section_type[i] );
        fprintf( map_file, headerfmt2 );
        start = 0;
        while ( outfile_next_section( &start, &length, &name,
                                      find_program ) )
        {
            fprintf( map_file, listfmt, start, length, name );
            ++start;
        }
        fprintf( map_file, "\n" );
        find_program = FALSE;
    }
}

static void write_input_sections( FILE *map_file )
{
    int i;
    OBJECT_FILE *file;
    const char *current_name;
    Elf_Scn *section;
    Elf32_Shdr *shdr;
    Elf32_Shdr *found_shdr;
    unsigned long start;
    int word_size;
    int section_count;
    static Elf32_Word sh_flags[] = { SHF_EXECINSTR, 0 };
    static const char headerfmt1[] =
        "%s sections:\n";

    fprintf( map_file, "\nInput Sections by File\n" );
    file = objects;
    current_name = "";
    while( (file = exec_next_object( current_name )) )
    {
        word_size = 3;
        for ( i = 0 ; i < 2 ; ++i )
        {
            fprintf( map_file, "  %s - ", file->name );
            fprintf( map_file, headerfmt1, section_type[i] );
            fprintf( map_file, headerfmt2 );

            section = NULL;
            start = 0;
            section_count = 0;
            found_shdr = (Elf32_Shdr *)NULL + 1;
            while ( found_shdr )
            {
                found_shdr = NULL;
                while ((section = elf_nextscn(file->elf, section)) != 0)
                {
                    shdr = elf32_getshdr(section);
                    elfcheck( shdr != NULL );
                    if ( (shdr->sh_flags & SHF_EXECINSTR) == sh_flags[i] &&
                         (shdr->sh_type == SHT_PROGBITS ||
                          shdr->sh_type == SHT_NOBITS) &&
                         shdr->sh_addr >= start )
                    {
                        if ( found_shdr )
                        {
                            if ( shdr->sh_addr < found_shdr->sh_addr )
                            {
                                found_shdr = shdr;
                            }
                        }
                        else
                        {
                            found_shdr = shdr;
                        }
                    }
                }
                if ( found_shdr )
                {
                    fprintf( map_file, listfmt,
                             (unsigned long)found_shdr->sh_addr,
                             (unsigned long)(found_shdr->sh_size/word_size),
                             file->strings + found_shdr->sh_name );
                    start = found_shdr->sh_addr + 1;
                    ++section_count;
                }
            }
            if ( section_count == 0 )
            {
                fprintf( map_file, none_text );
            }
            word_size = 2;
            fprintf( map_file, "\n" );
        }
        current_name = file->name;
    }
}


static void list_xrefs(
    array_t *xref_array,  /* the pool to allocate xref_t's from */
    OBJECT_FILE *file,    /* the file to cross reference */
    xref_t **xref_map     /* map of xref lists to symbols by symbol index */
)
{
    Elf_Scn *section;
    Elf32_Shdr *shdr;
    Elf32_Shdr *code_shdr;
    Elf32_Rela *relocations;
    Elf_Data *data;
    int xrefs_available;
    int xrefs_added;
    xref_t *xref;
    xref_t **xref_scan;
    int count;
    int i;
    int symbol_index;

    /* find all of the REL sections.
     * For each symbol, we'll search all of these for references to
     * that symbol. */
    for ( i = 0 ; i < max_symbols ; ++i )
    {
        xref_map[i] = NULL;
    }
    xrefs_available = xrefs_added = 0;
    section = NULL;
    while ((section = elf_nextscn(file->elf, section)) != 0)
    {
        shdr = elf32_getshdr(section);
        elfcheck( shdr != NULL );
        if (shdr->sh_type == SHT_RELA)
        {
            data = exec_getdata(section);
            count = data->d_size/sizeof(Elf32_Rela);
            relocations = data->d_buf;
            exec_getsection( file->elf, shdr->sh_info, &code_shdr, NULL );
            for ( i = 0 ; i < count ; ++i )
            {
                symbol_index = ELF32_R_SYM(relocations->r_info);
                if ( symbol_index >= file->first_global ||
                     (map_flags & MAP_INCLUDE_LOCALS) != 0 )
                {
                    if ( xrefs_added >= xrefs_available )
                    {
                        array_update( xref_array, xrefs_added );
                        xrefs_added = 0;
                        xref = array_alloc( xref_array,
                                            &xrefs_available );
                    }
                    xref->relocation = relocations;
                    xref->code_shdr = code_shdr;
                    xref->file = file;
                    xref_scan = &xref_map[symbol_index];
                    while( *xref_scan &&
                           xref->relocation->r_offset > (*xref_scan)->relocation->r_offset )
                    {
                        xref_scan = &(*xref_scan)->next;
                    }
                    xref->next = *xref_scan;
                    *xref_scan = xref;
                    ++xref;
                    ++xrefs_added;
                }
                ++relocations;
            }
        }
    }
}

static void write_symbols( FILE *map_file )
{
    OBJECT_FILE *file;
    bbtree_t symbol_tree;
    bbtree_node_t *parent;
    int compare;
    array_t symbol_ref_array;
    int refs_available;
    int refs_added;
    symbol_ref_t *symbol_ref;
    array_t xref_array;
    xref_t **xref_map;
    symbol_control_t control;
    int i;
    Elf32_Sym *symbol;
    static const char legend[] =
        "  Name                Section          Addr  Off   Size  File\n";

    array_init( &symbol_ref_array, sizeof( symbol_ref_t ),
                128 );
    refs_available = refs_added = 0;
    array_init( &xref_array, sizeof( xref_t ), 64 );
    xref_map = malloc( max_symbols * sizeof( xref_t * ) );
    if ( xref_map == NULL )
    {
        fprintf( stderr, "Failed to allocate memory for xref_map\n" );
        abort();
    }
    for ( i = 0 ; i < max_symbols ; ++i )
    {
        xref_map[i] = NULL;
    }
    bbtree( &symbol_tree, symbolcmpfn, 0 );
    file = objects;
    while (file)
    {
        if ( (map_flags & MAP_GEN_XREF) != 0 )
        {
            list_xrefs( &xref_array, file, xref_map );
        }
        if ( map_flags & MAP_INCLUDE_LOCALS )
        {
            symbol = file->symbols + 1;
            i = 1;
        }
        else
        {
            symbol = file->symbols + file->first_global;
            i = file->first_global;
        }

        for ( ; i < file->symbol_count ; ++i )
        {
            if ( (map_flags & MAP_GEN_XREF) != 0 ||
                 symbol->st_shndx != SHN_UNDEF )
            {
                if ( refs_added >= refs_available )
                {
                    array_update( &symbol_ref_array, refs_added );
                    refs_added = 0;
                    symbol_ref = array_alloc( &symbol_ref_array,
                                         &refs_available );
                }
                parent = bbtree_preinsert( &symbol_tree,
                                           file->strings + symbol->st_name,
                                           &compare );
                symbol_ref->dup_list = NULL;
                symbol_ref->symbol = symbol;
                symbol_ref->file = file;
                symbol_ref->xrefs = xref_map[i];
                exec_getsection( file->elf, symbol->st_shndx,
                                 &symbol_ref->shdr, NULL );
                if (!parent || compare != 0)
                {
                    bbtree_insert( &symbol_tree, parent, &symbol_ref->node,
                                   compare );
                }
                else /* duplicate entry, insert in dup_list */  
                {
                    map_duplicate( (symbol_ref_t *)parent,
                                   symbol_ref );
                }
                ++symbol_ref;
                ++refs_added;
            }
            ++symbol;
        }
        file = file->next_object;
    }
    fprintf( map_file, "\nSymbols:\n" );
    fprintf( map_file, legend );
    control.file = map_file;
    control.print_count = 0;
    bbtree_leftright_walk( &symbol_tree, symbol_tree.root,
                           print_node, &control );
    if ( control.print_count == 0 )
    {
        fprintf( map_file, none_text );
    }
    bbtree_destroy( &symbol_tree, NULL );
    free( xref_map );
    array_destroy( &xref_array );
    array_destroy( &symbol_ref_array );
}

static void write_map_file( void )
{
    FILE *map_file;
    time_t now;

    if (map_file_name)
    {
        map_file = fopen( map_file_name, "w" );
        if (map_file)
        {
            now = time(NULL);
            fprintf( map_file, "%s\n%s\n",
                     version,
                     ctime(&now) );
            write_output_sections( map_file );
            write_input_sections( map_file );
            write_symbols( map_file );
            fclose( map_file );
        }
        else
        {
            yyerror( "Unable to open %s as map file: %s.\n",
                     map_file_name, strerror(errno) );
        }
    }
}

void objects_link( void )
{
    bbtree( &globals, comparefn, 0 );
    fixup_symbols( );
#if 0
    resolve_globals( );
#endif
    relocate( );
    write_map_file( );
    bbtree_destroy( &globals, bbtree_deletefn );
}










