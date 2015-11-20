/*
 * fixup.h
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
 * Handle code fixups for the different machine types supported by the linker
 */

#ifndef _FIXUP_H
#define _FIXUP_H
#include <elf.h>
#include <libelf.h>

typedef const char *(*fixup_code_fn)(
    int reltype, 
    Elf32_Sword fixup,
    Elf32_Addr offset,
    Elf32_Shdr *shdr,
    void *section_data );

int fixup_code_map( Elf32_Half machine,
                    fixup_code_fn *fixup_code );

#endif
