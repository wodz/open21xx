/*
 * This is a small program to verify the linking of multiple files
 * with multiple program and data pages.
 */
 
	.pagewidth 40;
	.leftmargin 10;

#include "page.h"

    .global page0fn, page4fn, page5fn;
    .global vardata00, vardata4, vardata5;
    .global varpmdata00, varpmdata4, varpmdata5;

    .section/dm data00;
    .var vardata00 = { 1000 };

    .section/dm data4;
    .var vardata4 = { 2000 };

    .section/dm data5;
    .var vardata5 = { 3000 };


	.section/PM program00;
    .var varpmdata00 = { 4000 };
    .var dummy1[0x123];
page0fn:

    rts;

	.section/PM program4;
    .var/init24 varpmdata4 = { 5000 * 256 };
    .var dummy2[0x245];
page4fn:

    rts;

	.section/PM program5;
    .var varpmdata5 = { 6000 };
    .var dummy3[0x056];
page5fn:

    rts;
