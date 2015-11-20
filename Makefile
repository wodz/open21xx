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

# "make clean" to rebuild all subdirectories
# "make DEBUG=1" to turn on compiler debugging for all subdirectories
# "make NDEBUG=1" to compile out asserts in all subdirectories


.PHONY:	all build_samples build_all install clean_all clean tar backup

ifndef INSTALL_DIR
INSTALL_DIR=/usr/local/
endif

INSTALL_BIN=$(INSTALL_DIR)/bin/
INSTALL_TARGET=$(INSTALL_DIR)/share/open21xx/
INSTALL_INCLUDE=$(INSTALL_TARGET)/include/
INSTALL_MAN1=$(INSTALL_DIR)/share/man/man1/
INSTALL=install

all:	build_all build_samples

build_samples:	build_all
	$(MAKE) -C samples

build_all:
	$(MAKE) -C libas21
	$(MAKE) -C as21
	$(MAKE) -C ld21
	$(MAKE) -C ez21
	$(MAKE) -C elfdump
	$(MAKE) -C verify21

install:
	-$(INSTALL) -m 755 as21/as218x $(INSTALL_BIN)
	-$(INSTALL) -m 755 as21/as219x $(INSTALL_BIN)
	-$(INSTALL) -m 755 ld21/ld21 $(INSTALL_BIN)
	-$(INSTALL) -m 755 ez21/ez21 $(INSTALL_BIN)
	-$(INSTALL) -m 644 man1/{as218x,as219x,ld21,ez21}.1 $(INSTALL_MAN1)
	-$(INSTALL) -d -m 755 $(INSTALL_INCLUDE)
	-$(INSTALL) -m 644 include/* $(INSTALL_INCLUDE)
	-$(INSTALL) -m 644 *.ldf $(INSTALL_TARGET)

uninstall:
	-rm -f $(INSTALL_BIN)/{as218x,as219x,ld21,ez21}
	-rm -f $(INSTALL_MAN1)/{as218x,as219x,ld21,ez21}.1
	-rm -rf $(INSTALL_DIR)/open21xx

clean_all:	clean
	-rm *.tar.gz

clean:
	$(MAKE) -C libas21 $@
	$(MAKE) -C as21 $@
	$(MAKE) -C ld21 $@
	$(MAKE) -C ez21 $@
	$(MAKE) -C elfdump $@
	$(MAKE) -C verify21 $@
	$(MAKE) -C samples $@
	-rm include/*~ *~ man1/*~

tar:
	tar czf open21xx.tar.gz -X tar.exclude -C .. open21xx

backup:
	mount /mnt/floppy
	cp open21xx.tar.gz /mnt/floppy
	umount /mnt/floppy


