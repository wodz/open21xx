#
#  Makefile 
#  
#  Part of the Open21xx assembler toolkit
#  
#  Copyright (C) 2002 by Keith B. Clifford 
#  
#  The Open21xx toolkit is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as published
#  by the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
# 
#  The Open21xx toolkit is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with the Open21xx toolkit; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
CFLAGS=-Wall -I ../libas21
YFLAGS=-d

# "make DEBUG=1" to turn debugging on in the compiler
#                and enable lex and yacc debugging
ifdef DEBUG
YFLAGS+= -v
LFLAGS+= -d # -L
CFLAGS+= -g -DYYDEBUG
endif

# "make NDEBUG=1" to compile out asserts
ifdef NDEBUG
CFLAGS+=-DNDEBUG
endif

LEXERS=ld21-lex.l

GRAMMARS=ld21-grammar.y

.PHONY: clean

ld21: ld21-grammar.o ld21-lex.o dspmem.o namelist.o macro.o \
		 execfile.o array.o fixup.o \
		../libas21/libas21.a
	$(CC) -o $@ $^ -L ../libas21 -las21 -lelf

ld21-grammar.c ld21-grammar.h: ld21-grammar.y ld21-lex.h dspmem.h \
		namelist.h macro.h execfile.h \
		../defs.h
	$(YACC) $(YFLAGS) -o ld21-grammar.c $<

ld21-lex.c : ld21-lex.l ld21-lex.h ld21-grammar.h dspmem.h \
		namelist.h macro.h
		flex -t $(LFLAGS) $< > $@

execfile.o: execfile.c execfile.h namelist.h dspmem.h ld21-lex.h \
	array.h fixup.h \
	../defs.h ../adielf.h ../libas21/outfile.h ../libas21/bbtree.h

dspmem.o: dspmem.c dspmem.h ld21-lex.h

namelist.o: namelist.c namelist.h

macro.o: macro.c macro.h namelist.h

array.o: array.c array.h

fixup.o: fixup.c fixup.h \
	../defs.h ../adielf.h

clean:
	@-rm ld21 *.o *~ $(GRAMMARS:.y=.c) $(GRAMMARS:.y=.h) \
		$(LEXERS:.l=.c) *.output *.lst *.map

