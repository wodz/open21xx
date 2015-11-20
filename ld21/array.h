/*
 * array.c 
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
/*
 * arrays are growable arrays of elements of fixed size.
 * like a normal array but they're most efficient if you
 * access the elements sequentially.
 */

#ifndef ARRAY_H
#define ARRAY_H

typedef struct array_page_t
{
    struct array_page_t *next;
} array_page_t;

typedef struct array_index_t
{
    struct array_t *array;
    array_page_t *current;
    int index;
} array_index_t;

typedef struct array_t
{
    array_page_t *list;
    array_index_t index;
    int element_size;
    int elements_per_page;
} array_t;

/* manipulate entire arrays */
extern void array_init( array_t *array, int element_size,
                        int elements_per_page );
extern void array_destroy( array_t *array );
extern void array_clear( array_t *array );
extern void *array_alloc( array_t *array, int *available );
extern void array_update( array_t *array, int added );
#define array_size(array) ((array)->index.index)

/* array access */
extern void array_index_init( array_index_t *index,
                              array_t *array );
extern void *array_index_next_page( array_index_t *index,
                                    int *elements_in_page );
#define array_index(index) ((index)->index)

#endif
