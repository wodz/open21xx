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
AS8X=../as21/as218x
AS9X=../as21/as219x
LINK=../ld21/ld21
LDF8X=page.ldf
LDF9X=./reloc9x.ldf

RELOC8X_SRC = global8x.dsp extern8x.dsp
RELOC8X_OBJS =  $(RELOC8X_SRC:.dsp=.o)
RELOC9X_SRC = global9x.dsp extern9x.dsp
RELOC9X_OBJS =  $(RELOC9X_SRC:.dsp=.o)

TARGETS = reloc8x reloc9x relgen

all: $(TARGETS)
	../elfdump/elfdump reloc8x | tail -n 39 | head -n 15 > relfrom
	../elfdump/elfdump reloc8x | tail -n 17 | head -n 10 >> relfrom
	../elfdump/elfdump reloc9x | tail -n 39 | head -n 19 >> relfrom
	../elfdump/elfdump reloc9x | tail -n 13 | head -n 10 >> relfrom
	./relgen > relto
	diff -C 0 -b relfrom relto

reloc8x: $(RELOC8X_OBJS)
	$(LINK) -o $@ -T $(LDF8X) -m $@.map $(RELOC8X_OBJS)

reloc9x: $(RELOC9X_OBJS)
	$(LINK) -o $@ -T $(LDF9X) -m $@.map $(RELOC9X_OBJS)

%8x.o: %8x.dsp reloc.h
	$(AS8X) -o $@ $(ASM_FLAGS) $<

%9x.o: %9x.dsp reloc.h
	$(AS9X) -o $@ $(ASM_FLAGS) $<
    
relgen: relgen.c reloc.h
	gcc -o relgen relgen.c

clean:
	@-rm $(TARGETS) *.o *~ *.lst *.map

dump:
	../elfdump/elfdump $(D)

    