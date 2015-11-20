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
CFLAGS=-Wall -I../libas21 -I..
YFLAGS=-d

# "make DEBUG=1" to turn debugging on in the compiler
#                and enable lex and yacc debugging
ifdef DEBUG
YFLAGS+= -v
LFLAGS+= -d # -L
CFLAGS+=-g -DYYDEBUG
endif

# "make NDEBUG=1" to compile out asserts
ifdef NDEBUG
CFLAGS+=-DNDEBUG
endif

YACC=bison

GRAMMARS_8X=as21-grammar.y pp-grammar.y

GRAMMARS_9X=as219x-grammar.y pp-grammar.y

GRAMMARS=$(GRAMMARS_8X) $(GRAMMARS_9X)

LEXERS=as21-lex.l

CFILES = as21.c cpp.c listing.c symbol.c keyword.c grammar.c expression.c
CFILES_8X = $(CFILES) keytable8x.c
CFILES_9X = $(CFILES) keytable9x.c

CTESTFILES=keytest.c

OBJS_8X=$(CFILES_8X:.c=.o) $(GRAMMARS_8X:.y=.o) $(LEXERS:.l=.o)

OBJS_9X=$(CFILES_9X:.c=.o) $(GRAMMARS_9X:.y=.o) $(LEXERS:.l=.o)

.PHONY: clean

all: as218x as219x

as218x: $(OBJS_8X) ../libas21/libas21.a
	$(CC) -o $@ $^ -L ../libas21 -las21 -lelf

as219x: $(OBJS_9X) ../libas21/libas21.a
	$(CC) -o $@ $^ -L ../libas21 -las21 -lelf

keytest8x: keytest.o keyword.o keytable8x.o
	$(CC) -o $@ $(CFLAGS) $^

keytest9x: keytest.o keyword.o keytable9x.o
	$(CC) -o $@ $(CFLAGS) $^

as21.o: as21.c as21-lex.h listing.h symbol.h grammar.h \
	../defs.h ../adielf.h

#
# explicitly use flex since its required
#
as21-lex.c: as21-lex.l as21-lex.h as21-grammar.h  as219x-grammar.h \
		pp-grammar.h symbol.h expression.h listing.h \
		 ../defs.h ../libas21/bbtree.h ../libas21/util.h
		flex -t $(LFLAGS) $< > $@

as21-grammar.c as21-grammar.h: as21-grammar.y symbol.h listing.h \
		expression.h ../defs.h ../libas21/outfile.h ../libas21/util.h
	$(YACC) $(YFLAGS) -o as21-grammar.c $<

as219x-grammar.c as219x-grammar.h: as219x-grammar.y symbol.h listing.h \
		expression.h ../defs.h ../libas21/outfile.h ../libas21/util.h
	$(YACC) $(YFLAGS) -o as219x-grammar.c $<

pp-grammar.c pp-grammar.h: pp-grammar.y as21-lex.h listing.h \
		../defs.h
	$(YACC) $(YFLAGS) -o pp-grammar.c -b pp -p pp $<

symbol.o: symbol.c symbol.h as21-grammar.h listing.h \
		../defs.h ../libas21/outfile.h ../libas21/bbtree.h

listing.o: listing.h as21-lex.h \
		../defs.h ../libas21/outfile.h

keyword.o: keyword.c keyword.h keytable.h

keytable8x.o: keytable8x.c keytable.h as21-grammar.h \
		../defs.h

keytable9x.o: keytable9x.c keytable.h as219x-grammar.h \
		../defs.h

grammar.o: grammar.c grammar.h \
        ../defs.h
        
expression.o: expression.c expression.h \
        ../defs.h

keytest.o: keytest.c keyword.h keytable.h

cpp.o: cpp.c cpp.h pp-grammar.h as21-lex.h listing.h symbol.h \
	../defs.h

clean:
	@-rm as218x as219x *.o *~ $(GRAMMARS:.y=.c) $(GRAMMARS:.y=.h) \
		$(LEXERS:.l=.c) *.output *.lst *.map keytest


