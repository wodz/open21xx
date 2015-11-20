/*
 * dllist.h 
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
#ifndef _DLLIST_H
#define _DLLIST_H

typedef struct dllist_t
{
    struct dllist_t *next, *prev;
} dllist_t;

void dllist_init( dllist_t *item );

dllist_t *dllist_remove( dllist_t *item );

dllist_t *dllist_append( dllist_t *dllist, dllist_t *item );

dllist_t *dllist_prepend( dllist_t *dllist, dllist_t *item );

void *dllist_join( dllist_t *dllist, dllist_t *join_list );

#define dllist_isempty(dllist) ((dllist)->next == (dllist))
#define dllist_prev(dllist) ((dllist)->prev)
#define dllist_last(dllist) (dllist_prev(dllist))
#define dllist_next(dllist) ((dllist)->next)
#define dllist_first(dllist) (dllist_next(dllist))


#endif
