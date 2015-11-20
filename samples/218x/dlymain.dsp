/*
 * This is a small program to verify the linking of multiple files
 * and its about the simplest program that can do something visible
 * on the ezkit lite.
 */
	.pagewidth 40;
	.leftmargin 10;

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

	.global start;
	.global start2;
	.section/PM program0;
start:
	jump TurnOn;
start2:	
	jump TurnOff;

	.extern TurnOn, TurnOff;

