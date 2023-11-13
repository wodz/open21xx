/*
 * verify21-grammar.y 
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

#include "../defs.h"

#define MAX_VERIFY_LENGTH     (512)

extern int verify_errors;

static unsigned long location;
static unsigned long verify_data[MAX_VERIFY_LENGTH];
static int verify_length, verify_index;
static int recovering;
static char error_buf[128];

int yylex();
int yyerror(const char *);

%}

%union {
    int value;
    int bool;
}

%token LEFT_SHIFT RIGHT_SHIFT VERIFY_HEADER AND_EQUAL
%token <value> ADDRESS ASSEMBLED_DATA NUMBER 

%type <value> or_expression and_expression shift_expression
%type <value> primary_expression
%type <bool> verify_sequence;

%%

listing:
      listing listing_item
    | listing_item 
    ;

listing_item:
      ADDRESS ASSEMBLED_DATA verify_sequence
        {
            if ( recovering )
            {
                recovering = !$3;
                location = $1;
            }
            if ( !recovering )
            {
                if ( $1 != location )
                {
                    sprintf( error_buf,
                             "Address: expecting %x but got %x\n",
                             location, 
                             $1 );
                    yyerror( error_buf );
                    location = $1;  /* resync location */
                }
                if ( verify_index >= verify_length )
                {
                    sprintf( error_buf,
                             "Length: expecting %x but got %x\n",
                             verify_length, 
                             verify_index );
                    yyerror( error_buf );
                }
                else if ( $2 != verify_data[verify_index] )
                {
                    sprintf( error_buf,
                             "Content: expecting %x; got %x\n",
                             verify_data[verify_index], $2 );
                    yyerror( error_buf );
                }
                ++verify_index;
                ++location;
            }
        }
      /* error recovery */
    | error '\n'
        {
            yyclearin;
            recovering = TRUE;
            verify_length = verify_index = 0;
        }
    ;

verify_sequence:
      VERIFY_HEADER
        {
            if ( verify_index != verify_length )
            {
                yyerror( "Different amount of data then expected" );
            }
            verify_index = 0;
            verify_length = 0;
        }
      address_spec verify_list '\n'
        {
            $$ = TRUE;
        }
    | /* empty */
        {
            $$ = FALSE;
        }
    ;

verify_list:
      verify_list primary_expression
        {
            if ( verify_length < sizearray(verify_data) )
            {
                verify_data[verify_length++] = $2;
            }
            else
            {
                yyerror( "Maximum data block size exceeded" );
            }
        }
    | primary_expression
        {
            if ( verify_length < sizearray(verify_data) )
            {
                verify_data[verify_length++] = $1;
            }
            else
            {
                yyerror( "Maximum data block size exceeded" );
            }
        }
    ;

address_spec:
      AND_EQUAL primary_expression
        {
            location = (location + ($2 - 1)) & ~($2 - 1);
        }
    | '=' primary_expression
        {
            location = $2;
        }
    | /* empty */
    ;

or_expression:
      and_expression
        {
            $$ = $1;
        }
    | or_expression '|' and_expression
        {
            $$ = $1 | $3;
        }
    ;      

and_expression:
      shift_expression
        {
            $$ = $1;
        }
    | and_expression '&' shift_expression
        {
            $$ = $1 & $3;
        }
    ;

shift_expression:
      primary_expression
        {
            $$ = $1;
        }
    | shift_expression RIGHT_SHIFT primary_expression
        {
            $$ = $1 >> $3;
        }
    | shift_expression LEFT_SHIFT primary_expression
        {
            $$ = $1 << $3;
        }
    ;

primary_expression:
      NUMBER
        {
            $$ = $1;
        }
    | '(' or_expression ')'
        {
            $$ = $2;
        }
    ;

%%

int main( int argc, char **argv )
{
    static char *usage = 
        "Usage: verify21 [-D [v]]\n";
    int option;

    yydebug = 0;
    recovering = FALSE;
    while ((option = getopt( argc, argv, "D:" )) != -1)
    {
        switch (option)
        {
            case 'D':
                while (*optarg)
                {
                    switch (*optarg)
                    {
                        case 'v':
                            yydebug = 1;
                            break;
                        default:
                            fprintf( stderr, "Invalid debug option\n" );
                            break;
                    }
                    ++optarg;
                }
                break;
            case ':':
            case '?':
            default:
                fprintf( stderr, usage );
                break;
        }
    }

    yyparse();
    fprintf( stderr, "Errors found during verification: %d\n",
             verify_errors );
    return verify_errors;
}
