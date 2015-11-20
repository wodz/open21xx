/*
 * as21-grammar.y 
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

#if !defined(_DEFS_H)
#define _DEFS_H

#define VERSION_NUMBER      "0.7.6"

#define sizearray(x)        (sizeof(x)/sizeof(x[0]))

#ifndef FALSE
#define FALSE 0
#define TRUE (!FALSE)
#endif

/* if we've included fcntl.h and O_BINARY isn't included */
#if defined(O_RDONLY) && !defined(O_BINARY)
#define O_BINARY 0          /* for Windows compatibility */
#endif

typedef struct
{
    unsigned long length;
    char *string;
}string_t;

#endif /* _DEFS_H */
