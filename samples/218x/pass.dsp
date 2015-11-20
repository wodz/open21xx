#include "registers.h"
#include "mmregs.h"
#include "ad1847.h"

.section/pm	interrupts;

	jump start;             /* Reset interrupt vector */
	 rti; 
	 rti; 
	 rti;

	rti;                    /* IRQ2 interrupt vector */
	 rti; 
	 rti; 
	 rti;

	rti;                    /* IRQL1 interrupt vector */
	 rti;
	 rti;
	 rti;

	rti;                    /* IRQL0 interrupt vector */
	 rti; 
	 rti; 
	 rti;

        jump ad1847TxInt;	/* SPORT0 tx interrupt vector */
	 rti;
	 rti;
	 rti;

	jump ad1847RxInt;       /* SPORT0 rx interrupt vector */
	 rti;
	 rti;
	 rti;

	toggle fl1;           	/* IRQE interrupt vector */
	 rti;
	 rti;
	 rti;

	rti;            	/* BDMA interrupt vector */
	 rti; 
	 rti; 
	 rti;

	rti;                    /* SPORT1 tx / IRQ1 interrupt vector */
	 rti;
	 rti; 
	 rti;

	rti;                   	/* SPORT1 rx / IRQ0 interrupt vector */
	 rti;
	 rti; 
	 rti;

	rti;                   	/* timer interrupt vector */
	 rti; 
	 rti; 
	 rti;

	rti;                   	/* power down interrupt vector */
	 rti; 
	 rti; 
	 rti;

.section/pm program0;
start:
	ax0 = WAITSTATE_SET(0,7,7,7,7);   
	dm (WAITSTATE) = ax0;

	ax0 = SYS_SPORT0_ENA;		/* PWAIT = 0 */
	dm (SYS_CTRL) = ax0;

	ifc = IFC_CLEAR_ALL;
	nop;
	icntl = ICNTL_IRQ0_LEVEL | ICNTL_IRQ1_LEVEL |
                ICNTL_IRQ2_LEVEL;
	mstat = MSTAT_GO_ENA;

	call ad1847Init;

	ifc = IFC_CLEAR_ALL;
	nop;

	ax0 = imask;
	ar = ax0 or IMASK_IRQE;
	imask = ar;

forever_loop:
	idle;
	jump forever_loop;


