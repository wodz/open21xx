/*
 * This is a small program to verify the linking of multiple files
 * with multiple program and data pages.
 */

#include "page.h"

	.pagewidth 40;
	.leftmargin 10;
    .section/dm data0;
    .var dmindex;
    .var = { page(page4fn) };
    .var = { page(page5fn) };
    .var = { page(page0fn) };
    .var = { page(vardata00) };
    .var = { page(vardata4) };
    .var = { page(vardata5) };
    .var = { page(varpmdata00) };
    .var = { page(varpmdata4) };
    .var = { page(varpmdata5) };

	.section/PM interrupts;
	jump start; rti; rti; rti;

	rti; rti; rti; rti;	/* IRQ2 */
	rti; rti; rti; rti;     /* HIP write */
	rti; rti; rti; rti;	/* HIP read */
	rti; rti; rti; rti;	/* SPORT0 transmit */
	rti; rti; rti; rti;	/* SPORT0 Receive */
	rti; rti; rti; rti;	/* Analog DAC transmit */
	rti; rti; rti; rti;	/* Analog ADC receive */
	rti; rti; rti; rti;	/* SPORT1 transmit or IRQ1 */
	rti; rti; rti; rti;	/* SPORT1 receive or IRQ0 */
	rti; rti; rti; rti;	/* timer */
	rti; rti; rti; rti;	/* Powerdown (non-maskable) */

	.section/PM program0;
    .var = { page(page4fn) };
    .var = { page(page5fn) };
    .var = { page(page0fn) };
    .var = { page(vardata00) };
    .var = { page(vardata4) };
    .var = { page(vardata5) };
    .var = { page(varpmdata00) };
    .var = { page(varpmdata4) };
    .var = { page(varpmdata5) };
    .var/init24 = { page(page4fn) };
    .var/init24 = { page(page5fn) };
    .var/init24 = { page(page0fn) };
    .var/init24 = { page(vardata00) };
    .var/init24 = { page(vardata4) };
    .var/init24 = { page(vardata5) };
    .var/init24 = { page(varpmdata00) };
    .var/init24 = { page(varpmdata4) };
    .var/init24 = { page(varpmdata5) };
start:
    ar = page(page4fn);
    pmovlay = ar;
    call address(page4fn);
    ar = page(page5fn);
    pmovlay = ar;
    call address(page5fn);
    ar = page(page0fn);
    pmovlay = ar;
    call address(page0fn);


    pmovlay = page(page4fn);
    call address(page4fn);
    pmovlay = page(page5fn);
    call address(page5fn);
    pmovlay = page(page0fn);
    call address(page0fn);
    
    dmovlay = page(vardata00);
    dmovlay = page(vardata4);
    dmovlay = page(vardata5);

    i0 = dmindex;
    m0 = 0;
    dm(i0,m0) = page(page4fn);
    dm(i0,m0) = page(page5fn);
    dm(i0,m0) = page(page0fn);

    dm(i0,m0) = page(vardata00);
    dm(i0,m0) = page(vardata4);
    dm(i0,m0) = page(vardata5);

    dm(i0,m0) = page(varpmdata00);
    dm(i0,m0) = page(varpmdata4);
    dm(i0,m0) = page(varpmdata5);
    
    ar = address(page4fn);
    ar = address(page5fn);
    ar = address(page0fn);

    jump start;         /* and loop */

