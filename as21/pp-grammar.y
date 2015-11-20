/*
 * pp-grammar.y
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

/* because the preprocessor is built with the "-p pp" option yylex and
 * yyerror are redefined to pplex and pperror respectively but this
 * grammar should still call yylex and yyerror */

#ifdef yylex
#undef yylex
#endif

#ifdef yyerror
#undef yyerror
#endif

#include <stdlib.h>
#include <ctype.h>
#include "defs.h"
#include "as21-lex.h"
#include "symbol.h"
#include "listing.h"
#include "cpp.h"

%}

/******************************************************************************
 * Synchronize union members and tokens with the preprocessor. Any tokens
 * appearing in both parsers need to appear first and be in the same order.
 *****************************************************************************/
%union {
    int integer;
    string_t string;
}

/* Any tokens shared with any other grammars must be below this common
 * and above the END SHARED TOKENS comment and must appear in the same
 * order in all grammars (assemblers and preprocessor). A grammar only
 * has to duplicate up to any shared tokens that it uses so tokens
 * used by alot of grammars should appear earlier in the list. */
%token <integer> NUMBER
%token <string>   NAME
%token <string> DQ_STRING
%token <integer> LOGICAL_OR LOGICAL_AND COMPARE_EQUAL COMPARE_NOT_EQUAL
%token <integer> GREATER_THAN_EQUAL LESS_THAN_EQUAL SHIFT_LEFT SHIFT_RIGHT
%token <integer> SQ_CHAR
%token <string> SQ_STRING
%token DIRECTIVE_DOT PLUS_EQUAL

/* END SHARED TOKENS */

%token PPDEFINE PPDEFINE_PARAM PPELIF PPELSE PPENDIF PPERROR PPIF
%token PPIFDEF PPIFNDEF PPINCLUDE PPLINE PPUNDEF PPWARNING
%token PPDEFINED PPCONCAT PPSTRINGIZE PPMACRO_LABEL
%token <string> ARGUMENTED_MACRO

%type <integer> expression logical_or_expression logical_and_expression
%type <integer> or_expression xor_expression and_expression
%type <integer> equality_expression relational_expression
%type <integer> shift_expression additive_expression
%type <integer> multiplicative_expression unary_expression
%type <integer> primary_expression

%%

ppstatement:
      PPDEFINE { cpp_init_collection(); } macro_name
        {
            cpp_collect_macro();
            return 0;
        }
    | PPELIF expression
        {
            cpp_elif_condition( $2 );
        }
    | PPELSE
        {
            cpp_else_condition();
        }
    | PPENDIF
        {
            cpp_pop_condition();
        }
    | PPERROR 
        {
            char *error_msg;

            cpp_init_collection();
            error_msg = cpp_collect_tokens( NULL );
            yyerror( error_msg );
            return 0;
        }
    | PPIF expression
        {
            cpp_push_condition( $2 );
        }
    | PPIFDEF NAME
        {
            cpp_push_condition( find_macro( $2.string ) != NULL );
        }
    | PPIFNDEF NAME
        {
            cpp_push_condition( find_macro( $2.string ) == NULL );
        }
    | PPINCLUDE
        {
            char *file_name;
            int length;
            
            cpp_init_collection();
            file_name = cpp_collect_tokens( &length );
            --length;
            if ( file_name[0] != '\"' &&
                 file_name[0] != '<' &&
                 file_name[length-1] != file_name[0])
            {
                yyerror( "Unrecognized include statement" );
            }
            else
            {
                file_name[length-1] = '\0';
                cpp_push_include_file( file_name + 1,
                                       *file_name == '\"');
            }
            return 0;
        }
    | PPLINE line_number
    | PPUNDEF NAME
        {
            undefine_macro( $2.string );
        }
    | PPWARNING
        {
            char *warning_msg;

            cpp_init_collection();
            warning_msg = cpp_collect_tokens( NULL );
            yywarn( warning_msg );
            return 0;
        }
    | /* empty */
    | error
        {
            return 0;
        }
    ;

macro_name:
      NAME
        {
            cpp_collect_token( $1.string, $1.length );
        }
    | ARGUMENTED_MACRO 
        {
            cpp_collect_token( $1.string, $1.length );
        }
      '(' macro_parameters ')'
    ;

macro_parameters:
      macro_parameters ',' NAME
        {
            cpp_collect_token( $3.string, $3.length );
        }
    | NAME
        {
            cpp_collect_token( $1.string, $1.length );
        }
    ;

line_number:
      /* empty */
        {
            cpp_change_location( 0, NULL );
        }
    | NUMBER 
        {
            cpp_change_location( $1, NULL );
        }
    | NUMBER DQ_STRING
        {
            const char *file_name = $2.string + 1;
                
            $2.string[$2.length-1] = '\0';
            cpp_change_location( $1, file_name );
        }
    ;       

expression:
      logical_or_expression
        {
            $$ = $1;
        }
    ;

logical_or_expression:
      logical_and_expression
        {
            $$ = $1;
        }
    | logical_or_expression LOGICAL_OR logical_and_expression
        {
            $$ = $1 || $3;
        }
    ;

logical_and_expression:
      or_expression
        {
            $$ = $1;
        }
    | logical_and_expression LOGICAL_AND or_expression
        {
            $$ = $1 && $3;
        }
    ;

or_expression:
      xor_expression
        {
            $$ = $1;
        }
    | or_expression '|' xor_expression
        {
            $$ = $1 | $3;
        }
    ;

xor_expression:
      and_expression
        {
            $$ = $1;
        }
    | xor_expression '^' and_expression
        {
            $$ = $1 ^ $3;
        }
    ;

and_expression:
      equality_expression
        {
            $$ = $1;
        }
    | and_expression '&' equality_expression
        {
            $$ = $1 & $3;
        }
    ;

equality_expression:
      relational_expression
        {
            $$ = $1;
        }
    | equality_expression COMPARE_EQUAL relational_expression
        {
            $$ = $1 == $3;
        }
    | equality_expression COMPARE_NOT_EQUAL relational_expression
        {
            $$ = $1 != $3;
        }
    ;

relational_expression:
      shift_expression
        {
            $$ = $1;
        }
    | relational_expression '>' shift_expression
        {
            $$ = $1 > $3;
        }
    | relational_expression '<' shift_expression
        {
            $$ = $1 < $3;
        }
    | relational_expression LESS_THAN_EQUAL shift_expression
        {
            $$ = $1 <= $3;
        }
    | relational_expression GREATER_THAN_EQUAL shift_expression
        {
            $$ = $1 >= $3;
        }
    ;

shift_expression:
      additive_expression
        {
            $$ = $1;
        }
    | shift_expression SHIFT_LEFT additive_expression
        {
            $$ = $1 << $3;
        }
    | shift_expression SHIFT_RIGHT additive_expression
        {
            $$ = $1 >> $3;
        }
    ;

additive_expression:
      multiplicative_expression
        {
            $$ = $1;
        }
    | additive_expression '+' multiplicative_expression
        {
            $$ = $1 + $3;
        }
    | additive_expression '-' multiplicative_expression
        {
            $$ = $1 - $3;
        }
    ;

multiplicative_expression:
      unary_expression
        {
            $$ = $1;
        }
    | multiplicative_expression '*' unary_expression
        {
            $$ = $1 * $3;
        }
    | multiplicative_expression '/' unary_expression
        {
            $$ = $1 / $3;
        }
    | multiplicative_expression '%' unary_expression
        {
            $$ = $1 % $3;
        }
    ;

unary_expression:
      primary_expression
        {
            $$ = $1;
        }
    | '-' unary_expression
        {
            $$ = -$2;
        }
    | '+' unary_expression
        {
            $$ = $2;
        }
    | '~' unary_expression
        {
            $$ = ~$2;
        }
    | '!' unary_expression
        {
            $$ = !$2;
        }
    ;

primary_expression:
      NUMBER
        {
            $$ = $1;
        }
    | SQ_CHAR
        {
            $$ = $1;
        }
    | '(' expression ')'
        {
            $$ = $2;
        }
    | PPDEFINED '(' NAME
        {
            if ( find_macro( $3.string ) )
                $<integer>$ = 1;
            else
                $<integer>$ = 0;
        }
      ')'
        {
            $$ = $<integer>4;
        }
    | PPDEFINED NAME
        {
            if ( find_macro( $2.string ) )
                $$ = 1;
            else
                $$ = 0;
        }
    ;

%%


