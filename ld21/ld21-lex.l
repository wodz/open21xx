/*
 * ld21-lex.l 
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
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <stdarg.h>
#include <elf.h>
#include "dspmem.h"
#include "namelist.h"
#include "macro.h"
#include "ld21-grammar.h"
#include "ld21-lex.h"

typedef struct keyword_t
{
    char name[12];
    int token;
} keyword_t;

static int last_state = 0; /* INITIAL */
static int line_no = 1;
static const char *ldf_file;
int error_count;

%}

%option nounput

%x C_COMMENT

/*
 * This works as a non-exclusive start state because the character set
 * matched in this state is a superset of the character set matched in
 * the initial state. So if this start state is active, it will match
 * anything matched in the initial state
 */
%x PARSE_FREE_NAME

symbol [_a-zA-Z][_a-zA-Z0-9]*
unsymbol [^_a-zA-Z]
white_space [ \t]+

%%

{white_space} ;
\r?\n            { ++line_no; }
"//".*        ;  /* CPP comment */
"/*"          {
        last_state = YYSTATE;
        BEGIN C_COMMENT;
    }

    /**/
    /*
     * review the characters allowed in a file name. Also locate and expand
     * macro names in line.
     */
<PARSE_FREE_NAME>[-0-9A-Za-z/.#_]+ {
        yylval.name = yytext;
        return FREE_NAME;
    }

    /* returns either FREE_NAME, FILE_LIST, or UNDEFINED_MACRO */
<PARSE_FREE_NAME>\${symbol} {
        yylval.name_list = find_macro( yytext + 1 );
        return FILE_LIST;
    }

<PARSE_FREE_NAME>{white_space} ;

<PARSE_FREE_NAME>\r?\n { ++line_no; }

<PARSE_FREE_NAME>. {
        return yytext[0];
    }

ABSOLUTE            { return ABSOLUTE; }
ADDR                { return ADDR; }
ALGORITHM           { return ALGORITHM; }
ALIGN               { return ALIGN; }
ALL_FIT             { return ALL_FIT; }
ARCHITECTURE        { return ARCHITECTURE; }
BEST_FIT            { return BEST_FIT; }
BOOT                { return BOOT; }
COMAP               { return COMAP; }
DEFINED             { return DEFINED; }
DM                  { return DM; }
DYNAMIC             { return DYNAMIC; }
ELIMINATE           { return ELIMINATE; }
ELIMINATE_SECTIONS  { return ELIMINATE_SECTIONS; }
END                 { return END; }
FALSE               { return LDF_FALSE; }
FILL                { return FILL; }
FIRST_FIT           { return FIRST_FIT; }
INCLUDE             { return INCLUDE; }
INPUT_SECTION_ALIGN { return INPUT_SECTION_ALIGN; }
INPUT_SECTIONS      { return INPUT_SECTIONS; }
KEEP                { return KEEP; }
LENGTH              { return LENGTH; }
LINK_AGAINST        { return LINK_AGAINST; }
MAP                 { return MAP; }
MEMORY              { return MEMORY; }
MEMORY_SIZEOF       { return MEMORY_SIZEOF; }
MPMEMORY            { return MPMEMORY; }
NUMBER_OF_OVERLAYS  { return NUMBER_OF_OVERLAYS; }
OUTPUT              { return OUTPUT; }
OVERLAY_GROUP       { return OVERLAY_GROUP; }
OVERLAY_ID          { return OVERLAY_ID; }
OVERLAY_INPUT       { return OVERLAY_INPUT; }
OVERLAY_OUTPUT      { return OVERLAY_OUTPUT; }
PACKING             { return PACKING; }
PAGE_INPUT          { return PAGE_INPUT; }
PAGE_OUTPUT         { return PAGE_OUTPUT; }
PLIT                { return PLIT; }
PLIT_DATA_OVERLAY_IDS { return PLIT_DATA_OVERLAY_IDS; }
PLIT_SYMBOL_ADDRESS { return PLIT_SYMBOL_ADDRESS; }
PLIT_SYMBOL_OVERLAYID { return PLIT_SYMBOL_OVERLAYID; }
PM                  { return PM; }
PORT                { return PORT; }
PROCESSOR           { return PROCESSOR; }
RAM                 { return RAM; }
RESOLVE             { return RESOLVE; }
RESOLVE_LOCALLY     { return RESOLVE_LOCALLY; }
ROM                 { return ROM; }
SEARCH_DIR          { return SEARCH_DIR; }
SECTIONS            { return SECTIONS; }
SHARED_MEMORY       { return SHARED_MEMORY; }
SHT_NOBITS          { return NOBITS; }
SIZE                { return SIZE; }
SIZEOF              { return SIZEOF; }
START               { return START; }
WIDTH               { return WIDTH; }
TRUE                { return LDF_TRUE; }
TYPE                { return TYPE; }
VERBOSE             { return VERBOSE; }
XREF                { return XREF; }

\${symbol}/[ \t\n\r]*=  {
        yylval.name = yytext + 1; return MACRO_DEFINE; 
    }

{symbol}    { yylval.name = yytext; return NAME; }
  
[0-9]+ { yylval.number = strtol(yytext, NULL, 10); return NUMBER; }

0[xX][0-9a-fA-F]+ { yylval.number = strtol(yytext, NULL, 16); return NUMBER; }

[Bb]#[01]+ { yylval.number = strtol(yytext+2, NULL, 2); return NUMBER; }


.      { return yytext[0]; }
 
<C_COMMENT>[^*\r\n]* ;
<C_COMMENT>"*"+[^*/\r\n]* ;
<C_COMMENT>\r?\n   { ++line_no; }
<C_COMMENT>"*"+"/" { BEGIN last_state; }

%%

void yyerror(const char *fmt, ...)
{

    va_list args;

    ++error_count;
    va_start( args, fmt );
    if ( ldf_file )
    {
        fprintf( stderr, "%s:%d: ", ldf_file, line_no );
    }
    else
    {
        fprintf( stderr, ":: " );
    }
    vfprintf( stderr, fmt, args );
    fprintf( stderr, "\n" );
    va_end( args );
}

void lex_init( const char *name )
{
    ldf_file = name;
}

int yywrap()
{
    return 1;
}

void begin_free_names(void)
{
    BEGIN PARSE_FREE_NAME;
}

void end_free_names(void)
{
    BEGIN INITIAL;
}





