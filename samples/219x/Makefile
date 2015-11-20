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
ASM=../../as21/as219x
LINK=../../ld21/ld21
LDF=../../ADSP-2191.ldf
ASM_FLAGS=-I ../../include

LINK_SRC = link1.dsp link2.dsp
LINK_OBJS =  $(LINK_SRC:.dsp=.o)

UARTBOOT_SRC = UARTBoot.dsp
UARTBOOT_OBJS =  $(UARTBOOT_SRC:.dsp=.o)

TARGETS = link UARTBoot

all: $(TARGETS)

link: $(LINK_OBJS)
	$(LINK) -o $@ -T $(LDF) $(LINK_OBJS)
        
UARTBoot: $(UARTBOOT_OBJS)
	$(LINK) -o $@ -T UARTBoot.ldf $(UARTBOOT_OBJS)

%.o: %.dsp
	$(ASM) -o $@ $(ASM_FLAGS) $<

clean:
	@-rm $(TARGETS) *.o *~ *.lst *.map
