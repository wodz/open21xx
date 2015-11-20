/*
 * dllist.c 
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

#include "dllist.h"

void dllist_init( dllist_t *item )
{
    item->next = item->prev = item;
}

dllist_t *dllist_remove( dllist_t *item )
{
    item->prev->next = item->next;
    item->next->prev = item->prev;
    return item;
}

dllist_t *dllist_append( dllist_t *dllist, dllist_t *item )
{
    item->next = dllist->next;
    item->prev = dllist;
    dllist->next->prev = item;
    dllist->next = item;
    return item;
}

dllist_t *dllist_prepend( dllist_t *dllist, dllist_t *item )
{
    item->next = dllist;
    item->prev = dllist->prev;
    dllist->prev->next = item;
    dllist->prev = item;
    return item;
}

void *dllist_join( dllist_t *dllist, dllist_t *join_list )
{
    join_list->next->prev = dllist->prev;
    join_list->prev->next = dllist;
    dllist->prev->next = join_list->next;
    dllist->prev = join_list->prev;
    return dllist;
}

