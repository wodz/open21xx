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
YFLAGS+=-d -v
LFLAGS+= -d -L

CFLAGS= -g -DYYDEBUG

TARGET=verify21

GRAMMARS=verify21-grammar.y

.PHONY: clean

all: check8x check9x $(TARGET)

check8x: $(TARGET)
	../as21/as218x -o 218x.o -dv 218x.dsp | ./verify21
	../as21/as218x -o preproc.o -dv -I incdir2 -I incdir -I include preproc.dsp | ./verify21

check9x: $(TARGET)
	../as21/as219x -o 219x.o -dv 219x.dsp | ./verify21
	../as21/as219x -o preproc.o -dv -I incdir2 -I incdir -I include preproc.dsp | ./verify21

$(TARGET): $(TARGET)-grammar.o $(TARGET)-lex.o
	$(CC) -o $(TARGET) $^

$(TARGET)-lex.o: $(TARGET)-lex.c verify21-grammar.h

$(TARGET)-grammar.c $(TARGET)-grammar.h: $(TARGET)-grammar.y
	$(YACC) $(YFLAGS) -o $(TARGET)-grammar.c $<

clean:
	@-rm $(TARGET) *.o *~ $(GRAMMARS:.y=.c) $(GRAMMARS:.y=.h) \
		*.output *.lst *.map

