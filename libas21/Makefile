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
CFLAGS=-Wall -I..

# "make DEBUG=1" to turn on compiler debugging
ifdef DEBUG
CFLAGS+=-g
endif

# "make NDEBUG=1" to compile out asserts
ifdef NDEBUG
CFLAGS+=-DNDEBUG
endif

TARGET=libas21.a

.PHONY: clean

all: $(TARGET)

$(TARGET): outfile.o bbtree.o dllist.o util.o
	ar rc $(TARGET) $^

bbtree.o: bbtree.c bbtree.h

outfile.o: outfile.c outfile.h dllist.h

dllist.o: dllist.c dllist.h

util.o: util.c util.h

clean:
	@-rm $(TARGET) *.o *~
