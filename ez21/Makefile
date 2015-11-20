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
CFLAGS= -g -I ..

# "make NDEBUG=1" to compile out asserts
ifdef NDEBUG
CFLAGS+=-DNDEBUG
endif

TARGET=ez21

.PHONY: clean

$(TARGET): $(TARGET).o
	$(CC) -o $@ $^ -lelf

ez21.o: ez21.c ../defs.h ../adielf.h

clean:
	@-rm $(TARGET) *.o *~
