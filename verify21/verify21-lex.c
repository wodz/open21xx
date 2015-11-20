/*
 * verify21-lex.c 
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
#include <ctype.h>
#include "verify21-grammar.h"

#define MAX_LINE_LENGTH  (2048) // max characters in a line, oken or string

enum
{
    address_offset = 0,
    data_offset = 8,
    line_number_offset = 15,
    text_offset = 22
};

/* -------------------------- local variables ------------------------------- */

int verify_errors = 0;

static char yytext[MAX_LINE_LENGTH];
static int start_index = 0;
static int line_length = 0;
static int line_number = 0;

void yyerror( char *message )
{
    fprintf( stderr, "Error: %d: %s\n", line_number, message );
    ++verify_errors;
    if ( verify_errors > 10 )
    {
        exit(1);
    }
}

/*
 * This function should only be used for parsing the address and code fields
 * of an assembler output.
 */
int read_number( int offset, int base )
{
    char *number_end;
    int number;

    number = strtol( yytext+offset, &number_end, base );
    /* strtol skips leading space so  we must have at least one valid digit */
    if ( !isspace(*number_end) )
    {
        yyerror( "Invalid format on or after line" );
        exit( 1 );
    } 
    return number;
}

/* ------------------------- exported functions ----------------------------- */

int yylex(void)
{
    int token = 0;
    char *number_end, *scan;
    int line;
    static enum { find_header, header_found } parse_state;

    while ( token == 0 )
    {
        if ( start_index >= line_length )
        {
            if (fgets( yytext, sizeof( yytext ), stdin ) == NULL)
            {
                break;
            }
            start_index = address_offset;
            line_length = strlen( yytext );
            if (line_length > line_number_offset)
            {
                line_number = read_number( line_number_offset, 10 );
            }
        }
        if ( start_index == address_offset )
        {
            if ( isspace( yytext[start_index] ) )
            {
                start_index = line_length;
            }
            else
            {
                yylval.value = read_number( address_offset, 16 );
                token = ADDRESS;
                start_index = data_offset;
            } 
        }
        else if ( start_index == data_offset )
        {
            yylval.value = read_number( data_offset, 16 );
            token = ASSEMBLED_DATA;
            start_index = text_offset;
            parse_state = find_header;
        }
        else 
        {
            scan = yytext+start_index;
            switch ( parse_state )
            {
                case find_header:
                    for ( ; *scan != '\0' ; ++scan )
                    {
                        if (*scan == '/' && *(scan+1) == '/')
                        {
                            token = VERIFY_HEADER;
                            scan += 2;
                            parse_state = header_found;
                            break;
                        }
                    }
                    break;
                case header_found:
                    while ( *scan == ' ' || *scan == '\t' )
                    {
                        ++scan;
                    }
                    if ( isdigit(*scan) )
                    {
                        yylval.value = strtol( scan, &number_end, 0 );
                        scan = number_end;
                        token = NUMBER;
                    }
                    else if ( *scan == '<' &&
                              *(scan+1) == '<' )
                    {
                        token = LEFT_SHIFT;
                        scan += 2;
                    }
                    else if ( *scan == '&' &&
                              *(scan + 1) == '=' )
                    {
                        token = AND_EQUAL;
                        scan += 2;
                    }
                    else if ( *scan == '\'' )
                    {
                        ++scan;
                        if ( *scan == '\\' )
                        {
                            ++scan;
                            switch ( *scan )
                            {
                                case 'n':
                                    yylval.value = '\n';
                                    break;
                                case 't':
                                    yylval.value = '\t';
                                    break;
                                case 'v':
                                    yylval.value = '\v';
                                    break;
                                case 'b':
                                    yylval.value = '\b';
                                    break;
                                case 'r':
                                    yylval.value = '\r';
                                    break;
                                case 'f':
                                    yylval.value = '\f';
                                    break;
                                case 'a':
                                    yylval.value = '\a';
                                    break;
                                case '\\':
                                    yylval.value = '\\';
                                    break;
                                case '\?':
                                    yylval.value = '\?';
                                    break;
                                case '\'':
                                    yylval.value = '\'';
                                    break;
                                case '\"':
                                    yylval.value = '\"';
                                    break;
                                default:
                                    yylval.value = *scan;
                                    break;
                            }
                            ++scan;
                        }
                        else
                        {
                            yylval.value = *scan++;
                        }
                        token = NUMBER;
                        if ( *scan == '\'' )
                        {
                            ++scan;
                        }
                        else
                        {
                            yyerror( "Illegal character constant" );
                            scan = yytext + line_length - 1;
                        }
                    }
                    else
                    {
                        token = *scan;
                        ++scan;
                    }
                    break;
                default:
                    fprintf( stderr, "Invalid parse state %d\n", parse_state );
                    abort();
                    break;
            }
            start_index = scan - yytext;
        }
    }
    return token;
}


