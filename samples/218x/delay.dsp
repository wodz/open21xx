/*
 * This is a small program to verify the linking of multiple files
 * and its about the simplest program that can do something visible
 * on the ezkit lite.
 */
#define delayms 			\
	cntr=33000/4;	 		\
	do delayms_loop? until ce;	\
		nop;			\
		nop;			\
		nop;			\
delayms_loop?:				\
		nop
	
	.extern start, start2;
	.global TurnOn, TurnOff;
	.section/PM program0;

/* delay for 5 seconds with led on */
TurnOn:
	set fl1;
	cntr = 5000;
	do led_on until ce;
		delayms;
led_on:
	nop;
	jump start2;

TurnOff:
	reset fl1;
	cntr = 1500;
	do led_off until ce;
		delayms;
led_off:
	nop;
	jump start;	




