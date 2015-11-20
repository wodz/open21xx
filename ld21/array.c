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
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "array.h"

void array_index_init( array_index_t *index,
                       array_t *array )
{
    index->array = array;
    index->index = 0;
    index->current = NULL;
}

void *array_index_next_page( array_index_t *index,
                             int *page_size )
{
    array_t *array;
    int i;

    array = index->array;
    if ( index->current == NULL ) /* get the first page */
    {
        index->current = array->list;
        index->index = 0;
        if ( index->current == NULL )
        {
            return NULL;
        }
    }
    else  /* get the next page */
    {
        i = index->index;
        /* round index up to the start of the next page */
        i += array->elements_per_page;
        i -= i % array->elements_per_page;
        if ( i >= array->index.index )
        {
            /* update index to the end of the array */
            index->index = array->index.index;
            return NULL;
        }
        assert( index->current->next != NULL );
        index->index = i;
        index->current = index->current->next;
    }
    if ( index->current )
    {
        *page_size = array->index.index - index->index;
        if ( *page_size > array->elements_per_page )
        {
            *page_size = array->elements_per_page;
        }
        return &index->current->next + 1;
    }
    return NULL;
}

void array_init( array_t *array, int element_size,
                 int elements_per_page )
{
    array->list = NULL;
    array_index_init( &array->index, array );
    array->element_size = element_size;
    array->elements_per_page = elements_per_page;
}

void array_destroy( array_t *array )
{
    array_page_t *page, *list;

    list = array->list;
    while ( list )
    {
        page = list->next;
        free( list );
        list = page;
    }
    memset( array, 0, sizeof( *array ) );
}

/*
 * empty the array but don't free its resources
 */
void array_clear( array_t *array )
{
    array_index_init( &array->index, array );
}

/*
 * allocates a new element at the end of the array
 *
 * returns a pointer to that element
 */
void *array_alloc( array_t *array, int *available )
{
    array_page_t *page;
    int page_index;
    char *element;

    assert( array->element_size != 0 );
    page_index = array->index.index % array->elements_per_page;
    if ( page_index == 0 )
    {
        /* need to allocate or go to the next page */
        if ( array->index.current == NULL )
        {
            if (array->list != NULL)
            {
                array->index.current = array->list;
            }
            else
            {
                page = (array_page_t *)malloc(
                    sizeof(array_page_t *) +
                    array->element_size * array->elements_per_page );
                assert( page );
                if (page)
                {
                    page->next = NULL;
                    array->index.current = array->list = page;
                }
            }
        }
        else if ( array->index.current->next != NULL )
        {
            array->index.current = array->index.current->next;
        }
        else
        {
            page = (array_page_t *)malloc(
                sizeof(array_page_t *) +
                array->element_size * array->elements_per_page );
            assert( page );
            if (page)
            {
                page->next = NULL;
                array->index.current->next = page;
                array->index.current = page;
            }
        }
    }
    /* point to start of page's data */
    element = (char *)(&array->index.current->next + 1);
    element += page_index * array->element_size;
    *available = array->elements_per_page - page_index;
    return element;
}

void array_update( array_t *array, int added )
{
    assert( array->index.index % array->elements_per_page + added <=
            array->elements_per_page );
    array->index.index += added;
}

