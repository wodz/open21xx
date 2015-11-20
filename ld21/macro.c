/*
 * macro.c 
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
#include "macro.h"

typedef struct MACRO_LIST
{
    struct MACRO_LIST *next;
    const char *name;
    NAME_LIST *names;
}MACRO_LIST;

static MACRO_LIST *macro_list;

void macro_list_init( void )
{
    macro_list = NULL;
}

void macro_list_destroy( void )
{
    MACRO_LIST *next;
    
    while (macro_list)
    {
        next = macro_list->next;
        free( macro_list );
        macro_list = next;
    }
}

void add_macro( const char *name, NAME_LIST *files )
{
    MACRO_LIST *macro, **list;
    int compare;

    macro = (MACRO_LIST *)malloc(sizeof(MACRO_LIST));
    assert(macro);
    if (macro)
    {
        macro->name = name;
        macro->next = NULL;
        macro->names = files;
        list = &macro_list;
        while (*list)
        {
            compare = strcasecmp( name, (*list)->name );
            if (compare == 0)
            {
                /* replace the definition of an existing macro */
                name_list_destroy( (*list)->names );
                (*list)->names = files;
                break;
            }
            else if (compare < 0)
            {
                /* inserting new name before the entry */
                macro->next = *list;
                *list = macro;
                break;
            }
            list = &(*list)->next;
        }
        if (!*list)
        {
            *list = macro;
        }
    }
}

const NAME_LIST *find_macro( const char *name )
{
    MACRO_LIST *list;
    int compare;

    list = macro_list;
    while (list)
    {
        compare = strcasecmp( name, list->name );
        if (compare == 0)
        {
            return list->names;
        }
        else if (compare < 0)
        {
            break;
        }
        list = list->next;
    }    
    return NULL;
}

void macro_list_print( void )
{
    MACRO_LIST *list;
    NAME_LIST *fnames;

    list = macro_list;
    while (list)
    {
        printf( "%s: ", list->name );
        fnames = list->names;
        while (fnames)
        {
            printf( "%s%s", fnames->name, fnames->next ? "," : "\n" );
            fnames = fnames->next;
        }
        printf( "\n" );
        list = list->next;
    }
}

