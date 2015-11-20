/*
 * elfdump.c 
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
#include <string.h>
#include <fcntl.h>
#include <elf.h>
#include <libelf.h>

#include "adielf.h"
#include "defs.h"

static Elf *elf;

void dump_ehdr(Elf32_Ehdr *ehdr)
{
    switch (ehdr->e_machine)
    {
        case EM_ADSP218X:
            printf( "ADSP218X " );
            break;
        default:
            printf( "Machine: %2d ", ehdr->e_machine );
            break;
    }
    switch (ehdr->e_type)
    {
        case ET_REL:
            printf( "Relocatable " );
            break;
        case ET_EXEC:
            printf( "Executable " );
            break;
        default:
            printf( "File Type: %#-4x ", ehdr->e_type );
            break;
    }
    switch (ehdr->e_ident[EI_CLASS])
    {
        case ELFCLASS32:
            printf( "32 bit " );
            break;
        case ELFCLASS64:
            printf( "64 bit " );
            break;
        case ELFCLASSNONE:
        default:
            printf( "Class: %2d ", ehdr->e_ident[EI_CLASS] );
            break;
    }
    switch (ehdr->e_ident[EI_DATA])
    {
        case ELFDATA2LSB:
            printf( "LSB " );
            break;
        case ELFDATA2MSB:
            printf( "MSB " );
            break;
        case ELFDATANONE:
        default:
            printf( "Encoding: %2d ",
                    ehdr->e_ident[EI_DATA] );
            break;
    }
    printf( "\n" );
    printf( "   Entry: %8X   EHdr Size: %3X  StrNdx: %d EFlags: %X\n",
            ehdr->e_entry, ehdr->e_ehsize, ehdr->e_shstrndx, ehdr->e_flags );
    printf( "PHdr Off: %8X   PHdr Size: %3X   PHdrs: %d\n",
            ehdr->e_phoff, ehdr->e_phentsize, ehdr->e_phnum );
    printf( "SHdr Off: %8X   SHdr Size: %3X   SHdrs: %d\n",
            ehdr->e_shoff, ehdr->e_shentsize, ehdr->e_shnum );
}

void dump_phdr( Elf32_Phdr *phdr, int count )
{
    for ( ; count > 0 ; --count )
    {
        printf( " Type: %8X    Off: %8X  VAddr: %8x  PAddr: %8x\n",
                phdr->p_type, phdr->p_offset, phdr->p_vaddr,
                phdr->p_paddr );
        printf( "FSize: %8X  MemSz: %8X  Flags: %8x  Align: %8x\n",
                phdr->p_filesz, phdr->p_memsz,
                phdr->p_flags, phdr->p_align );
        if (count > 1)
        {
            printf( "\n" );
        }
        ++phdr;
    }
}

void dump_shdr( Elf32_Shdr *shdr, const char *strings )
{
    switch( shdr->sh_type)
    {
        case SHT_NULL:
            printf( "null     " );
            break;
        case SHT_PROGBITS:
            printf( "progbits " );
            break;
        case SHT_SYMTAB:
            printf( "symtab   " );
            break;
        case SHT_STRTAB:
            printf( "strtab   " );
            break;
        case SHT_NOBITS:
            printf( "nobits   " );
            break;
        case SHT_RELA:
            printf( "rela     " );
            break;
        default:
            printf( "%9d", shdr->sh_type );
            break;
    }
    /*       flg  add  off  sz   lnk inf algn esz */
    printf( "%08X %08X %08X %08X %4d %4d %04X %3d %s\n",
            shdr->sh_flags, shdr->sh_addr, shdr->sh_offset,
            shdr->sh_size, shdr->sh_link, shdr->sh_info,
            shdr->sh_addralign, shdr->sh_entsize,
            strings+shdr->sh_name );
}

void dump_progbits( const unsigned char *code, int count,
                    int executable )
{
    int dumped;
    unsigned long code_word;
    int per_line;

    per_line = 0;
    for ( dumped = 0 ; dumped < count ; )
    {
        code_word = 0;
        if (executable)
        {
            code_word |= ((unsigned long)*code++) << 16;
        }
        code_word |= ((unsigned long)*code++) << 8;
        code_word |= *code++;
        if (executable)
        {
            printf( "%06lX ", code_word );
            dumped += 3;
        }
        else
        {
            printf( "%04lX ", code_word );
            dumped += 2;
        }
        ++per_line;
        if (per_line == 8 || dumped == count )
        {
            printf( "\n" );
            per_line = 0;
        }
    }
}

void dump_strtab( const char *strings, int length )
{
    int size;
    int line_length;

    line_length = 0;
    while ( length > 0 )
    { 
        size = strlen( strings ) + 1;
        if ( line_length + size + 3 > 80)
        { 
            printf( "\n" );
            line_length = 0;
        }
        printf( "\"%s\" ", strings );
        length -= size;
        strings += size;
        line_length += size + 3;
    }
    if ( line_length > 0 )
        printf( "\n" );
}

void dump_symtab( const Elf32_Sym *symbols, int count, const char *strings )
{
    static const char * const bind_type[] =
    {
        "LOCAL",
        "GLOBAL",
        "WEAK"
    };
    char bind_no[8];
    const char *binding;
    int bind_index;

    printf( "   Value     Size Binding  Type Ndx Name\n" );
    while (count > 0)
    { 
        bind_index = ELF32_ST_BIND(symbols->st_info);
        if (bind_index > STB_WEAK)
        {
            snprintf( bind_no, sizeof(bind_no), 
                      "%-6d", bind_index );
            binding = bind_no;
        }
        else
        {
            binding = bind_type[bind_index];
        }
            
        printf( "%8X %8X  %6s %4X %4d %s\n",
                symbols->st_value, symbols->st_size, binding,
                ELF32_ST_TYPE(symbols->st_info),
                symbols->st_shndx, strings + symbols->st_name );
        ++symbols;
        --count;
    }
}

void dump_rel( Elf32_Rela *relocations, int count,
               Elf_Data *symtab_data, Elf_Data *strtab_data )
{
    Elf32_Sym *symbols, *rel_symbol;
    const char *strings, *rel_to_name;
    int symbol_index;
    int symbol_count;
    int strings_size;

    symbols = (Elf32_Sym *)symtab_data->d_buf;
    strings = (const char *)strtab_data->d_buf;
    symbol_count = symtab_data->d_size/sizeof(*symbols);
    strings_size = strtab_data->d_size;
    while (count > 0)
    {
        rel_to_name = NULL;
        symbol_index = ELF32_R_SYM(relocations->r_info);
        if (symbol_index < symbol_count)
        {
            rel_symbol = symbols + symbol_index;
            if (rel_symbol->st_name < strings_size)
            {
                rel_to_name = strings + rel_symbol->st_name;
            }
            else
            {
                printf( "Illegal string offset: %d out of %d\n",
                        rel_symbol->st_name, strings_size );
            }
        }
        else
        {
            printf( "Illegal symbol index: %d out of %d\n",
                    symbol_index, symbol_count );
        }
        if (rel_to_name)
        {
            printf( "%08X %2x %08X %s\n", relocations->r_offset,
                    ELF32_R_TYPE(relocations->r_info),
                    relocations->r_addend, rel_to_name );
        }
        else
        {
            printf( "%08X %2x %08X %3d\n", relocations->r_offset,
                    ELF32_R_TYPE(relocations->r_info),
                    relocations->r_addend,
                    ELF32_R_SYM(relocations->r_info) );
        }
        ++relocations;
        --count;
    }
}

int get_rel_data( Elf32_Shdr *shdr, Elf_Data **symtab_data,
                  Elf_Data **strtab_data )
{
    Elf_Scn *symtab_section, *strtab_section;
    Elf32_Shdr *symtab_shdr;
    char *errlocation;

    symtab_section = elf_getscn(elf, shdr->sh_link);
    if (symtab_section)
    {
        *symtab_data = elf_getdata(symtab_section, NULL);
        if ( *symtab_data )
        {
            symtab_shdr = elf32_getshdr(symtab_section);
            if (symtab_shdr)
            {
                strtab_section =
                    elf_getscn(elf, symtab_shdr->sh_link);
                if (strtab_section)
                {
                    *strtab_data = elf_getdata(strtab_section, NULL);
                    if ( *strtab_data )
                    {
                        return TRUE;
                    }
                    else
                        errlocation = "strtab_data";
                }
                else
                    errlocation = "strtab_section";
            }
            else
                errlocation = "symtab_shdr";
        }
        else
            errlocation = "symtab_data";
    }
    else
        errlocation = "symtab_section";
    fprintf( stderr, "get_rel_data: %s - %s\n",
             errlocation, elf_errmsg(-1) );
    return FALSE;
}

void dump_section( Elf_Scn *section, const char *strings )
{
    Elf32_Shdr *shdr;
    Elf_Data *data;
    Elf_Data *symtab_data, *strtab_data;
    char *errlocation;

    shdr = elf32_getshdr(section);
    if ( shdr )
    {
        dump_shdr( shdr, strings );

        data = elf_getdata(section, NULL);
        if ( data )
        {
            switch( shdr->sh_type )
            {
                case SHT_PROGBITS:
                    dump_progbits( data->d_buf, data->d_size,
                                (shdr->sh_flags & SHF_EXECINSTR) != 0);
                    break;
                case SHT_SYMTAB:
                    dump_symtab( data->d_buf, data->d_size/sizeof(Elf32_Sym),
                                strings );
                    break;
                case SHT_STRTAB:
                    dump_strtab( data->d_buf, data->d_size );
                    break;
                case SHT_NOBITS:
                    break;
                case SHT_RELA:
                    if ( get_rel_data( shdr, &symtab_data, &strtab_data ) )
                    {
                        dump_rel( data->d_buf,
                                  data->d_size/sizeof(Elf32_Rela),
                                  symtab_data, strtab_data );
                    }
                    break;
                default:
                    printf( "Unknown section type: %d\n", shdr->sh_type );
                    break;
            }
            printf( "\n" );
            return;
        }
        else
            errlocation = "data";
    }
    else
        errlocation = "shdr";
    fprintf( stderr, "dump_section: %s - %s\n", errlocation,
             elf_errmsg(-1) );
}

char *get_string_data( Elf32_Ehdr *ehdr )
{
    Elf_Scn *string_section;
    char *errlocation;
    Elf_Data *string_data;

    if ( ehdr->e_shstrndx != SHN_UNDEF )
    {
        string_section = elf_getscn(elf, ehdr->e_shstrndx);
        if ( string_section )
        {
            string_data = elf_getdata(string_section, NULL);
            if (string_data)
            {
                return (char *)string_data->d_buf;
            }
            else
                errlocation = "string_data";
        }
        else
            errlocation = "string_section";
        fprintf( stderr, "get_string_data: %s - %s\n",
                errlocation, elf_errmsg(-1) );
    }
    return NULL;
}


int main( int argc, char **argv )
{
    int fd;
    Elf32_Ehdr *ehdr;
    Elf_Scn *scn;
    Elf_Scn *section;
    Elf32_Phdr *phdr;
    char *strings = NULL;
    int first_section;
    static const char mainerr[] = "main: %s - %s\n";
    int errno;

    if (argc > 0)
    {
        printf( "elfdump of file: %s\n", argv[1] );
        if ((fd = open(argv[1], O_RDONLY | O_BINARY)) != -1)
        {
            if (elf_version(EV_CURRENT) != EV_NONE)
            {
                elf = elf_begin(fd, ELF_C_READ, NULL);
                if (elf)
                {
                    const char *ident;
                    size_t length, i;

                    ehdr = elf32_getehdr(elf);
                    if (ehdr)
                    {
                        printf( "\n----Elf Header----\n" );
                        dump_ehdr( ehdr );
                        strings = get_string_data( ehdr );
                        phdr = elf32_getphdr(elf);
                        if (phdr)
                        {
                            printf( "\n----Program Header----\n" );
                            dump_phdr( phdr, ehdr->e_phnum );
                        }
                        section = NULL;
                        first_section = TRUE;
                        while ((section = elf_nextscn(elf, section)) != 0)
                        {
                            if (first_section)
                            {
                                printf("\n----Section Header Table----\n" );
                                printf( "type     flags    addr     offset"
                                        "   size     link info algn esz name\n" );
                                first_section = FALSE;
                            }
                            dump_section( section, strings );
                        }
                        errno = elf_errno();
                        if ( errno != 0 )
                        {
                            fprintf( stderr,
                                     "main: section -  %s\n",
                                     elf_errmsg(errno) );
                        }
                    }
                    else
                    {
                        fprintf( stderr, "ELF header not found: %s\n",
                                 elf_errmsg(-1) );
                    }
                    elf_end(elf);
                }
                else
                {
                    fprintf( stderr, "main: elf_begin - %s\n",
                             elf_errmsg(-1) );
                }
            }
            else
            {
                fprintf(stderr, "Elf library out of date\n" );
            }
            if (close( fd ) != 0)
                perror("Error closing file");
        }
        else
        {
            perror("Error opening file" );
        }
    }
    return 0;
}
