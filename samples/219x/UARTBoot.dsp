/*
 * A small program to test the ez21 UART boot loading.
 * Send "Booted" after we've started.
 *
 * Of course you wouldn't write a real program this way!
 */

#define UART_CONTROLLER_PAGE        0x5

#define UART_THR                    0x00

#define UART_LSR                    0x05
#define UART_LSR_THRE               0x20
	
	.pagewidth 40;
	.leftmargin 10;
    
    .section/DM dataB;
    .var boot = 'B';
    
    .section/DM dataoo;
    .var = 'oo';
    
    .section/DM datat;
    .var = 't';
    
    .section/DM datae;
    .var = 'e';
    
    .section/DM datad;
    .var = 'd\r\n';
BootedEnd:
    
	.section/PM interrupts;
    jump start;
    
    .section/PM program0;
start:    
    iopg = UART_CONTROLLER_PAGE;
    l0 = 0;
    m0 = 1;
    ay0 = BootedEnd;
    
    .section/PM program1;
ReSend:    
    i0 = boot;
wait_tx_ready:
    ar = io(UART_LSR);
    ar = ar AND UART_LSR_THRE;
    if eq jump wait_tx_ready;
    
    ar = dm(i0,m0);
    io(UART_THR) = ar;

    .section/PM program2;
wait_thre:
    ar = io(UART_LSR);
    ar = ar and UART_LSR_THRE;
    if ne jump wait_thre;
    ar = i0;
    ar = ar - ay0;
    if lt jump wait_tx_ready;
    jump ReSend;

    



