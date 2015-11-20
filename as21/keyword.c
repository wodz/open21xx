/*
 * keyword.c 
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
#include <ctype.h>
#include "keyword.h"
#include "keytable.h"

/* manually do the case insensitive compare to know where characters
 * between upper and lower case will be ordered */
int compare_keyword( const void *key, const void *element)
{
    const char *src = key;
    const char *dst = ((const keyword_t *)element)->name;

    while ( *src && *dst && tolower( *src ) == tolower( *dst ) )
    {
        ++src;
        ++dst;
    }
    return tolower(*src) - tolower(*dst);
}

int find_keyword( const char *name )
{
    const keyword_t *keyword;

    keyword = (keyword_t *)bsearch( name, keywords,
                                    keywords_size,
                                    sizeof(keyword_t),
                                    compare_keyword );
    if ( keyword )
        return keyword->token;
    return 0;
}









