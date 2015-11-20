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
ASM=../../as21/as218x
LINK=../../ld21/ld21
LDF=../../ADSP-2181.ldf
BSS_LDF=bss.ldf
ASM_FLAGS=-I ../../include

DELAY_SRC = dlymain.dsp delay.dsp
DELAY_OBJS =  $(DELAY_SRC:.dsp=.o)

PASS_SRC = pass.dsp ad1847.dsp
PASS_OBJS =  $(PASS_SRC:.dsp=.o)

REVERB_SRC = reverb.dsp
REVERB_OBJS = $(REVERB_SRC:.dsp=.o)

STAIR_SRC = stair.dsp
STAIR_OBJS = $(STAIR_SRC:.dsp=.o)

PAGE_SRC = mainpage.dsp page.dsp
PAGE_OBJS = $(PAGE_SRC:.dsp=.o)

TARGETS = dlymain pass reverb stair page

all: $(TARGETS)

dlymain: $(DELAY_OBJS)
	$(LINK) -o $@ -T $(LDF) $(DELAY_OBJS)

pass: $(PASS_OBJS)
	$(LINK) -o $@ -T $(LDF) $(PASS_OBJS)

reverb: $(REVERB_OBJS)
	$(LINK) -o $@ -T $(BSS_LDF) $(REVERB_OBJS)

stair: $(STAIR_OBJS)
	$(LINK) -o $@ -T $(BSS_LDF) $(STAIR_OBJS)

page: $(PAGE_OBJS) page.h
	$(LINK) -o $@ -T page.ldf $(PAGE_OBJS)


%.o: %.dsp
	$(ASM) -o $@ $(ASM_FLAGS) $<

clean:
	@-rm $(TARGETS) *.o *~ *.lst *.map
