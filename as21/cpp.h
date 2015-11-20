/*
 * cpp.h
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
#if !defined(_CPP_H)
#define _CPP_H

typedef enum
{
    CPP_EXPAND_ALL,
    CPP_EXPAND_NONE,
    CPP_EXPAND_NEXT_OFF
} expand_t;

extern void cpp_push_condition( int condition );

extern void cpp_elif_condition( int condition );

extern void cpp_else_condition( void );

extern void cpp_pop_condition( void );

extern int cpp_assembly_on();

extern int cpp_read_buf( char *buf, int max_size );

extern int cpp_push_file( const char *name, int return_end );

extern void cpp_pop_file(void);

extern int cpp_wrap();

extern void cpp_pop_file(void);

extern int cpp_current_line(void);

extern int cpp_current_location( const char **file_name, int *line,
                                 int *column );

extern void cpp_change_location( int line, const char *file_name );

extern void cpp_add_column( int last_length );

extern int cpp_push_macro( const char *name );

extern void cpp_pop_macro( void );

extern void cpp_expand( expand_t expand );

extern void cpp_line_add( int count );

extern int cpp_preprocess( void );

extern void cpp_init_collection(void);

extern void cpp_collect_token( const char *text, int length );

extern char *cpp_collect_tokens( int *length );

extern int cpp_tokens_length(void);

extern int cpp_collect_argument(void);

extern void cpp_collect_macro(void);

extern void cpp_terminate(void);

extern int cpp_cmd_line_macro( char *text );

extern void cpp_queue_include_dir( const char *dir_name );

extern void cpp_push_include_file( const char *include_name, int local );

extern void cpp_init_pass( void );

#endif




