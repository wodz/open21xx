#include "reloc.h"
    
    .global buf1, buf2, buf3, buf4;
    .global target1, target2, target3, target4, target5;

    .section/DM data0;
    .var space1[12];
    .var buf1[buf1_length];

    .section/DM data00 SHT_NOBITS;
    .var space2[57];
    .var buf2[buf2_length];
    
    .section/DM data4 SHT_NOBITS;
    .var space3[0x1325];
    .var/circ buf3[buf3_length];
    
    .section/DM data5 SHT_NOBITS;
    .var space4[0x0b19];
    .var buf4[buf4_length];
    
    .section/PM program0;
target1:
    nop; nop; nop; nop;
target2:
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop;
target3:
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop;
target4:
    nop; nop; nop; nop;
    nop; nop; nop; nop;
    nop; nop; nop; nop;
target5:    