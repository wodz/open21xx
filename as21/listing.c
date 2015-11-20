/*
 * listing.c 
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
#include <stdarg.h>
#include <assert.h>
#include <string.h>
#include <time.h>
#include <limits.h>
#include <ctype.h>
#include "defs.h"
#include "cpp.h"
#include "outfile.h"
#include "listing.h"
#include "grammar.h"

#define MIN_COLUMN            (1)
#define MAX_COLUMN            (256)
#define MIN_PAGE_LENGTH       (10)
#define DEFAULT_PAGE_WIDTH    (72)
#define DEFAULT_LEFT_MARGIN   (0)
#define DEFAULT_PAGE_LENGTH   (INT_MAX)
#define LISTING_COLUMN        (21)
#define MIN_PRINTABLE         (LISTING_COLUMN + 10)
#define DEFAULT_TAB_WIDTH     (4)
#define DEFAULT_LISTING       (LISTING_FLAG_LIST)

typedef struct listing_t
{
    struct listing_t *next;
    list_item_t type;
    int line;
    union
    {
        struct
        {
            int emitted;  /* width, length, words emitted, etc. */
            int scn_index;
        }code;
        char *error;
        int tab_width;
        unsigned int list_flags;
    }value;
} listing_t;

int error_count;

static listing_t *listing, *end_listing, *errors, *end_errors;
static const char *listing_output_file, *listing_input_file;
static char buffer[1000];
static char print_buffer[sizeof(buffer)+MIN_PRINTABLE];
static char time_stamp[26];
static int page_number;
static int lines_on_page;
static int warn_count;
static int eof_found;
static int verify;
static int page_width;
static int page_length;
static int left_margin;
static int line_position;
static unsigned int list_flags;
static int default_tab;
static int local_tab;

static void listing_fprintf( FILE *outfile, const char *format, ... )
{
    va_list ap;
    const char *print;
    int tab_spaces;
    
    va_start( ap, format );
    vsnprintf( print_buffer, sizeof(print_buffer), format, ap );
    va_end( ap );

    print = print_buffer;
    while ( *print )
    {
        switch( *print )
        {
            case '\f':
                break;
            case '\n':
                line_position = 0;
                break;
            case '\t':
                assert( line_position >= LISTING_COLUMN );
                if ( line_position >= LISTING_COLUMN )
                {
                    tab_spaces = line_position - LISTING_COLUMN;
                    tab_spaces %= local_tab;
                    tab_spaces = local_tab - tab_spaces;
                    while ( tab_spaces && line_position < page_width )
                    {
                        fputc( ' ', outfile );
                        --tab_spaces;
                        ++line_position;
                    }
                    line_position += tab_spaces;
                }
                ++print;
                continue;
            default:
                if ( line_position == 0 )
                {
                    while ( line_position < left_margin )
                    {
                        fputc( ' ', outfile );
                        ++line_position;
                    }
                }
                else if ( line_position >= page_width )
                {
                    fputc( '\n', outfile );
                    line_position = 0;
                    while ( line_position < left_margin + LISTING_COLUMN )
                    {
                        fputc( ' ', outfile );
                        ++line_position;
                    }
                }
                ++line_position;
                break;
        }
        fputc( *print, outfile );
        ++print;
    }
}

static void throw_page( FILE *outfile )
{
    static const char *header_fmt =
        "%s\n%-20s %s Page %d\n";

    if ( !verify && lines_on_page >= page_length )
    {
        if (page_number != 0)
        {
            listing_fprintf( outfile, "\f");
        }
        ++(page_number);
        listing_fprintf( outfile, header_fmt,
                         version,
                         listing_input_file,
                         time_stamp, page_number );
        lines_on_page = 2;
    }
}

void listing_line( FILE *outfile, listing_t *scan,
                   int line_number, char *buffer )
{
    memory_space_t memory_space;
    unsigned long location, code;
    int list_data;
    char * format;

    /* outfile_walk must be called even if listing is off to maintain sync
     * with the object file */
    memory_space = outfile_walk( scan->value.code.scn_index,
                                 &location, &code );

    if ( (list_flags & LISTING_FLAG_LIST) == 0 )
    {
        return;
    }

    list_data =
        (scan->type != LIST_ITEM_DATA &&
         scan->type != LIST_ITEM_DATFILE) ||
         (list_flags & LISTING_FLAG_LISTDATA) != 0 ||
         (list_flags & LISTING_FLAG_LISTDATFILE) != 0;

    if (memory_space == SECTION_DATA ||
        memory_space == SECTION_PROGRAM)
    {
        if (memory_space == SECTION_DATA)
        {
            format = "%04lX      %04lX";
        }
        else
        {
            format = "%04lX    %06lX";
        }
        if (list_data)
        {
            listing_fprintf( outfile, format, location, code );
        }
        else if (buffer)
        {
            listing_fprintf( outfile, "              " );
        }
    }
    else
    {
        listing_fprintf( outfile, "              " );
        assert( buffer != NULL );
    }

    if ( buffer )
    {
        listing_fprintf( outfile, " %5d %s", line_number, buffer );
    }
    else
    {
        if (list_data)
        {
            listing_fprintf( outfile, "\n" );
        }
        else
        {
            --lines_on_page;
        }
    }
    ++lines_on_page;    
}

static listing_t *add_list_item( list_item_t type, int line )
{
    listing_t *new_item;

    new_item = (listing_t *)malloc( sizeof(listing_t) );
    if ( new_item == NULL )
    {
        fprintf( stderr, "Failed to allocate a new list item\n" );
        abort();
    }
    memset( new_item, 0, sizeof(*new_item) );
    new_item->type = type;
    new_item->line = line;
    if (type == LIST_ERROR)
    {
        if (errors == NULL)
        {
            errors = end_errors = new_item;
        }
        else
        {
            end_errors = end_errors->next = new_item;
        }
    }
    else
    {
        while (errors && errors->line < line)
        {
            if (listing == NULL)
            {
                listing = end_listing = errors;
            }
            else
            {
                end_listing = end_listing->next = errors;
            }
            errors = errors->next;
            end_listing->next = NULL;
            if (errors == NULL)
            {
                end_errors = NULL;
            }
        }
        if (listing == NULL)
        {
            listing = end_listing = new_item;
        }
        else
        {
            end_listing = end_listing->next = new_item;
        }
    }
    return new_item;
}

void listing_init( const char *source_name, const char *listing_name,
                   int generate_verify )
{
    page_width = DEFAULT_PAGE_WIDTH;
    page_length = DEFAULT_PAGE_LENGTH;
    left_margin = DEFAULT_LEFT_MARGIN;
    error_count = warn_count = 0;
    listing_input_file = source_name;
    listing_output_file = listing_name;
    listing = end_listing = NULL;
    errors = end_errors = NULL;
    eof_found = FALSE;
    list_flags = DEFAULT_LISTING;
    verify = generate_verify;
    if (!verify)
    {
        if (listing_output_file)
        {
            time_t now;

            now = time(0);
            strncpy( time_stamp, ctime( &now ), sizeof(time_stamp)-1 );
            /* force string termination and remove trailing \n */
            time_stamp[sizeof(time_stamp)-1] = '\0';
            time_stamp[strlen(time_stamp)-1] = '\0';
        }
    }
}

void listing_term( void )
{
    static const char *line_fmt = "               %5d %s";
    static const char *result_message =
        "\nFile %s: %d errors, %d warnings\n";
    listing_t *save;
    FILE *infile, *outfile;
    listing_t *scan;
    int line_number = 0;
    int i;
    int length;

    if (verify || listing_output_file)
    {
        if (errors)
        {
            if (listing == NULL)
            {
                listing = errors;
                end_listing = end_errors;
            }
            else
            {
                end_listing->next = errors;
                end_listing = end_errors;
            }
            errors = end_errors = NULL;
        }
        if (listing_output_file)
        {
            outfile = fopen( listing_output_file, "w" );
            if (outfile == NULL)
                fprintf( stderr, "Failed to open listing file %s\n",
                         listing_output_file );
        }
        else
        {
            outfile = stdout;
        }
        infile = fopen( listing_input_file, "r" );
        if (infile == NULL)
            fprintf( stderr, "Failed to open source file %s\n",
                     listing_input_file );
        if (outfile && infile)
        {   
            scan = listing;
            page_number = 0;
            line_position = 0;
            default_tab = local_tab = DEFAULT_TAB_WIDTH;
            list_flags = DEFAULT_LISTING;
            if (verify)
            {
                page_length = INT_MAX;
                page_width = INT_MAX;
                left_margin = DEFAULT_LEFT_MARGIN;
                lines_on_page = 0;
            }
            else
            {
                lines_on_page = page_length;
                if ( page_width - left_margin < MIN_PRINTABLE )
                {
                    page_width = DEFAULT_PAGE_WIDTH;
                    left_margin = DEFAULT_LEFT_MARGIN;
                    fprintf( stderr, "Warning: "
                             "Printable area too small, using defaults\n" );
                }
            }
            while ( fgets( buffer, sizeof(buffer), infile ) != NULL )
            {
                ++line_number;
                length = strlen( buffer );
                if ( buffer[length-1] != '\n' && length < sizeof(buffer))
                {
                    buffer[length] = '\n';
                    ++length;
                    buffer[length] = '\0';
                }
                while (scan && scan->type == LIST_ERROR)
                {
                    throw_page( outfile );
                    listing_fprintf( outfile, "%s", scan->value.error );
                    ++lines_on_page;
                    scan = scan->next;
                }
                throw_page( outfile );
                if ( scan && line_number == scan->line )
                {
                    if ( scan->type == LIST_ITEM_CODE ||
                         scan->type == LIST_ITEM_DATA ||
                         scan->type == LIST_ITEM_DATFILE )
                    {
                        listing_line( outfile, scan, line_number, buffer );
                        for ( i = 0 ; i < scan->value.code.emitted - 1 ; ++i )
                        {
                            throw_page( outfile );
                            listing_line( outfile, scan, line_number, NULL );
                        }
                    }
                    else
                    {
                        switch (scan->type)
                        {
                            case LIST_NEW_PAGE:
                                lines_on_page = page_length;
                                throw_page( outfile );
                                break;
                            case LIST_DEFAULT_TAB:
                                default_tab = scan->value.tab_width;
                                if ( default_tab == 0 )
                                {
                                    default_tab = DEFAULT_TAB_WIDTH;
                                }
                                break;
                            case LIST_LOCAL_TAB:
                                local_tab = scan->value.tab_width;
                                if ( local_tab == 0 )
                                {
                                    local_tab = default_tab;
                                }
                                break;
                            case LIST_LIST_FLAGS:
                                list_flags = scan->value.list_flags;
                                break;
                            default:
                                break;
                        }
                        if ( (list_flags & LISTING_FLAG_LIST) != 0 )
                        {
                            listing_fprintf( outfile, line_fmt, line_number,
                                             buffer );
                            ++lines_on_page;
                        }
                    }
                    scan = scan->next;
                }
                else
                {
                    if ( (list_flags & LISTING_FLAG_LIST) != 0 )
                    {
                        listing_fprintf( outfile, line_fmt, line_number,
                                         buffer );
                        ++lines_on_page;
                    }
                }
            }
            while (scan && scan->type == LIST_ERROR )
            {
                throw_page( outfile );
                listing_fprintf( outfile, "%s", scan->value.error );
                ++lines_on_page;
                scan = scan->next;
            }
            assert( scan == NULL );
            if (!verify)
            {
                listing_fprintf( outfile, result_message,
                                 listing_input_file, error_count,
                                 warn_count );
            }
        }
        if (infile)
            fclose( infile );
        if (outfile && outfile != stdout)
            fclose( outfile );
    }
    if (!verify)
    {
        fprintf( stderr, result_message,
                 listing_input_file, error_count, warn_count );
    }
    while (listing)
    {
        save = listing->next;
        if (listing->type == LIST_ERROR && listing->value.error)
        {
            free( listing->value.error );
        }
        free( listing );
        listing = save;
    }
}

void listing_left_margin( int new_left_margin )
{
    if (!verify && listing_output_file)
    {
        if ( new_left_margin < MIN_COLUMN ||
             new_left_margin > MAX_COLUMN )
        {
            yyerror( "Left margin limits exceeded" );
        }
        else
        {
            left_margin = new_left_margin;
        }
    }
}

void listing_new_page( void )
{
    if (!verify && listing_output_file)
    {
        add_list_item( LIST_NEW_PAGE, cpp_current_line() );
    }
}

void listing_page_length( int new_page_length )
{
    if (!verify && listing_output_file)
    {
        if ( new_page_length == 0 )
        {
            page_length = INT_MAX;
        }
        else if ( new_page_length < MIN_PAGE_LENGTH )
        {
            yyerror( "Page length is too short. Using default" );
            page_length = MIN_PAGE_LENGTH;
        }
        else
        {
            page_length = new_page_length;
        }
    }
}

void listing_page_width( int new_page_width )
{
    if (!verify && listing_output_file)
    {
        if ( new_page_width < MIN_COLUMN ||
             new_page_width > MAX_COLUMN )
        {
            yyerror( "Page width limits exceeded" );
        }
        else
        {
            page_width = new_page_width;
        }
    }
}

void listing_set_deftab( int width )
{
    listing_t *deftab;

    if (!verify && listing_output_file)
    {
        deftab = add_list_item( LIST_DEFAULT_TAB,
                                cpp_current_line() );
        deftab->value.tab_width = width;
    }
}

void listing_set_tab( int width )
{
    listing_t *loctab;

    if (!verify && listing_output_file)
    {
        loctab = add_list_item( LIST_LOCAL_TAB,
                                cpp_current_line() );
        loctab->value.tab_width = width;
    }
}

void listing_control_set(unsigned int bit)
{
    listing_t *list_control;

    if (verify || listing_output_file)
    {
        list_flags |= bit;
        list_control = add_list_item( LIST_LIST_FLAGS,
                                      cpp_current_line() );
        list_control->value.list_flags = list_flags;
    }
}

void listing_control_reset(unsigned int bit)
{
    listing_t *list_control;

    if (verify || listing_output_file)
    {
        list_flags &= ~bit;
        list_control = add_list_item( LIST_LIST_FLAGS,
                                      cpp_current_line() );
        list_control->value.list_flags = list_flags;
    }
}

void yyerror(const char *fmt, ... )
{
    const char *file_name;
    int line;
    int column;
    va_list args;

    if ( cpp_current_location( &file_name, &line, &column ) )
    {
        sprintf( buffer, "%s:%d:%d: %s\n",
                 file_name, line, column, fmt );
    }
    else if (!eof_found)
    {
        eof_found = TRUE;
        sprintf( buffer, "Unexpected end of file: %s\n",
                fmt );
    }
    else
    {
        return;
    }
    va_start( args, fmt );
    vfprintf( stderr, buffer, args );
    va_end( args );
    if (!verify && listing_output_file)
    {
        listing_t *item;

        item = add_list_item( LIST_ERROR, line );
        item->value.error = strdup( buffer );
    }
    ++error_count;
}

void yywarn(const char *fmt, ... )
{
    const char *file_name;
    int line;
    int column;
    va_list args;

    if ( cpp_current_location( &file_name, &line, &column ) )
    {
        sprintf( buffer, "%s:%d:%d: warning: %s\n",
                 file_name, line, column, fmt);
    }
    else
    {
        sprintf( buffer, "Unexpected end of file: %s\n",
                 fmt );
    }
    va_start( args, fmt );
    fprintf( stderr, buffer, args );
    va_end( args );
    if (!verify && listing_output_file)
    {
        listing_t *item;

        item = add_list_item( LIST_ERROR, line );
        item->value.error = strdup( buffer );
    }
    ++warn_count;
}

void emit( unsigned long code, int init_24, list_item_t item )
{
    memory_space_t memory_space;
    int line;
    unsigned long sign;
    int valid;

    memory_space = outfile_memory_space();
    if (memory_space == SECTION_NONE)
    {
        yyerror("No section defined");
    }
    if (memory_space == SECTION_PROGRAM && !init_24)
    {
        code <<= 8;
    }
    valid = TRUE;
    if (memory_space == SECTION_PROGRAM)
    {
        sign = code & 0xff000000;
        valid = sign == 0 || sign == 0xff000000;
    }
    else if (memory_space == SECTION_DATA)
    {
        sign = code & 0xffff0000;
        valid = sign == 0 || sign == 0xffff0000;
    }
    if (!valid)
    {
        fprintf( stderr, "CODE %lx\n", code );
        yyerror( "Word size exceeded" );
    }

    if ( verify || listing_output_file )
    {
        line = cpp_current_line();
        if ( listing == NULL ||
             end_listing->type != item ||
             end_listing->line != line )
        {
            add_list_item( item, line );
            end_listing->value.code.scn_index = outfile_section_index();
        }
        ++end_listing->value.code.emitted;
    }
    outfile_emit( code );
}

unsigned long parse_quoted( char **charp, char *endp )
{
    char *cp;
    int code;
    int i;
    unsigned long xdig;

    cp = *charp;
    if ( *cp == '\\' )
    {
        ++cp;
        if ( cp < endp )
        {
            switch ( *cp )
            {
                case 'a':
                    code = '\a';
                    break;
                case 'b':
                    code = '\b';
                    break;
                case 'f':
                    code = '\f';
                    break;
                case 'n':
                    code = '\n';
                    break;
                case 'r':
                    code = '\r';
                    break;
                case 't':
                    code = '\t';
                    break;
                case 'v':
                    code = '\v';
                    break;
                case '\\':
                    code = '\\';
                    break;
                case '\?':
                    code = '\?';
                    break;
                case '\'':
                    code = '\'';
                    break;
                case '\"':
                    code = '\"';
                    break;
                case 'x':
                    ++cp;
                    code = 0;
                    i = 0;
                    while ( cp < endp && isxdigit( *cp ) )
                    {
                        xdig = toupper(*cp) - '0';
                        if ( xdig > 9 )
                        {
                            xdig = xdig - ('A' - ('9' + 1));
                        }
                        code = (code << 4) | xdig;
                        ++cp;
                        ++i;
                    }
                    if ( i == 0 )
                    {
                        yyerror( "Expecting a hexidecimal digit" );
                    }
                    --cp;
                    break;
                /* this case also takes care of '\0' */
                default:
                    code = 0;
                    for ( i = 0 ;
                          cp < endp && i < 3 && isdigit(*cp) && *cp < '8' ;
                          ++i )
                    {
                        code = code << 3 | (*cp - '0');
                        ++cp;
                    }
                    if ( i == 0 )
                    {
                        yyerror( "Expecting an octal digit" );
                    }
                    --cp;
                    break;
            }
        }
        else
        {
            yyerror( "Expecting an escape sequence" );
        }
    }
    else
    {
        code = *cp;
    }
    *charp = cp + 1;
    return code;
}

unsigned long emit_var_string( const string_t *string, int init_24 )
{
    char *charp = string->string + 1;
    char *endp = charp + string->length - 1;
    unsigned long emit_length;
    unsigned long code;

    if ( *(endp - 1) == '\'' )
    {
        --endp;
    }
    emit_length = 0;
    while ( charp < endp )
    {
        code = parse_quoted( &charp, endp );
        emit( code, init_24, LIST_ITEM_DATA );
        ++emit_length;
    }
    return emit_length;
}

void emit_bss( int size )
{
    int line;
    int emitted;

    emitted = outfile_emit_bss( size );
    if ( emitted )
    {
        if ( verify || listing_output_file )
        {
            line = cpp_current_line();
            if ( listing == NULL ||
                 end_listing->type != LIST_ITEM_DATA ||
                 end_listing->line != line )
            {
                add_list_item( LIST_ITEM_DATA, line );
                end_listing->value.code.scn_index = outfile_section_index();
            }
            end_listing->value.code.emitted += emitted;
        }    
    }
}

