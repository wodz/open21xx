/*
 * namelist.c 
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
#include <assert.h>
#include "namelist.h"

void name_list_init( NAME_LIST_HDR *header )
{
    header->names = header->last = NULL;
}

void name_list_destroy( NAME_LIST *names )
{
    NAME_LIST *next;

    while(names)
    {
        next = names->next;
        free( names );
        names = next;
    }
}

void add_name( NAME_LIST_HDR *header, const char *name )
{
    NAME_LIST *name_list;

    name_list = (NAME_LIST *)malloc(sizeof(NAME_LIST) + strlen(name));
    assert(name_list);
    if (name_list)
    {
        strcpy(name_list->name, name);
        name_list->next = NULL;
        if (!header->names)
        {
            header->names = header->last = name_list;
        }
        else
        {
            header->last->next = name_list;
            header->last = name_list;
        }
    }
}

void copy_name_list( NAME_LIST_HDR *header, const NAME_LIST *list )
{
    while (list)
    {
        add_name( header, &list->name[0] );
        list = list->next;
    }
}

void add_name_list( NAME_LIST_HDR *to, NAME_LIST_HDR *from )
{
    if (!to->names)
    {
        to->last = from->last;
        to->names = from->names;
    }
    else
    {
        to->last->next = from->names;
        to->last = from->last;
    }
}

void name_list_print( NAME_LIST *names )
{
    while (names)
    {
        printf( " %s%s", names->name, names->next ? "," : "" );
        names = names->next;
    }
}

