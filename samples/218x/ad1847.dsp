#include "registers.h"
#include "mmregs.h"
#include "ad1847.h"

.pagewidth 120;
.global 	ad1847Init, ad1847RxInt, ad1847TxInt;

.section/dm	data0;
.var/circ     	rx_buf[3]; 	/* rx buffer, Status + L data + R data */

#define CLOR_MCE (AD1847_CTRL_CLOR | AD1847_CTRL_MCE)

.var/circ       tx_buf[3] =     /* tx buffer, Cmd + L data + R data */
{
	CLOR_MCE,
	0x0000,
	0x0000
};

.var/circ    init_cmds[] = 	/* initialization codes */
{
	CLOR_MCE | AD1847_INL | AD1847_IN_SS_LINE1 | AD1847_IN_GAIN_SET(30),
	CLOR_MCE | AD1847_INR | AD1847_IN_SS_LINE1 | AD1847_IN_GAIN_SET(30),
	CLOR_MCE | AD1847_AUX1L | AD1847_MUTE | AD1847_AUX_GAIN_SET(0),
	CLOR_MCE | AD1847_AUX1R | AD1847_MUTE | AD1847_AUX_GAIN_SET(0),
	CLOR_MCE | AD1847_AUX2L | AD1847_MUTE | AD1847_AUX_GAIN_SET(0),
	CLOR_MCE | AD1847_AUX2R | AD1847_MUTE | AD1847_AUX_GAIN_SET(0),
	CLOR_MCE | AD1847_DACL | AD1847_MUTE | AD1847_DAC_ATTN_SET(0),
	CLOR_MCE | AD1847_DACR | AD1847_MUTE | AD1847_DAC_ATTN_SET(0),
	CLOR_MCE | AD1847_DFMT | AD1847_DFMT_LINEAR16 | AD1847_DFMT_STEREO |
		AD1847_DFMT_8K,
	CLOR_MCE | AD1847_IFACE | AD1847_IFACE_PEN | AD1847_IFACE_ACAL,
	CLOR_MCE | AD1847_PIN,
	CLOR_MCE | AD1847_MISC | AD1847_MISC_32_SLOT | AD1847_MISC_2_WIRE,
	CLOR_MCE | AD1847_DMIX | AD1847_DMIX_ATTN_SET(0),
	AD1847_CTRL_CLOR | AD1847_CTRL_RREQ | AD1847_NOREG,
	AD1847_CTRL_CLOR | AD1847_DACL | AD1847_DAC_ATTN_SET(0),
	AD1847_CTRL_CLOR | AD1847_DACR | AD1847_DAC_ATTN_SET(0)
};

#define INIT_LENGTH	14
#define UNMUTE_LENGTH	2

.section/pm program0;

/*
 * Note: ax0 and af are shared by this routine and ad1847TxInt.
 *       When af is none 0, ad1847TxInt will modify ax0.
 *       af specifies the number of words left for ad1847TxInt
 *       to write.
 */
ad1847Init:
	i0 = rx_buf;
	l0 = LENGTH(rx_buf);
	i1 = tx_buf;
	l1 = LENGTH(tx_buf);
	i3 = init_cmds;
	l3 = 0;
	m1 = 1;

	/* setup autobuffering on SPORT0 to talk to the AD1847 */
	ax0 = SPORT_AUTO_RREG(0,1) | SPORT_AUTO_TREG(1,1);   
	dm (SPORT0_AUTO) = ax0;
	ax0 = 0;         
	dm (SPORT0_RFSDIV) = ax0;       /*  using external RFS */

	ax0 = 0;         
	dm (SPORT0_SCLKDIV) = ax0;      /*  SCLK = CLKOUT / 2 */ 

	ax0 = SPORT_CTRL_SLEN_SET(16) | SPORT_CTRL_DTYPE_ZERO |
	      SPORT0_CTRL_MCE | SPORT0_CTRL_MFD_SET(1) | SPORT0_CTRL_MCL_32;
	dm (SPORT0_CTRL) = ax0;

	ax0 =0x7;      
        dm (SPORT0_TX_CHANS_LO) = ax0;  /* tx on channels 0, 1 and 2 */
	dm (SPORT0_TX_CHANS_HI) = ax0;  /* tx on channels 16, 17 and 18 */
	dm (SPORT0_RX_CHANS_LO) = ax0;  /* rx on channels 0, 1 and 2 */
	dm (SPORT0_RX_CHANS_HI) = ax0;  /* rx on channels 16, 17 and 18 */

	/* codec initialization */
	ax0 = INIT_LENGTH;
	af = pass ax0;			/* af=number of words left to write */

	ax0 = imask;
	ar = ax0 or IMASK_SPORT0_TX;
	imask = ar;			/* unmask SPORT0 tx interrupt */
	ax0 = dm (i1, m1);              /* start autobuffering by writting */
	tx0 = ax0;                      /* first tx_buf value */

check_init:
	/* wait for init_cmds to complete */
	idle;
	NONE = pass af;
	if ne jump check_init;

	/* wait for codec to go into auto calibration */
check_aci1:
	ax0 = dm (rx_buf);
	ar = ax0 and AD1847_STAT_ACI;
	if eq jump check_aci1;

	/* wait for codec to come out of auto calibration */
check_aci2:
	ax0 = dm (rx_buf);
	ar = ax0 and AD1847_STAT_ACI;
	if ne jump check_aci2;
	idle;

	ax0 = UNMUTE_LENGTH;
	af = pass ax0;

	/* wait for commands to be sent */
check_done:
	idle;
	none = pass af;
	if ne jump check_done;	

	/* done with transmit but now want receive interrupts */
	ax0 = imask;
	ar = ax0 or IMASK_SPORT0_RX;
	ar = ar and ~IMASK_SPORT0_TX;
	imask = ar;
 	rts;

/*
 * Receive Interrupt Service Routine
 */
ad1847RxInt:
	ena sec_reg;
	ax0 = dm(rx_buf + 1);           /* loopback left channel data */
	dm (tx_buf + 1) = ax0;
	ay0 = dm(rx_buf + 2);           /* loopback right channel data */
	dm (tx_buf + 2) = ay0;
	rti;
 
/*
 * Transmit Interrupt Service Routine
 * 
 * Only used during initialization
 * af contains the current number of words remaining in init_cmds
 * to be sent
 */
ad1847TxInt:
	none = pass af;
	if eq rti;
	/* put next init_cmd into tx_buf */
	ax0 = dm (i3, m1);
	dm (tx_buf) = ax0;
	af = af-1;
	rti;







