/*
 * keytest.c 
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
#include "keyword.h"
#include "keytable.h"

int main( int argc, char **argv )
{
    const keyword_t *keyword;
    int i, result;
    int faults;

    keyword = keywords + 1;
    faults = 0;
    for ( i = 1 ; i < keywords_size ; ++i )
    {
        result = compare_keyword( (keyword - 1)->name, keyword );
        if (result >= 0)
        {
            printf( "%s >= %s\n", (keyword - 1)->name, keyword->name );
            ++faults;
        }
        ++keyword;
    }
    printf( "%d faults found\n", faults );
    return 0;
}

