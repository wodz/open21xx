/*
 * ld21-grammar.y
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

%{
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <assert.h>
#include <elf.h>
#include "../defs.h"
#include "../adielf.h"
#include "ld21-lex.h"
#include "dspmem.h"
#include "namelist.h"
#include "macro.h"
#include "execfile.h"

char version[] = "Open21xx Linker Version " VERSION_NUMBER;
typedef struct ARCHITECTURE_DEF
{
    const char *arch_name;
    Elf32_Half machine;
    int width[2];    /* indexed by MEMORY_SPACE - 1 */
}ARCHITECTURE_DEF;

extern int yyparse( void );

extern FILE *yyin;
static int link_files;

MEMORY_LIST global_memory, processor_memory, *current_memory;

NAME_LIST_HDR search_dir;
NAME_LIST_HDR build_fname_list;
NAME_LIST_HDR section_label_list;

static const ARCHITECTURE_DEF *architecture;
static int arch_by_command;
static int map_flags = 0;
static char *dup_name;

const ARCHITECTURE_DEF *find_architecture( const char *arch_name );

%}

%union {
    int number;
    char *name;
    MEMORY_LOCUS locus;
    MEMORY_SPACE memory_space;
    int bool;
    MEMORY_BLOCK *block;
    const NAME_LIST *name_list;
    int arch_type;
    Elf32_Word section_type;
}

%token <number> NUMBER
%token <name> NAME FREE_NAME MACRO_DEFINE
%token <name_list> FILE_LIST

%token ABSOLUTE ADDR ALGORITHM ALIGN ALL_FIT BEST_FIT BOOT COMAP
%token DEFINED DYNAMIC ELIMINATE ELIMINATE_SECTIONS LDF_FALSE FILL
%token FIRST_FIT INCLUDE INPUT_SECTION_ALIGN KEEP MAP MEMORY_SIZEOF
%token MPMEMORY NUMBER_OF_OVERLAYS OVERLAY_GROUP OVERLAY_ID OVERLAY_INPUT
%token OVERLAY_OUTPUT PACKING PAGE_INPUT PAGE_OUTPUT PLIT
%token PLIT_DATA_OVERLAY_IDS PLIT_SYMBOL_ADDRESS PLIT_SYMBOL_OVERLAYID
%token RESOLVE RESOLVE_LOCALLY SHARED_MEMORY NOBITS SIZE SIZEOF
%token LDF_TRUE VERBOSE XREF

%token MEMORY ARCHITECTURE PROCESSOR SEARCH_DIR LINK_AGAINST OUTPUT
%token INPUT_SECTIONS SECTIONS
%token TYPE START END LENGTH WIDTH PM DM PORT RAM ROM

%type <locus> memory_locus
%type <memory_space> memory_space
%type <bool> length_end
%type <name> name
%type <block> output_memory_segment
%type <section_type> section_type

%%

description:
      description description_element
      {
          assert( dup_name == NULL );
      }
    | description_element
      {
          assert( dup_name == NULL );
      }
    | error
      {
          if ( dup_name )
          {
              free( dup_name );
          }
      }
    ;

description_element:
      ARCHITECTURE '(' 
        {
            begin_free_names();
        }
      FREE_NAME
        {
            if (!arch_by_command)
            {
                architecture = find_architecture( $4 );
            }
            end_free_names();
        }
      ')'
    | SEARCH_DIR '('
        {
            begin_free_names();
            name_list_init( &build_fname_list );
        }
      dir_list
        {
            end_free_names();
        }
      ')'
        {
            add_name_list( &search_dir, &build_fname_list );
        }
    | memory_description
    | PROCESSOR NAME
        {
            if ( architecture == NULL )
            {
                yyerror( "PROCESSOR section with no architecture defined" );
                YYABORT;
            }
            memory_list_init( &processor_memory );
            current_memory = &processor_memory;
        }
      '{' processor_description '}'
        {
            current_memory = &global_memory;
        }
    | MACRO_DEFINE
        {
            assert( dup_name == NULL );
            $1 = dup_name = strdup( $1 );
        }
      '='
        {
            begin_free_names();
            name_list_init( &build_fname_list );
        }
      file_list
        {
            end_free_names();
        }
      ';'
        {
            add_macro( $1, build_fname_list.names );
            free( $1 );
            dup_name = NULL;
        }
    | MAP '('
        {
            begin_free_names();
        }
      FREE_NAME
        {
            map_file( $4, map_flags );
            end_free_names();
        }
      ')'
    | XREF
        {
            map_flags |= MAP_GEN_XREF;
        }
    ;

processor_description:
      OUTPUT '(' 
        {
            begin_free_names();
            name_list_init( &build_fname_list );
        }
      fname_list
        {
            end_free_names();
        }
      ')'
        {
            if (!exec_open( build_fname_list.names,
                            architecture->machine,
                            architecture->width[0]/8,
                            architecture->width[1]/8))
            {
                YYABORT;
            }
            name_list_destroy( build_fname_list.names );
        }
      processor_memory
      SECTIONS '{' section_statement_list '}'
        {
            objects_link( );
            exec_close();
        }
    ;

processor_memory:
      memory_description
    | /* empty */
    ;
 
memory_description:
      MEMORY '{' memory_section_list '}'
        {
//            memory_list_print( *current_memory, FALSE );
        }
    ;

memory_section_list:
      memory_section_list memory_section
    | memory_section
    ;

memory_section:
      name '{'
          TYPE '(' memory_space memory_locus ')' 
          START '(' NUMBER ')'
          length_end '(' NUMBER ')'
          WIDTH '(' NUMBER ')'
      '}'
        {
            if (!architecture)
            {
                yyerror( "Memory section with no architecture defined" );
            }
            else if ($18 != architecture->width[$5 - 1])
            {
                yyerror("Memory width doesn't match architecture");
            }
            else
            {
                add_memory_block( current_memory,
                                  $1, $5, $6, $10,
                                  $12 ? $14 : ($10 + $14 - 1),
                                  $18);
            }
            free( $1 );
            dup_name = NULL;
        }
    ;

length_end:
      LENGTH  { $$ = 0; }
    | END     { $$ = 1; }
    ;

memory_space:
      PM  { $$ = PROGRAM_MEMORY; }
    | DM  { $$ = DATA_MEMORY; }
    ;

memory_locus:
      PORT  { $$ = PORT_LOCUS; }
    | RAM   { $$ = RAM_LOCUS; }
    | ROM   { $$ = ROM_LOCUS; }
    ;

section_statement_list:
      section_statement_list section_statement
    | section_statement
    ;

section_statement:
      name section_type '{' 
        {
            new_input_sections();
        }
      section_command_list '}' output_memory_segment
        {
            memorize($1, $2, $7);
            free( $1 );
            dup_name = NULL;
        }
    | expression ';'
        {
        }
    ;

section_type:
      NOBITS
      {
          $$ = SHT_NOBITS;
      }
    | /* empty */
      {
          $$ = SHT_PROGBITS;
      }
    ;

output_memory_segment:
      '>' NAME
        {
            $$ = find_memory_block( *current_memory, $2 );
            if (!$$ && current_memory == &processor_memory)
            {
                $$ = find_memory_block( global_memory, $2 );
            }
            if (!$$)
            {
                yyerror("No memory segment of the supplied name found");
            }
        }
    | /* empty */ { $$ = NULL; }
    ;

section_command_list:
      section_command_list section_command
    | section_command
    ;

section_command:
      INPUT_SECTIONS '(' 
        {
            new_file_list();
            begin_free_names();
            link_files = TRUE;
        }
      file_list
        {
            link_files = FALSE;
            end_free_names();
        } 
      '('
        {
            name_list_init( &section_label_list );
        }            
      input_label_list ')' ')'
        {
            add_object_sections( section_label_list.names);
            name_list_destroy( section_label_list.names );
        }
    | expression ';'
        {
        }
    ;

input_label_list:
      input_label_list ',' input_label
    | input_label
    ;

input_label:
      NAME      /* actually the name of a section */
        {
            add_name( &section_label_list, $1 );
        }
    ;

expression:
      '.' '=' '.' '+' NUMBER
        {
            yyerror( "Expressions are not supported yet" );
            YYABORT;
        }
    ;

dir_list:
      dir_list ';' fname_list
    | fname_list
    ;

file_list:
      file_list ',' fname_list
    | fname_list
    ;

fname_list:
      FREE_NAME
       {
           if (link_files)
           {
               add_one_object( $1 );
           }
           else
           {
               add_name( &build_fname_list, $1 );
           }
       }
    | FILE_LIST
       {
           if (link_files)
           {
               add_objects( $1 );
           }
           else
           {
               copy_name_list( &build_fname_list, $1 );
           }
       }
    ;

name:
      NAME
       {
           assert( dup_name == NULL );
           $$ = dup_name = strdup( $1 );
       }
    ;

%%

int main(int argc, char **argv)
{
    int option;
    char *open21xx_env;
    char *ldf_file = NULL;
    char *system_ldf = NULL;
    char *map_file_name = NULL;
#if YYDEBUG
    extern int yy_flex_debug;
    static char option_list[] = "d:D:Lo:T:m:vX";
#else
    static char option_list[] = "D:Lo:T:m:vX";
#endif

#if YYDEBUG
    yydebug = 0;
    yy_flex_debug = 0;
#endif

    arch_by_command = FALSE;
    architecture = NULL;
    macro_list_init();
    name_list_init( &search_dir );
    objects_init();
    error_count = 0;
    while ((option = getopt( argc, argv, option_list )) != -1)
    {
        switch (option)
        {
#if YYDEBUG
            case 'd':
                while (*optarg)
                {
                    switch (*optarg)
                    {
                        case 'y':
                            yydebug = 1;
                            break;
                        case 'l':
                            yy_flex_debug = 1;
                            break;
                        default:
                            fprintf( stderr, "Invalid debug option\n" );
                            exit( 1 );
                    }
                    ++optarg;
                }
                break;
#endif
            case 'D':     // architecture
                arch_by_command = TRUE;
                architecture = find_architecture( optarg );
                if ( architecture == NULL )
                {
                    exit( 1 );
                }
                break;
            case 'L':
                map_flags |= MAP_INCLUDE_LOCALS;
                break;
            case 'm':     // map file output
                map_file_name = optarg;
                break;
            case 'o':     // output file
                name_list_init( &build_fname_list );
                add_name( &build_fname_list, optarg );
                add_macro( "COMMAND_LINE_OUTPUT_FILE",
                           build_fname_list.names );
                break;
            case 'T':     // ldf input file
                if ( ldf_file != NULL )
                {
                    fprintf( stderr, "Multiple LDF files specified\n" );
                    exit( 1 );
                }
                ldf_file = optarg;
                break;
            case 'v':
                printf( "%s\n", version );
                exit(0);
            case 'X':
                map_flags |= MAP_GEN_XREF;
                break;
            case ':':
            case '?':
            default:
                exit(1);
                break;
        }
    }
    if ( map_file_name )
    {
        map_file( map_file_name, map_flags );
    }
    if (ldf_file == NULL)
    {
        if ( architecture == NULL )
        {
            fprintf( stderr,
                     "An LDF file or architecture must be specified.\n" );
            exit(1);
        }
        open21xx_env = getenv( "OPEN21XXDIR" );
        if ( open21xx_env == NULL )
        {
            fprintf( stderr,
                     "No environment available to look for LDF.\n" );
            exit( 1 );
        }
        system_ldf = (char *)malloc( strlen( open21xx_env ) +
                                     strlen( architecture->arch_name ) +
                                     6 );
        strcpy( system_ldf, open21xx_env );
        strcat( system_ldf, "/" );
        strcat( system_ldf, architecture->arch_name );
        strcat( system_ldf, ".ldf" );
        ldf_file = system_ldf;
    }
    yyin = fopen( ldf_file, "r" );
    if ( yyin == NULL )
    {
        fprintf( stderr,
                 "No LDF found matching the architecture.\n" );
        exit( 1 );
    }
    lex_init( ldf_file );
    name_list_init( &build_fname_list );
    while (optind < argc)
    {
        add_name( &build_fname_list, argv[optind] );
        ++optind;
    }
    add_macro( "COMMAND_LINE_OBJECTS",
               build_fname_list.names );
    memory_list_init( &global_memory );
    current_memory = &global_memory;
    link_files = FALSE;

    yyparse();

    memory_list_destroy( &global_memory );
    objects_destroy();
    name_list_destroy( search_dir.names );
    if ( system_ldf )
    {
        free( system_ldf );
    }
    macro_list_destroy();
    return error_count;
}


const ARCHITECTURE_DEF *find_architecture( const char *arch_name )
{
    static const ARCHITECTURE_DEF architectures[] =
    {
        { "ADSP-2181", EM_ADSP218X, { 24, 16} },
        { "ADSP-2183", EM_ADSP218X, { 24, 16} },
        { "ADSP-2184", EM_ADSP218X, { 24, 16} },
        { "ADSP-2185", EM_ADSP218X, { 24, 16} },
        { "ADSP-2186", EM_ADSP218X, { 24, 16} },
        { "ADSP-2187", EM_ADSP218X, { 24, 16} },
        { "ADSP-2188", EM_ADSP218X, { 24, 16} },
        { "ADSP-2189", EM_ADSP218X, { 24, 16} },
        { "ADSP-2191", EM_ADSP219X, { 24, 16} },
        { "ADSP-2195", EM_ADSP219X, { 24, 16} },
        { "ADSP-2196", EM_ADSP219X, { 24, 16} },
        { "ADSP-21990", EM_ADSP219X, { 24, 16} },
        { "ADSP-21991", EM_ADSP219X, { 24, 16} },
        { "ADSP-21992", EM_ADSP219X, { 24, 16} }
    };
    const ARCHITECTURE_DEF *device;
    int i;

    for (device = architectures, i = 0 ;
         i < sizearray(architectures) &&
             strcmp( arch_name, device->arch_name ) != 0 ;
         ++device, ++i)
        ;
    if (i >= sizearray(architectures))
    {
        yyerror("Architecture not found");
        device = NULL;
    }
    return device;
}





