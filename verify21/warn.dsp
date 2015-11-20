//    \
  \
\
#warning This is a line  /**/\\
         breaking warning at line 33 /***/
	.extern start, start2;
#warning This is a line  /**/\\
         breaking warning at line 8 /***/
	.section/PM program0;
#warning This is a warning on line 10
delay1:
	cntr = 0x3fff;
	do led_on until ce;
	  cntr = 0x200;
	  do led_on1 until ce;
		nop;
#warning This is a line  /**/\
         breaking warning at line 18
		nop;
#warning This is a line  /**/\\
         breaking warning at line 21 /***/

		nop;
led_on1:	nop;
led_on:		nop;
#error This is an error on line 26
	
	jump start2;
delay2:
	cntr = 0xfff;
	do led_off until ce;
	  cntr = 0x25;
	  do led_off1 until ce;
		nop;
#error This is a line \
         breaking error at line 36
		nop;
led_off1:	nop;
led_off: nop;

	jump start;
no_execute:
#
	ax0 = length(delay1);
#pragma
	jump start;


