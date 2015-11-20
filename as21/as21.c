/*
 * as21.c 
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

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include "../defs.h"
#include "../adielf.h"
#include "as21-lex.h"
#include "cpp.h"
#include "listing.h"
#include "symbol.h"
#include "cpp.h"
#include "grammar.h"

void assembler_init( const char *source_name,
                     const char *object_name,
                     const char *listing_name,
                     int verify )
{
    lex_init();
    listing_init( source_name, listing_name, verify );
    grammar_init( object_name );
}

void assembler_term( const char *object_name, int verify )
{
    check_symtab();
    listing_term();
#if 0
    if (!verify)
    {
        print_symtab();
    }
#endif
    grammar_term();
    if (error_count > 0)
    {
        remove(object_name);
    }
}

int main(int argc, char **argv)
{
    int yyparse(void);
    static char *usage =
        "Usage: as21 [-d [a][p][l][v]] [-Dname[=literal]] [-E <max errors>]\n"
        "            [-I <include dir>] [-l <listing file>] [-o <object file]\n"
        "            [-v] [-2 <processor>]\n";
    static const char include[] = "/include";
    int option;
    char *object_name;
    char *listing_name;
    char *processor_name;
    int verify;
    int fail = FALSE;
    char *sys_include;
    char *sys_dir;
    time_t now;
    struct tm *tm;
    char timebuf[32];
    int count;
    char *endp;
#if YYDEBUG
    extern int yy_flex_debug;
    extern int yydebug;
    extern int ppdebug;
#endif

    sys_include = NULL;
    sys_dir = getenv( "OPEN21XXDIR" );
    if ( sys_dir )
    {
        sys_include = (char *)malloc( strlen( sys_dir ) +
                                      strlen( include ) + 1 );
        if ( sys_include == NULL )
        {
            fprintf( stderr,
                     "Failed to allocate memory for system include\n" );
            abort();
        }
        strcpy( sys_include, sys_dir );
        strcat( sys_include, include );
    }

    for ( ; optind < argc ; ++optind )
    {
        cpp_init_pass();
        init_symtab();
        listing_name = NULL;
        processor_name = NULL;
        max_error_count = 15;
#if YYDEBUG
        yydebug = 0;
        ppdebug = 0;
        yy_flex_debug = 0;
#endif
        object_name = "a.out";
        verify = FALSE;
        if ( sys_include )
        {
            cpp_queue_include_dir( sys_include );
        }
        while ((option = getopt( argc, argv, "+l:o:d:I:D:E:v2:" )) != -1)
        {
            switch (option)
            {
                case 'l':
                    listing_name = optarg;
                    break;
                case 'I':
                    cpp_queue_include_dir( optarg );
                    break;
                case 'o':
                    object_name = optarg;
                    break;
                case 'D':
                    if ( !cpp_cmd_line_macro( optarg ) )
                    {
                        exit( 1 );
                    }
                    break;
                case 'd':
                    while (*optarg)
                    {
                        switch (*optarg)
                        {
#if YYDEBUG
                            case 'a':
                                yydebug = 1;
                                break;
                            case 'p':
                                ppdebug = 1;
                                break;
                            case 'l':
                                yy_flex_debug = 1;
                                break;
#endif
                            case 'v':
                                verify = TRUE;
                                break;
                            default:
                                fprintf( stderr, "Invalid debug option\n" );
                                exit( 1 );
                        }
                        ++optarg;
                    }
                    break;
                case 'E':
                    count = strtol( optarg, &endp, 10 );
                    if ( *endp == '\0' )
                    {
                        max_error_count = count;
                    }
                    break;
                case 'v':
                    printf( "%s\n", version );
                    exit(0);
                case '2':
                    if ( processor_name != NULL )
                    {
                        fprintf( stderr, "Multiple processor selections\n" );
                        exit(2);
                    }
                    processor_name = optarg;
                    break;
                case ':':
                case '?':
                default:
                    fprintf( stderr, usage );
                    break;
            }
        }
        if ( optind < argc )
        {
            if ( !select_processor( processor_name ) )
            {
                fprintf( stderr, "Unrecognized processor name\n" );
                exit(2);
            }
            if (!verify)
            {
                printf("Assembling: %s to %s\n", argv[optind], object_name );
            }
            now = time( NULL );
            tm = localtime( &now );
            strftime( timebuf, sizeof( timebuf ), "'%T'", tm );
            define_simple_macro( "__TIME__", timebuf );
            strftime( timebuf, sizeof( timebuf ), "'%b %d %Y'", tm );
            define_simple_macro( "__DATE__", timebuf );
            if (cpp_push_file( argv[optind], FALSE))
            {
                assembler_init( argv[optind], object_name, listing_name,
                                verify );
                yyparse();
                assembler_term( object_name, verify );
                cpp_pop_file();
                fail = fail || error_count > 0;
            }
        }
        else
        {
            fprintf( stderr, "Missing source file\n" );
        }
        empty_symtab();
    }
    cpp_terminate();
    return fail;
}
