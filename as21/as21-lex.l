/*
 * as21-lex.l
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include "symbol.h"
#include "expression.h"
#include "keyword.h"
#include "listing.h"
#include "as21-lex.h"
#include "bbtree.h"
#include "defs.h"
#include "cpp.h"
#include "pp-grammar.h"
#include "as21-grammar.h"
#include "as219x-grammar.h"

#define YY_INPUT(buf,result,max_size) result=cpp_read_buf(buf,max_size);

#define MACRO_ARG              (257)

static int push_token = '\0';

/* YACC has a one token look ahead. If you need to tolerate more lookahead
 * increase the number of name_buffer elements accordingly. */ 
static char name_buffer[2][256];
static int which_name;

static string_t lex_string( const char *text, int length )
{
    string_t string;

    string.string = name_buffer[which_name];
    if ( yyleng > sizearray(name_buffer[which_name]) - 1 )
    {
        strncpy( string.string, text,
                sizearray(name_buffer[which_name]) - 1 );
        string.string[sizearray(name_buffer[which_name]) - 1] = '\0';
        yywarn( "Truncating name %s to %d characters", text,
                sizearray(name_buffer[which_name]) - 1 );
        string.length = sizearray(name_buffer[which_name]) - 1;
    }
    else
    {
        strcpy( string.string, text );
        string.length = length;
    }
    which_name = (which_name + 1) % sizearray(name_buffer);
    return string;
}

%}

%option nounput

 /* The only difference between PROPROCESS and PREPROC_TEXT is that
  * PREPROC_TEXT includes white space. */
%s PREPROC_DIRECTIVE PREPROCESS PREPROC_TEXT
%s PREPROCESS_IF
%x PREPROC_MACRO_NAME GOBBLE MACRO_ARG_LIST

digits [A-Za-z0-9]
symbol [A-Za-z_][A-Za-z_0-9]*
preproc ^[ \t]*\#[ \t]*

%%
    {
        int token;

        if ( push_token )
        {
            token = push_token;
            push_token = 0;
            return token;
        }
    }

<GOBBLE>{preproc} {
        cpp_add_column( yyleng );
        cpp_preprocess();
    }

<GOBBLE>[^ \t#\n]* ;  /* throw out anything not a preprocessor command */
<GOBBLE>\n+ cpp_line_add( yyleng );
<GOBBLE>[ \t]+ ;
<GOBBLE>[#]+ ;

<PREPROC_DIRECTIVE>define {
        cpp_add_column( yyleng );
        if ( cpp_assembly_on() )
        {
            BEGIN PREPROC_MACRO_NAME;
            cpp_expand( CPP_EXPAND_NONE );
            return PPDEFINE;
        }
        else
        {
            BEGIN GOBBLE;
            return 0;
        }
    }

<PREPROC_DIRECTIVE>elif {
        cpp_add_column( yyleng );
        BEGIN PREPROCESS_IF;
        return PPELIF;
    }

<PREPROC_DIRECTIVE>else {
        cpp_add_column( yyleng );
        BEGIN PREPROCESS;
        return PPELSE;
    }

<PREPROC_DIRECTIVE>endif {
        cpp_add_column( yyleng );
        BEGIN PREPROCESS;
        return PPENDIF;
    }

<PREPROC_DIRECTIVE>error {
        cpp_add_column( yyleng );
        if ( cpp_assembly_on() )
        {
            BEGIN PREPROC_TEXT;
            return PPERROR;
        }
        else
        {
            BEGIN GOBBLE;
            return 0;
        }
    }

<PREPROC_DIRECTIVE>if {
        cpp_add_column( yyleng );
        BEGIN PREPROCESS_IF;
        return PPIF;
    }

<PREPROC_DIRECTIVE>ifdef {
        cpp_add_column( yyleng );
        cpp_expand( CPP_EXPAND_NONE );
        BEGIN PREPROCESS;
        return PPIFDEF;
    }

<PREPROC_DIRECTIVE>ifndef {
        cpp_add_column( yyleng );
        cpp_expand( CPP_EXPAND_NONE );
        BEGIN PREPROCESS;
        return PPIFNDEF;
    }

<PREPROC_DIRECTIVE>include {
        cpp_add_column( yyleng );
        if ( cpp_assembly_on() )
        {
            BEGIN PREPROCESS;
            return PPINCLUDE;
        }
        else
        {
            BEGIN GOBBLE;
            return 0;
        }
    }

<PREPROC_DIRECTIVE>line {
        cpp_add_column( yyleng );
        if ( cpp_assembly_on() )
        {
            BEGIN PREPROCESS;
            return PPLINE;
        }
        else
        {
            BEGIN GOBBLE;
            return 0;
        }
    }

<PREPROC_DIRECTIVE>undef {
        cpp_add_column( yyleng );
        if ( cpp_assembly_on() )
        {
            cpp_expand( CPP_EXPAND_NONE );
            BEGIN PREPROCESS;
            return PPUNDEF;
        }
        else
        {
            BEGIN GOBBLE;
            return 0;
        }
    }

<PREPROC_DIRECTIVE>warning {
        cpp_add_column( yyleng );
        if ( cpp_assembly_on() )
        {
            BEGIN PREPROC_TEXT;
            return PPWARNING;
        }
        else
        {
            BEGIN GOBBLE;
            return 0;
        }
    }

<PREPROC_DIRECTIVE>\n {
        /* line_number incremented on return from ppparse() */
        if ( cpp_assembly_on() )
        {
            BEGIN INITIAL;
        }
        else
        {
            BEGIN GOBBLE;
        }
        return 0;
    }

<PREPROCESS_IF>defined {
        cpp_add_column( yyleng );
        cpp_expand( CPP_EXPAND_NEXT_OFF );
        return PPDEFINED;
    }

<PREPROC_MACRO_NAME>[ \t]* {  /* toss out any white space */
        cpp_add_column( yyleng );
    }

<PREPROC_MACRO_NAME>{symbol}/\( {
        cpp_add_column( yyleng );
        BEGIN PREPROCESS;     /* to parse the parameter list */
        yylval.string = lex_string( yytext, yyleng );
        pplval.string = yylval.string;
        return ARGUMENTED_MACRO;
    }

<PREPROC_MACRO_NAME>{symbol} {
        cpp_add_column( yyleng );
        BEGIN PREPROCESS;     /* to parse the parameter list */
        yylval.string = lex_string( yytext, yyleng );
        pplval.string = yylval.string;
        return NAME;
    }

<PREPROC_MACRO_NAME>. {
        cpp_add_column( yyleng );
        BEGIN PREPROCESS;
        yyless(0);
    }

<PREPROC_TEXT>[ \t]*##[ \t]* {
        cpp_add_column( yyleng );
        return PPCONCAT;
    }

<PREPROC_TEXT>#[ \t]* {
        cpp_add_column( yyleng );
        return PPSTRINGIZE;
    }

<PREPROC_TEXT>{symbol}\? {
        cpp_add_column( yyleng );
        return PPMACRO_LABEL;
    }

<MACRO_ARG_LIST>[ \f\n\r\t\v]+ {
        cpp_add_column( yyleng );
        yytext[0] = ' ';
        yyleng = 1;
        return ' ';
    }

<MACRO_ARG_LIST>[^ \f\n\r\t\v(),]+ {
        cpp_add_column( yyleng );
        return MACRO_ARG;
    }

<MACRO_ARG_LIST>. {
        cpp_add_column( yyleng );
        return yytext[0];
    }

[ \t]+   {
        cpp_add_column( yyleng );
        if ( YYSTATE == PREPROC_TEXT )
        {
            yytext[0] = ' ';
            yytext[1] = '\0';
            yyleng = 1;
            return ' ';
        }
    }

^[ \t]*\.[ \t]* {
        cpp_add_column( yyleng );
        return DIRECTIVE_DOT;
    }

{preproc} {
        cpp_add_column( yyleng );
        if ( !cpp_preprocess() )
        {
            return '#';
        }
    }

\'[^'\n]*['\n] {
        if ( yytext[yyleng-2] == '\\' )
        {
            /* continuation lines are already removed so
             * must be an escaped single quote */
            yyless(yyleng-1);
            yymore();
        }
        else
        {
            char *charp;
            char *endp;

            cpp_add_column( yyleng );
            charp = yytext + 1;
            endp = yytext + yyleng - 1;
            if ( *endp == '\n' )
            {
                yyerror( "Unterminated string" );
                yyless(yyleng-1);
            }
            if ( charp == endp )
            {
                yyerror( "Empty string" );
                yylval.integer = 0;
                return SQ_CHAR;
            }
            else
            {
                yylval.integer = parse_quoted( &charp, endp );
                if ( charp == endp )
                {
                    return SQ_CHAR;
                }
                else
                {
                    yylval.string = lex_string( yytext, yyleng );
                    return SQ_STRING;
                }
            }
        }
    }

\"[^"\n]*["\n] {
        if ( yytext[yyleng-2] == '\\' )
        {
            /* continuation lines are already removed so
             * must be an escaped double quote */
            yyless(yyleng-1);
            yymore();
        }
        else
        {
            cpp_add_column( yyleng );
            if ( yytext[yyleng-1] == '\n' )
            {
                yyerror( "Unterminated string" );
                yyless(yyleng-1);
            }
            yylval.string = lex_string( yytext, yyleng );
            pplval.string = yylval.string;
            return DQ_STRING;
        }
    }

{symbol} {
        cpp_add_column( yyleng );
        if ( !cpp_push_macro( yytext ) )
        {
            int keyword_token;

            keyword_token = find_keyword( yytext );
            if ( keyword_token )
            {
                return keyword_token;
            }
            yylval.string = lex_string( yytext, yyleng );
            pplval.string = yylval.string;
            return NAME;
        }
    }

([0-9]|[bB]#){digits}*   {
        char *endptr;

        cpp_add_column( yyleng );
        /* Lexer has already verified the # */
        if ( toupper(yytext[0]) == 'B' )
        {
            /* convert binary representation */
            yylval.integer = strtoul( yytext + 2, &endptr, 2);
        }
        else
        {
            /* convert octal, decimal, hex representation */
            yylval.integer = strtoul( yytext, &endptr, 0);
        }
        if (*endptr != '\0')
        {
            yyerror( "Invalid number: %s", yytext );
        }
        
        pplval.integer = yylval.integer;
        return NUMBER;
    }

"||" {
        cpp_add_column( yyleng );
        return LOGICAL_OR;
    }

"&&" {
        cpp_add_column( yyleng );
        return LOGICAL_AND;
    }

"<<" {
        cpp_add_column( yyleng );
        return SHIFT_LEFT;
    }

">>" {
        cpp_add_column( yyleng );
        return SHIFT_RIGHT;
    }

"==" {
        cpp_add_column( yyleng );
        return COMPARE_EQUAL;
    }

"!=" {
        cpp_add_column( yyleng );
        return COMPARE_NOT_EQUAL;
    }

"<=" {
        cpp_add_column( yyleng );
        return LESS_THAN_EQUAL;
    }

">=" {
        cpp_add_column( yyleng );
        return GREATER_THAN_EQUAL;
    }

"+=" {
        cpp_add_column( yyleng );
        return PLUS_EQUAL;
    }

\n   {
        if ( YYSTATE == PREPROCESS ||
             YYSTATE == PREPROC_TEXT ||
             YYSTATE == PREPROCESS_IF )
        {
            /* line number will be incremented on preprocessing done */
            BEGIN INITIAL;
            return 0;
        }
        cpp_line_add( 1 );
    }

.        {
        cpp_add_column( yyleng );
        return yytext[0];
    }

%%

int yywrap()
{
    return cpp_wrap();
}

void lex_state( lex_state_t state )
{
    int map_states[] =
    {
        INITIAL,
        PREPROC_TEXT,
        PREPROC_DIRECTIVE,
        MACRO_ARG_LIST,
        GOBBLE
    };

    assert( state <= LEX_GOBBLE );
    BEGIN map_states[state];
}

void *lex_scan_file( FILE *file )
{
    YY_BUFFER_STATE buffer;

    buffer = yy_create_buffer( file, YY_BUF_SIZE );
    yy_switch_to_buffer( buffer );
    return buffer;
}

void *lex_scan_string( char *string )
{
    return yy_scan_string( string );
}

void lex_delete_buffer( void *buffer )
{
    yy_delete_buffer( buffer );
}

void lex_use_buffer( void *buffer )
{
    yy_switch_to_buffer( buffer );
}

void *lex_scan_buffer( char *text, int length )
{
    return yy_scan_buffer( text, length );
}

void lex_push( int token )
{
    push_token = token;
}

void lex_init( void )
{
    push_token = '\0';
    which_name = 0;
}

