/*
 * outfile.c
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
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <assert.h>
#include "defs.h"
#include "adielf.h"
#include "outfile.h"
#include "dllist.h"

extern void yyerror( const char *fmt, ... );

/* size page data so as not to waste any space */
#define PAGE_DATA_SIZE        (32*sizeof(Elf32_Sym))
#define MAX_STRING_SIZE       (PAGE_DATA_SIZE-1) /* string + null fits on a page */
/*
 * MAX_SYMBOL_INDEX is restricted to 24 bits by how it is included int r_info
 * in a relocation entry
 */
#define MAX_SYMBOL_INDEX      ((1<<24) - 1)
#define ELF_ALIGN(offset)     ((offset) + sizeof(Elf32_Off) - 1) & \
                              ~(sizeof(Elf32_Off) - 1)

typedef struct SECTION_PAGE
{
    dllist_t dllist;
    int size;
    int delta;
    union
    {
        char strings[PAGE_DATA_SIZE];
        unsigned char code[PAGE_DATA_SIZE];
        Elf32_Rela relocations[PAGE_DATA_SIZE/sizeof(Elf32_Rela)];
        Elf32_Sym symbols[PAGE_DATA_SIZE/sizeof(Elf32_Sym)];
    } data;
} SECTION_PAGE;

typedef struct PAGE_LIST
{
    dllist_t dllist;
    /*
     * Meaning of offset is section specific. For code sections, its the
     * location counter. For string sections its the offset of the next
     * string to be saved. For arrays, ie. rel/symtab sections, its the
     * symbol/relocation index.
     */
    size_t offset;
} PAGE_LIST;

#define page_next(page) \
    ((SECTION_PAGE *)dllist_next(&(page)->dllist))
#define page_prev(page) \
    ((SECTION_PAGE *)dllist_prev(&(page)->dllist))
#define page_list_head(page_list) \
    ((SECTION_PAGE *)&(page_list)->dllist)
#define page_list_isempty(page_list) \
    (dllist_isempty(&(page_list)->dllist))
#define page_list_last(page_list) \
    ((SECTION_PAGE *)dllist_prev(&(page_list)->dllist))
#define page_list_join(page_list,insert) \
    (dllist_join(&(page_list)->dllist,&(insert)->dllist))

typedef struct
{
    SECTION_PAGE *page;
    size_t offset;
    unsigned long page_index;
} WALK;

typedef struct SECTION
{
    struct SECTION *next;
    const char *name;
    Elf_Scn *scn;
    Elf32_Shdr *shdr;
    struct SECTION *relocations;
    memory_space_t space;
    PAGE_LIST pages; /* pages of section data */
    WALK walk;
} SECTION;

typedef struct align_block_t
{
    SECTION_PAGE *page;
    int symbol_index, relocation_index;
    size_t offset;
} align_block_t;

typedef struct
{
    int fd;
    int code_size;
    int data_size;
    Elf *elf;
    Elf32_Ehdr *ehdr;
    int program_sections;
    SECTION *code_sections;
    SECTION *string_section;
    SECTION *symbol_section;
    align_block_t align;
} OUT_FILE;

static OUT_FILE outfile;

static void init_page_list( PAGE_LIST *page_list )
{
    dllist_init(&page_list->dllist);
    page_list->offset = 0;
}

static void free_page_list( PAGE_LIST *page_list )
{
    dllist_t *remove;

    while (!dllist_isempty(&page_list->dllist))
    {
        remove = dllist_remove(dllist_next(&page_list->dllist));
        free( remove );
    }
    init_page_list( page_list );
}

static SECTION *remlist_section( SECTION **section )
{
    SECTION *removed;

    removed = *section;
    assert( removed != NULL );
    *section = removed->next;
    return removed;
}

static void inslist_section( SECTION *section )
{
    section->next = outfile.code_sections;
    outfile.code_sections = section;
}

static SECTION *new_section( Elf32_Word type )
{
    SECTION *section;

    section = (SECTION *)malloc(sizeof(*section));
    if (section)
    {
        /* initialize new section */
        section->name = NULL;
        section->scn = elf_newscn(outfile.elf);
        elfcheck( section->scn != NULL );
        section->shdr =
            elf32_getshdr(section->scn);
        elfcheck( section->shdr != NULL );
        section->shdr->sh_type = type;
        section->shdr->sh_addralign = 1;
        section->relocations = NULL;
        init_page_list( &section->pages );
        section->next = NULL;
        section->walk.page = NULL;
        section->walk.offset = 0;
        section->walk.page_index = 0;
    }
    else
    {
        fprintf( stderr,"new_section: malloc failed\n" );
        exit(1);
    }
    return section;
}

static void free_sections( SECTION *section )
{
    SECTION *next;

    while (section)
    {
        free_sections( section->relocations );
        /* free all associated pages */
        free_page_list( &section->pages );
        next = section->next;
        free(section);
        section = next;
    }
}


static SECTION_PAGE *new_page( PAGE_LIST *page_list, int size )
{
    SECTION_PAGE *page;

    assert( size >= 0 );
    if (size == 0)
    {
        size = sizeof(*page);
    }
    else
    {
        size = size + sizeof(*page) - sizeof(page->data);
    }
    /* allocate and initialize a new code page */
    page = (SECTION_PAGE *)malloc(size);
    if (page)
    {
        memset( page, 0, size );
        /* prepending to list head appends to list */
        dllist_prepend(&page_list->dllist,&page->dllist);
    }
    else
    {
        fprintf( stderr, "Failed to allocate page\n" );
        abort();
    }
    return page;
}

static void create_elf_data( SECTION *section )
{
    SECTION_PAGE *page;
    Elf_Data *elf_data;
    Elf32_Off offset;

    while (section)
    {
        if ( section->shdr->sh_type == SHT_NOBITS )
        {
            assert( section->relocations == NULL );
            elf_data = elf_newdata(section->scn);
            elfcheck( elf_data != NULL );
            elf_data->d_buf = NULL;
            elf_data->d_size = section->pages.offset *
                section->shdr->sh_entsize;
            elf_data->d_align = 0;
            elf_data->d_off = 0;
        }
        else
        {
            page = page_next(&section->pages);
            offset = 0;
            if ( page == page_list_head(&section->pages) )
            {
                /* if the section is empty, make it NOBITS
                 * because libelf doesn't like a non-NOBITS section
                 * with no data */
                elf_data = elf_newdata(section->scn);
                elfcheck( elf_data != NULL );
                elf_data->d_buf = NULL;
                elf_data->d_size = 0;
                elf_data->d_align = 0;
                elf_data->d_off = 0;
                section->shdr->sh_type = SHT_NOBITS;
            }
            else
            {
                while (page != page_list_head(&section->pages))
                {
                    elf_data = elf_newdata(section->scn);
                    elfcheck( elf_data != NULL );
                    elf_data->d_buf = &page->data;
                    elf_data->d_size = page->size;
                    elf_data->d_align = 0;
                    elf_data->d_off = offset + page->delta;
                    offset = elf_data->d_off + elf_data->d_size;
                    page = page_next(page);
                }
                create_elf_data( section->relocations );
            }
        }
        section = section->next;
    }
}


/*
 * outfile_add_string - add string to the string section of an output
 *                     file.
 * string - the string to add
 * where - a pointer to the saved string. Used by the program for 
 *         name searches etc.
 *
 * Return:
 *   Index into the section header string table.
 */
static Elf32_Word outfile_add_string( const char *string, const char **where )
{
    SECTION_PAGE *page;
    size_t size;
    PAGE_LIST *page_list;

    if (outfile.string_section == NULL)
    { 
        outfile.string_section = new_section( SHT_STRTAB );
        elfcheck( outfile.string_section != NULL );
        outfile.ehdr->e_shstrndx =
            elf_ndxscn(outfile.string_section->scn);
        elfcheck( outfile.ehdr->e_shstrndx != SHN_UNDEF );
        outfile.string_section->shdr->sh_name =
            outfile_add_string( ".strtab",
                                &outfile.string_section->name );
    }

    size = strlen( string ) + 1;
    if (size > MAX_STRING_SIZE)
    {
        yyerror( "Long symbol name truncated." );
        size = MAX_STRING_SIZE;
    }

    page_list = &outfile.string_section->pages;

    page = page_list_last(page_list);
    if (page_list_isempty(page_list) ||
        page->size + size > sizeof(page->data.strings))
    {
        /* allocate and initialize a new code page */
        page = new_page( page_list, 0 );
    }

    /* insert the UNDEF string */
    if (page_list->offset == 0)
    {
        page->data.strings[0] = '\0';
        ++page->size;
        ++page_list->offset;
    }
    /* after all that, put the string in the table */
    strncpy( page->data.strings + page->size,
             string, size - 1 );
    page->data.strings[page->size + size - 1] = '\0';
    if (where)
    {
        *where = page->data.strings + page->size;
    }

    page->size += size;
    page_list->offset += size;
    
    return page_list->offset - size;
}


/*
 * Start from the beginning of the symbol table looking for globals.
 * Swap any found with local symbols from the end of the symbol table.
 * Track the swaps to use in updating the relocation table.
 */
static void outfile_sort_globals( void )
{
    SECTION *code_section, *rel_section;
    SECTION_PAGE *global_page, *local_page, *rel_page;
    Elf32_Sym swap;
    Elf32_Sym *global, *global_end;
    Elf32_Sym *local, *local_end;
    Elf32_Rela *rel, *rel_end;
    Elf32_Word *swap_list, rel_symbol;
    int global_index, local_index, symbol_count;
    int matched;

    if (outfile.symbol_section)
    {
        symbol_count = outfile.symbol_section->pages.offset;
        swap_list = (Elf32_Word *)malloc( symbol_count * sizeof(Elf32_Word) );
        if (swap_list == NULL)
        {
            fprintf( stderr, "Unable to allocate global swap list.\n" );
            abort();
        }
        /* initialize the swap list to an invalid value */
        for ( global_index = 0 ;
              global_index < symbol_count ;
              ++global_index )
        {
            swap_list[global_index] = symbol_count;
        }
        global_index = 0;
        global_page = page_list_head( &outfile.symbol_section->pages );
        global = global_end = NULL;

        local_index = symbol_count;
        local_page = page_list_head( &outfile.symbol_section->pages );
        local = NULL;
        local_end = local + 1;
        while (global_index < local_index)
        {
            if (global >= global_end)
            {
                global_page = page_next( global_page );
                global = global_page->data.symbols;
                global_end = global + global_page->size / sizeof( *global );
            }
            /* if this is a global find a local to swap with it */
            if (ELF32_ST_BIND(global->st_info) != STB_LOCAL)
            {
                matched = FALSE;
                while (!matched && global_index < local_index)
                {
                    --local_index;
                    if (local < local_end)
                    {
                        local_page = page_prev( local_page );
                        local_end = local_page->data.symbols;
                        local = local_end + local_page->size / sizeof( *local )
                            - 1;
                    }
                    if (ELF32_ST_BIND(local->st_info) == STB_LOCAL)
                    {
                        memcpy( &swap, local, sizeof(swap) );
                        memcpy( local, global, sizeof(*local) );
                        memcpy( global, &swap, sizeof(*global) );
                        swap_list[global_index] = local_index;
                        swap_list[local_index] = global_index;
                        matched = TRUE;
                        ++global;
                        ++global_index;
                    }
                    --local;
                }
            }
            else
            {
                ++global;
                ++global_index;
            }
        }
        outfile.symbol_section->shdr->sh_info = global_index;
        
        /* fixup relocations */
        code_section = outfile.code_sections;
        while (code_section)
        {
            rel_section = code_section->relocations;
            if (rel_section)
            {
                rel_page = page_list_head( &rel_section->pages ); 
                while ((rel_page = page_next( rel_page )) !=
                       page_list_head( &rel_section->pages ) )
                {
                    rel = rel_page->data.relocations;
                    rel_end = rel + rel_page->size / sizeof(*rel);
                    while (rel < rel_end)
                    {
                        rel_symbol = ELF32_R_SYM( rel->r_info );
                        assert( rel_symbol < symbol_count );
                        if ( swap_list[rel_symbol] < symbol_count )
                        {
                            rel->r_info = ELF32_R_INFO(
                                swap_list[rel_symbol],
                                ELF32_R_TYPE( rel->r_info ) );
                        }
                        ++rel;
                    }
                }
            }
            code_section = code_section->next;
        }
        free( swap_list );
    }
}

void outfile_layout( int reserve )
{
    SECTION *section;
    Elf32_Shdr *shdr;
    Elf32_Off offset;

    offset = reserve;
    section = outfile.code_sections;
    while ( section )
    {
        shdr = section->shdr;
        shdr->sh_offset = offset = ELF_ALIGN(offset);
        shdr->sh_size = shdr->sh_entsize * section->pages.offset;
        if ( shdr->sh_type == SHT_PROGBITS )
        {
            offset += shdr->sh_size;
            if ( section->relocations )
            {
                assert( section->relocations->next == NULL );
                shdr = section->relocations->shdr;
                shdr->sh_offset = offset = ELF_ALIGN(offset);
                shdr->sh_size = shdr->sh_entsize *
                    section->relocations->pages.offset;
                offset += shdr->sh_size;
            }
        }
        else
        {
            assert( shdr->sh_type == SHT_NOBITS );
            assert( section->relocations == NULL );
        }
        section = section->next;
    }
    section = outfile.string_section;
    if ( section )
    {
        shdr = section->shdr;
        shdr->sh_offset = offset = ELF_ALIGN(offset);
        shdr->sh_size = section->pages.offset;
        offset += shdr->sh_size;
    }
    section = outfile.symbol_section;
    if ( section )
    {
        shdr = section->shdr;
        shdr->sh_offset = offset = ELF_ALIGN(offset);
        shdr->sh_size = shdr->sh_entsize * section->pages.offset;
        offset += shdr->sh_size;
    }
    outfile.ehdr->e_shoff = offset = ELF_ALIGN(offset);
}

/* ----------------------- external functions --------------------- */

#if 0
/* debug function for walking elf structures while running */
void elf_walk( Elf *elf )
{
    Elf32_Ehdr *ehdr;
    Elf_Scn *section;
    Elf32_Shdr *shdr;
    Elf_Data *data;
    char *strings = NULL;

    ehdr = elf32_getehdr( elf );
    if ( ehdr )
    {
        section = elf_getscn( elf, ehdr->e_shstrndx );
        if ( section )
        {
            data = elf_getdata( section, NULL );
            if ( data )
            {
                strings = data->d_buf;
            }
        }
        section = NULL;
        while ( (section = elf_nextscn( elf, section )) != NULL )
        {
            shdr = elf32_getshdr( section );
            if ( shdr )
            {
                printf( "section %d %s\n", shdr->sh_name,
                        strings != NULL ?
                            strings + shdr->sh_name : "UNKNOWN" );
                data = NULL;
                while ( (data = elf_getdata( section, data )) != NULL )
                {
                    printf( "%p, %d\n", data->d_buf, data->d_size );
                }
            }
            else
            {
                printf( "shdr is null\n" );
            }
        }
    }
    else
    {
        printf( "no ehdr\n" );
    }
}
#endif

int outfile_init( const char *outfile_name,
                  Elf32_Half machine,
                  int executable,
                  int code_size,
                  int data_size )
{
    if ((outfile.fd = open(outfile_name,
                           O_WRONLY | O_CREAT | O_TRUNC | O_BINARY,
                           S_IRUSR | S_IWUSR)) != -1)
    {
        if (elf_version(EV_CURRENT) != EV_NONE)
        {
            outfile.elf = elf_begin(outfile.fd, ELF_C_WRITE, NULL);
            if (outfile.elf)
            {
                outfile.ehdr = elf32_newehdr(outfile.elf);
                if (outfile.ehdr)
                {
                    elf_flagelf( outfile.elf, ELF_C_SET, ELF_F_LAYOUT );
                    outfile.ehdr->e_machine = machine;
                    if ( executable )
                    {
                        outfile.ehdr->e_type = ET_EXEC;
                    }
                    else
                    {
                        outfile.ehdr->e_type = ET_REL;
                    }
                    outfile.ehdr->e_version = EV_CURRENT;
                    outfile.program_sections = 0;
                    outfile.code_sections = NULL;
                    outfile.string_section = NULL;
                    outfile.symbol_section = NULL;
                    outfile.code_size = code_size;
                    outfile.data_size = data_size;
                    return 0;
                }
                else
                    fprintf( stderr, "outfile_init: elf32_newehdr - %s\n",
                             elf_errmsg(-1) );
            }
            else
                fprintf( stderr, "outfile_init: elf_begin - %s\n",
                         elf_errmsg(-1) );
        }
        else
            fprintf(stderr, "Elf library is out of date\n" );
    }
    else
        perror( "Failed to open output file" );

    return -1;
}

int outfile_term( int elf_flags )
{
    SECTION *section;
    Elf32_Phdr *phdr;
    Elf32_Shdr *shdr;
    int reserve;
    int i;
    off_t file_size;

    outfile.ehdr->e_flags = elf_flags;
    reserve = sizeof( Elf32_Ehdr );
    if (outfile.ehdr->e_type == ET_EXEC)
    {
        phdr = elf32_newphdr( outfile.elf, outfile.program_sections );
        elfcheck( phdr != NULL );
        reserve += outfile.program_sections * sizeof(*phdr);
    }
    else
    {
        /* no symbols and data should already exist for an elf file */
        outfile_sort_globals( );
        create_elf_data( outfile.code_sections );
        create_elf_data( outfile.symbol_section );
    }
    create_elf_data( outfile.string_section );

    outfile_layout( reserve );

    if (outfile.ehdr->e_type == ET_EXEC && phdr != NULL)
    {
        outfile.ehdr->e_phoff = sizeof( Elf32_Ehdr );
        section = outfile.code_sections;
        for ( i = 0 ; section && i < outfile.program_sections ; ++i )
        {
            shdr = section->shdr;
            phdr->p_type = PT_LOAD;
            phdr->p_vaddr = shdr->sh_addr;
            phdr->p_offset = shdr->sh_offset;
            phdr->p_memsz = shdr->sh_size;
            if ( shdr->sh_type == SHT_PROGBITS )
            {
                phdr->p_filesz = shdr->sh_size;
            }
            else
            {
                phdr->p_filesz = 0;
            }
            phdr->p_flags = PF_R;
            if ((shdr->sh_flags & SHF_EXECINSTR) != 0)
            {
                phdr->p_flags |= PF_X;
            }
            if ((shdr->sh_flags & SHF_WRITE) != 0)
            {
                phdr->p_flags |= PF_W;
            }
            ++phdr;
            section = section->next;
        }
    }
    file_size = elf_update(outfile.elf, ELF_C_WRITE);
    elfcheck( file_size >= 0 );
    elf_end(outfile.elf);
    close(outfile.fd);
    free_sections( outfile.code_sections );
    free_sections( outfile.string_section );
    free_sections( outfile.symbol_section );
    return 0;
}

void outfile_emit( unsigned long code )
{
    SECTION_PAGE *page;
    PAGE_LIST *page_list;
    int byte_shift;
    Elf32_Shdr *shdr;

    if (outfile.code_sections == NULL)
    {
        return;
    }
    shdr = outfile.code_sections->shdr;
    if ( shdr->sh_type == SHT_NOBITS )
    {
        ++outfile.code_sections->pages.offset;
        yyerror( "Attempt to initialize an unitialized section" );
        return;
    }

    page_list = &outfile.code_sections->pages;

    page = page_list_last(page_list);
    if (page_list_isempty(page_list) ||
        page->size + shdr->sh_entsize  >= sizearray(page->data.code))
    { 
        /* allocate and initialize a new code page */
        page = new_page( page_list, 0 );
    }

    for ( byte_shift = (shdr->sh_entsize - 1) * 8 ;
          byte_shift >= 0 ; byte_shift -= 8 )
    {
        page->data.code[page->size++] = code >> byte_shift;
    }
    ++page_list->offset;
}

unsigned long outfile_emit_bss( unsigned long size )
{
    unsigned long i;

    if ( outfile.code_sections->shdr->sh_type == SHT_NOBITS )
    {
        outfile.code_sections->pages.offset += size;
        size = 0;
    }
    else
    {
        for ( i = 0 ; i < size ; ++i )
        {
            outfile_emit( 0 );
        }
    }
    return size;
}

void outfile_memorize_section(  Elf_Scn *section,
                                unsigned long *start_used,
                                unsigned long end,
                                unsigned long width )
{
    Elf32_Shdr *in_shdr, *out_shdr;
    Elf_Data *data_in, *data_out;
    SECTION_PAGE *page;
    int align, size, byte_size;
    int add_first;
    void *buffer;

    add_first = FALSE;
    data_in = elf_getdata(section, NULL);
    elfcheck( data_in != NULL );
    in_shdr = elf32_getshdr(section);
    elfcheck( in_shdr != NULL );
    out_shdr = outfile.code_sections->shdr;

    /* if this section isn't code or data yet make it the same
    * as the input section
    */
    if (out_shdr->sh_flags == 0)
    {
        out_shdr->sh_type = in_shdr->sh_type;
        out_shdr->sh_flags = in_shdr->sh_flags;
        out_shdr->sh_entsize = in_shdr->sh_entsize;
        if ((in_shdr->sh_flags & SHF_EXECINSTR) != 0)
        {
            outfile.code_sections->space = SECTION_PROGRAM;
        }
        else
        {
            outfile.code_sections->space = SECTION_DATA;
        }
        out_shdr->sh_addr = *start_used;
        add_first = TRUE;
    }
    if (out_shdr->sh_type == in_shdr->sh_type)
    {
        if (in_shdr->sh_addralign > 1)
        {
            align = in_shdr->sh_addralign;
            size = ((*start_used + align - 1) & ~(align - 1)) -
                    *start_used;
            if (size > 0)
            {
                if (*start_used + size - 1 <= end)
                {
                    if ( add_first )
                    {
                        /* align by moving section */
                        *start_used += size;
                        out_shdr->sh_addr = *start_used;
                    }
                    else
                    {
                        /* align by filling */
                        byte_size = size * in_shdr->sh_entsize;
                        if ( in_shdr->sh_type == SHT_NOBITS )
                        {
                            buffer = NULL;
                        }
                        else
                        {
                            page = new_page( &outfile.code_sections->pages,
                                        byte_size );
                            page->size = byte_size;
                            buffer = &page->data;
                        }
                        data_out = elf_newdata(outfile.code_sections->scn);
                        elfcheck( data_out != NULL );
                        data_out->d_buf = buffer;
                        data_out->d_size = byte_size;
                        data_out->d_off = outfile.code_sections->pages.offset *
                            in_shdr->sh_entsize;
                        outfile.code_sections->pages.offset += size;
                        *start_used += size;
                    }
                }
                else
                {
                    yyerror( "Section won't fit in memory" );
                    return;
                }
            }
        }
        size = data_in->d_size / in_shdr->sh_entsize;
        if (*start_used + size <= end + 1)
        {
            in_shdr->sh_addr = *start_used;
            data_out = elf_newdata(outfile.code_sections->scn);
            elfcheck( data_out != NULL );
            data_out->d_buf = data_in->d_buf;
            data_out->d_size = data_in->d_size;
            data_out->d_off = outfile.code_sections->pages.offset *
                in_shdr->sh_entsize;
            outfile.code_sections->pages.offset += size;
            *start_used += size;
        }
        else
        {
            yyerror( "Section won't fit in memory" );
        }
    }
    else
    {
        yyerror( "Section type mismatch %d %d",
                 out_shdr->sh_type, in_shdr->sh_type );
    }
    return;
}

/* scan the list of sections, if section found move
 * it to head of list. Otherwise, create a new section
 */
int outfile_select_section( const char *name,
                            Elf32_Word section_type,
                            memory_space_t memory_space )
{
    SECTION **section, *selected;
    int result = 1;
    
    section = &outfile.code_sections;
    while (*section)
    {
        if (strcmp((*section)->name, name) == 0)
        {
            break;
        }
        section = &(*section)->next;
    }
    if (*section)
    {
        if (outfile.ehdr->e_type != ET_EXEC)
        {
            if ( (*section)->shdr->sh_type != section_type )
            {
                yyerror("Cannot mix SHT_NOBITS with SHT_PROGBITS sections");
                return 0;
            }
            /* remove found section from current spot in list */
            selected = remlist_section( section );
        }
        else
        {
            yyerror("Attempting to redefine an output section");
            return 0;
        }
    }
    else
    {
        /* section not found, creating a new one */
        selected = new_section( section_type );
        ++outfile.program_sections;
        selected->shdr->sh_name =
            outfile_add_string( name, &selected->name );
        switch (memory_space)
        {
            case SECTION_PROGRAM:
                selected->shdr->sh_flags |= SHF_ALLOC | SHF_WRITE | SHF_EXECINSTR;
                selected->shdr->sh_entsize = outfile.code_size;
                selected->space = SECTION_PROGRAM;
                break;
            case SECTION_DATA:
                selected->shdr->sh_flags |= SHF_ALLOC | SHF_WRITE;
                selected->shdr->sh_entsize = outfile.data_size;
                selected->space = SECTION_DATA;
                break;
            default:
                if (outfile.ehdr->e_type == ET_REL)
                {
                    yyerror("Invalid section type requested");
                    result = 0;
                }
                break;
        }
    }
    
    /* insert section at front of section list */
    inslist_section( selected );
    return result;
}

/*
 *  Returns:
 *    1 if there was a previous section, 0 if there
 *    0 if there wasn't
 */
int outfile_previous_section( void )
{
    SECTION **section;

    if (outfile.code_sections)
    {
        section = &outfile.code_sections->next;
        if (section)
        {
            inslist_section( remlist_section( section ) );
            return 1;
        }
    }
    return 0;
}

Elf32_Sym *outfile_add_symbol( const char *name, const char **where, 
                              int *elf_index )
{
    Elf32_Sym *symbol;
    SECTION_PAGE *page;
    PAGE_LIST *page_list;
    int is_new;
    
    if (outfile.symbol_section == NULL)
    { 
        /* create the symbol section */
        outfile.symbol_section = new_section( SHT_SYMTAB );
        outfile.symbol_section->shdr->sh_entsize = sizeof(Elf32_Sym);
        outfile.symbol_section->shdr->sh_name =
            outfile_add_string( ".symtab",
                                &outfile.symbol_section->name );
        outfile.symbol_section->shdr->sh_link =
            elf_ndxscn(outfile.string_section->scn);
        elfcheck( outfile.symbol_section->shdr->sh_link != SHN_UNDEF );
        is_new = TRUE;
    }
    else
    {
        is_new = FALSE;
    }
    page_list = &outfile.symbol_section->pages;

    page = page_list_last(page_list);
    if (page_list_isempty(page_list) ||
        page->size >= sizeof(page->data.symbols))
    {
        page = new_page( page_list, 0 );
    }
    
    symbol = page->data.symbols + (page->size/sizeof(*symbol));
    page->size += sizeof(*symbol);
    /* if this is a new section add the initial entry */
    if ( is_new )
    {
        /* since there is more then one entry per page and this is a new page
         * we won't have to allocate another page first */
        memset( symbol, 0, sizeof(*symbol) );
        page->size += sizeof(*symbol);
        ++page_list->offset;
        ++symbol;
    }
    if (strcmp( name, "" ) == 0)
    {
        symbol->st_name = 0;
    }
    else
    {
        symbol->st_name = outfile_add_string( name, where );
    }
    if (elf_index)
    {
        *elf_index = page_list->offset;
    }
    ++page_list->offset;
    return symbol;
}

void outfile_define_symbol( Elf32_Sym *elf_symbol, int size )
{
    if (outfile.code_sections && elf_symbol)
    {
        elf_symbol->st_value = outfile.code_sections->pages.offset;
        elf_symbol->st_size = size;
        elf_symbol->st_shndx = elf_ndxscn(outfile.code_sections->scn);
        elfcheck( elf_symbol->st_shndx != SHN_UNDEF );
    }
}

void outfile_globalize_symbol( Elf32_Sym *symbol )
{
    symbol->st_info = ELF32_ST_INFO( STB_GLOBAL, STT_NOTYPE );
}

void outfile_add_relocation( int symbol_index, int addend, int type )
{
    SECTION_PAGE *page;
    SECTION *section;
    Elf32_Rela *relocation;
    static char dot_rel[] = ".rela.";

    if (outfile.code_sections == NULL ||
        outfile.code_sections->shdr->sh_type == SHT_NOBITS)
    {
        /* error will be handled when code is emitted */
        return;
    }
    if (outfile.code_sections->relocations == NULL)
    { 
        char *name;

        /* create the symbol section */
        section = new_section( SHT_RELA);
        outfile.code_sections->relocations = section;
        section->shdr->sh_entsize = sizeof(Elf32_Rela);
        section->shdr->sh_link = elf_ndxscn(outfile.symbol_section->scn);
        elfcheck( section->shdr->sh_link != SHN_UNDEF );
        section->shdr->sh_info = elf_ndxscn(outfile.code_sections->scn);
        elfcheck( section->shdr->sh_info != SHN_UNDEF );
        name = (char *)malloc(strlen(dot_rel)+
                              strlen(outfile.code_sections->name) + 1);
        if (name)
        {
            strcpy( name, dot_rel);
            strcat( name, outfile.code_sections->name );
            section->shdr->sh_name =
                outfile_add_string( name, &section->name );
            free(name);
        }
        else
        {
            section->shdr->sh_name = 0;
            yyerror("Error naming relocation section");
        }
    }
    else
    {
        section = outfile.code_sections->relocations;
    }

    page = page_list_last(&section->pages);
    if (page_list_isempty(&section->pages) ||
        page->size >= sizeof(page->data.relocations))
    {
        page = new_page( &section->pages, 0 );
    }

    relocation = page->data.relocations + (page->size/sizeof(*relocation));
    page->size += sizeof(*relocation);
    ++section->pages.offset;
    relocation->r_offset = outfile.code_sections->pages.offset * 
        outfile.code_sections->shdr->sh_entsize;
    
    relocation->r_info = ELF32_R_INFO( symbol_index, type );
    relocation->r_addend = addend;
}

memory_space_t outfile_memory_space( void )
{
    if (!outfile.code_sections)
        return SECTION_NONE;
    return outfile.code_sections->space;
}

static void align_symbols( SECTION *symbol_section, alignment_t alignment,
                           int delta, Elf32_Half ref_index )
{
    SECTION_PAGE *page;
    Elf32_Sym *symbol, *last_symbol;
    int first;

    if (symbol_section)
    {
        first = TRUE; 
        page = page_next(&symbol_section->pages);
        while (page != page_list_head(&symbol_section->pages))
        {
            symbol = page->data.symbols;
            last_symbol = page->data.symbols + page->size / sizeof(*symbol);
            /* never update symbol 0 */
            if ( first )
            {
                assert( symbol < last_symbol );
                ++symbol;
                first = FALSE;
            }
            while ( symbol < last_symbol )
            {
                if ( symbol->st_shndx == ref_index &&
                     symbol->st_value >= alignment->offset )
                {
                    symbol->st_value += delta;
                }
                ++symbol;
            }
            page = page_next( page );
        }
    }
}

static void align_relocations( SECTION *relocation_section,
                               alignment_t alignment,
                               int delta )
{
    SECTION_PAGE *page;
    int index;
    Elf32_Rela *relocation;

    if (relocation_section)
    {
        page = (SECTION_PAGE *)&relocation_section->pages;
        for ( index = relocation_section->pages.offset - 1 ;
              index >= alignment->relocation_index ; )
        {
            page = page_prev( page );
            relocation = page->data.relocations + page->size /
                sizeof(*relocation);
            while ( relocation > page->data.relocations &&
                    index >= alignment->relocation_index )
            {
                --relocation;
                relocation->r_offset += delta;
                --index;
            }
        }
    }
}

int outfile_align(
    alignment_t *alignment,   /* alignment == NULL, simply align
                               * *alignment == NULL, initialize to align the
                               *                     current address later
                               * *alignment != NULL, align using the info
                               *                     pointed to */
    int by                    /* how much to align by */
)
{
    SECTION_PAGE *page;
    int align;
    enum { max_by = 1 << 14 };
    int delta;
    Elf32_Half ref_index;

    if (by >= max_by)
    {
        yyerror( "Alignment requirement is too large" );
        return 0;
    }
    for ( align = 1 ; align < by ; align <<= 1 )
        ;
    if (outfile.code_sections == NULL)
    { 
        yyerror( "No section to align" );
        return align;
    }

    if ( alignment == NULL || *alignment == NULL )
    {
        page = page_list_last( &outfile.code_sections->pages );
        /* if there is no code in this section yet or the current page
         * already has data, create a new page for the aligned data */
        if (page == (SECTION_PAGE *)&outfile.code_sections->pages ||
            page->size > 0)
        {
            page = new_page( &outfile.code_sections->pages, 0 );
        }

        if ( alignment == NULL )
        {
            if ( align > outfile.code_sections->shdr->sh_addralign )
            {
                outfile.code_sections->shdr->sh_addralign = align;
            }
            delta = ((outfile.code_sections->pages.offset + align - 1) &
                ~(align - 1)) - outfile.code_sections->pages.offset;
            outfile.code_sections->pages.offset += delta;
            page->delta = delta * outfile.code_sections->shdr->
                sh_entsize;
        }
        else if ( *alignment == NULL )
        {
            *alignment = &outfile.align;
            outfile.align.page = page;
            outfile.align.symbol_index = 0;
            outfile.align.relocation_index = 0;
            outfile.align.offset = outfile.code_sections->pages.offset;
            if (outfile.symbol_section)
            {
                outfile.align.symbol_index =
                    outfile.symbol_section->pages.offset;
            }
            if (outfile.code_sections->relocations)
            {
                outfile.align.relocation_index = 
                    outfile.code_sections->relocations->pages.offset;
            }
            /* by is ignored in this case */
        }
    }
    else /* *alignment != NULL */
    {
        page = (*alignment)->page;
        if ( align > outfile.code_sections->shdr->sh_addralign )
        {
            outfile.code_sections->shdr->sh_addralign = align;
        }
        delta = (((*alignment)->offset + align - 1) & ~(align - 1)) -
            (*alignment)->offset;
        outfile.code_sections->pages.offset += delta;
        ref_index = elf_ndxscn(outfile.code_sections->scn);
        elfcheck( ref_index != SHN_UNDEF );
        align_symbols( outfile.symbol_section, *alignment, delta,
                       ref_index );
        align_relocations( outfile.code_sections->relocations,
                           *alignment, delta );
        delta *= outfile.code_sections->shdr->sh_entsize;

        /* two consecutive alignments should take the larger alignment */
        if ( delta > page->delta )
        {
            page->delta = delta;
        }
    }

    return align;
}

unsigned long outfile_offset( void )
{
    if (outfile.code_sections)
    {
        return outfile.code_sections->pages.offset;
    }
    else
    {
        return 0;
    }
}

unsigned long outfile_section_index( void )
{
    Elf32_Half index;

    if (outfile.code_sections)
    {
        index = elf_ndxscn(outfile.code_sections->scn);
        elfcheck( index != SHN_UNDEF );
        return index;
    }
    else
    {
        return 0;
    }
}

/*
 * outfile_walk should only be called after all code has been
 * emitted. Sections can get seriously messed up otherwise.
 */
memory_space_t outfile_walk( unsigned long section_index,
                             unsigned long *offset,
                             unsigned long *code )
{
    SECTION **section, *selected;
    Elf32_Half current_index;
    unsigned char *data;

    section = &outfile.code_sections;
    while (*section)
    {
        current_index = elf_ndxscn((*section)->scn);
        elfcheck( current_index != SHN_UNDEF );
        if (section_index == current_index )
        {
            break;
        }
        section = &(*section)->next;
    }
    if (*section)
    {
        if (section != &outfile.code_sections)
        {
            /* remove found section from current spot in list */
            selected = remlist_section( section );
            inslist_section( selected );
        }
        else
        {
            selected = *section;
        }
    }
    else
    {
        /* section not found, probably an assembly error */
        if (offset)
        {
            *offset = 0;
        }
        if (code)
        {
            *code = 0;
        }
        return SECTION_NONE;
    }
    if (selected->walk.page == NULL)
    {
        selected->walk.page = page_next( &selected->pages );
        selected->walk.page_index = 0;
        selected->walk.offset = 0;
    }
    if (selected->walk.page_index >= selected->walk.page->size)
    {
        selected->walk.page = page_next( selected->walk.page );
        selected->walk.page_index = 0;
        selected->walk.offset += selected->walk.page->delta /
            selected->shdr->sh_entsize;
        
    }
    if (offset)
    {
        *offset = selected->walk.offset;
    }
    if (code)
    {
        *code = 0;
        data = selected->walk.page->data.code + 
            selected->walk.page_index;
        if (selected->space == SECTION_PROGRAM)
        {
            *code = ((unsigned long)*data) << 16;
            ++selected->walk.page_index;
            ++data;
        }
        *code |= (((unsigned long)*data) << 8) |
            (unsigned long)*(data+1);
        selected->walk.page_index += 2;
        ++selected->walk.offset;
    }
    return selected->space;
}

int outfile_next_section( unsigned long *start,
                          unsigned long *length,
                          const char **name,
                          int program )
{
    SECTION *found, *scan;
    Elf32_Shdr *shdr;

    found = NULL;
    scan = outfile.code_sections;
    while ( scan )
    {
        shdr = scan->shdr;
        if (shdr->sh_addr >= *start)
        {
            /* if we're looking for program and found program or
             * we're looking for data and found data */
            if (program == ((shdr->sh_flags & SHF_EXECINSTR) != 0))
            {
                if ( found )
                {
                    if ( shdr->sh_addr < found->shdr->sh_addr )
                    {
                        found = scan;
                    }
                }
                else
                {
                    found = scan;
                }
            }
        }
        scan = scan->next;
    }
    if ( found )
    {
        *start = found->shdr->sh_addr;
        *length = found->pages.offset;
        *name = found->name;
    }
    return found != NULL;
}

