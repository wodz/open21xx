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
        
.extern page0fn, page4fn, page5fn;

.extern vardata00, vardata4, vardata5;

.extern varpmdata00, varpmdata4, varpmdata5;




