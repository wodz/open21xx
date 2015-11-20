/*
 * listing.h 
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
#ifndef LISTING_H
#define LISTING_H

#include "defs.h"

/*
 * flags for listing_control_*()
 */
typedef enum
{
    LISTING_FLAG_LIST = 0x01,
    LISTING_FLAG_LISTDATA = 0x02,
    LISTING_FLAG_LISTDATFILE = 0x04
} listing_flag_t;

/*
 * emitted data type
 */
typedef enum
{
    LIST_ITEM_CODE,
    LIST_ITEM_DATA,
    LIST_ITEM_DATFILE,
    /* the following are used internally by listing.c */
    LIST_NEW_PAGE,
    LIST_ERROR,
    LIST_DEFAULT_TAB,
    LIST_LOCAL_TAB,
    LIST_LIST_FLAGS
} list_item_t;

extern int error_count;

extern void listing_init( const char *input, const char *output,
                   int verify );

extern void listing_term( void );

extern void listing_left_margin( int margin );

extern void listing_new_page( void );

extern void listing_page_length( int length );

extern void listing_page_width( int width );

extern void listing_control_set( unsigned int );

extern void listing_control_reset( unsigned int );

extern void listing_left_margin( int margin );

extern void listing_set_deftab( int width );

extern void listing_set_tab( int width );

extern void yyerror( const char *, ... );

extern void yywarn( const char *, ... );

extern unsigned long parse_quoted( char **charp, char *endp );

extern void emit( unsigned long code, int init_24, list_item_t );

extern unsigned long emit_var_string( const string_t *string, int init_24 );

extern void emit_bss( int size );

#endif
