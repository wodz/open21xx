/*
 * as21-lex.h 
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
#ifndef AS21_LEX_H
#define AS21_LEX_H

#include <stdio.h>

typedef enum
{
    LEX_INITIAL,
    LEX_PREPROC_TEXT,
    LEX_PREPROC_DIRECTIVE,
    LEX_MACRO_ARG_LIST,
    LEX_GOBBLE
} lex_state_t;

extern void lex_init( void );

extern int yylex( void );

extern void lex_state( lex_state_t state );

extern void *lex_scan_file( FILE *file );

/*
 * the string will be modified by this call
 */
extern void *lex_scan_string( char *string );

extern void lex_delete_buffer( void *buffer );

extern void lex_use_buffer( void *buffer );

extern void *lex_scan_buffer( char *text, int length );

extern void lex_push( int token );

#endif




