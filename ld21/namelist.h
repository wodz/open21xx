/*
 * namelist.h 
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
#ifndef _NAMELIST_H
#define _NAMELIST_H

typedef struct NAME_LIST
{
    struct NAME_LIST *next;
    char name[1];
}NAME_LIST;

/*
 * NAME_LIST_HDR only exists while building the header and isn't
 * carried with the NAME_LIST itself. Thats why the assymetry in
 * name_list_init and name_list_destroy.
 */
typedef struct NAME_LIST_HDR
{
    NAME_LIST *names;
    NAME_LIST *last;
}NAME_LIST_HDR;

void name_list_init( NAME_LIST_HDR *header );
void name_list_destroy( NAME_LIST *names );
void add_name( NAME_LIST_HDR *header, const char *name );
void add_name_list( NAME_LIST_HDR *to, NAME_LIST_HDR *from );
void copy_name_list( NAME_LIST_HDR *header, const NAME_LIST *list );
void name_list_print( NAME_LIST *names );

#endif
