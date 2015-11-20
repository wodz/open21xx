/*******************************************************************************

	Reverberation program as described by James A. Moorer in
	"About This Reverberation Business," Computer Music Journal,
	Vol. 3, No. 2, pp. 13-28, 1979.

	Written for the ADSP-2181 EZ-KIT Lite by
	Brian C. Neunaber, SLM Electronics

 *******************************************************************************/

/*******************************************************************************
 *
 *  Assemble time constants
 *
 *******************************************************************************/

#define  IDMA                    0x3fe0 
#define  BDMA_BIAD               0x3fe1 
#define  BDMA_BEAD               0x3fe2 
#define  BDMA_BDMA_Ctrl          0x3fe3 
#define  BDMA_BWCOUNT            0x3fe4 
#define  PFDATA                  0x3fe5 
#define  PFTYPE                  0x3fe6 

#define  SPORT1_Autobuf          0x3fef 
#define  SPORT1_RFSDIV           0x3ff0 
#define  SPORT1_SCLKDIV          0x3ff1 
#define  SPORT1_Control_Reg      0x3ff2 
#define  SPORT0_Autobuf          0x3ff3 
#define  SPORT0_RFSDIV           0x3ff4 
#define  SPORT0_SCLKDIV          0x3ff5 
#define  SPORT0_Control_Reg      0x3ff6 
#define  SPORT0_TX_Channels0     0x3ff7 
#define  SPORT0_TX_Channels1     0x3ff8 
#define  SPORT0_RX_Channels0     0x3ff9 
#define  SPORT0_RX_Channels1     0x3ffa 
#define  TSCALE                  0x3ffb 
#define  TCOUNT                  0x3ffc 
#define  TPERIOD                 0x3ffd 
#define  DM_Wait_Reg             0x3ffe 
#define  System_Control_Reg      0x3fff 

/* comb lengths are rounded to nearest prime number */
#define COMB1_LENGTH     1759  /* 40 ms @ 44.1 KHz*/
#define COMB2_LENGTH  	1949  /* 44 ms */
#define COMB3_LENGTH  	2113  /* 48 ms */
#define COMB4_LENGTH  	2293  /* 52 ms */
#define COMB5_LENGTH  	2467  /* 56 ms */
#define COMB6_LENGTH  	2647  /* 60 ms */

.section/dm bssdata0 SHT_NOBITS;
.VAR/CIRC early_refl[3520];
.var stat_flag;

.VAR/CIRC er_length[18];
.VAR/CIRC all_pass[307]; /* 7 ms, rounded to prime number */
.VAR/CIRC comb2[COMB2_LENGTH];
.VAR/CIRC comb3[COMB3_LENGTH];
.VAR/CIRC comb4[COMB4_LENGTH];
.VAR/CIRC comb_output[6];
.VAR early_refl_ptr;
.VAR all_pass_ptr;
.VAR comb1_ptr;
.VAR comb2_ptr;
.VAR comb3_ptr;
.VAR comb4_ptr;
.VAR comb5_ptr;
.VAR comb6_ptr;
.VAR comb1_lpf_state;
.VAR comb2_lpf_state;
.VAR comb3_lpf_state;
.VAR comb4_lpf_state;
.VAR comb5_lpf_state;
.VAR comb6_lpf_state;
.VAR left_input;
.VAR right_input;
.var/circ rx_buf[3];      /* Status + L data + R data */

.section/dm data0;
/* DATA MEMORY */
.var/circ tx_buf[3]=      /* Cmd + L data + R data    */
{   0xc000, 0x0000, 0x0000}; /* Initially set MCE        */

.var/circ init_cmds[13]=

{
        0xc002,     /*
                        Left input control reg
                        b7-6: 0=left line 1
                              1=left aux 1
                              2=left line 2
                              3=left line 1 post-mixed loopback
                        b5-4: res
                        b3-0: left input gain x 1.5 dB
                    */
        0xc102,     /*
                        Right input control reg
                        b7-6: 0=right line 1
                              1=right aux 1
                              2=right line 2
                              3=right line 1 post-mixed loopback
                        b5-4: res
                        b3-0: right input gain x 1.5 dB
                    */
        0xc288,     /*
                        left aux 1 control reg
                        b7  : 1=left aux 1 mute
                        b6-5: res
                        b4-0: gain/atten x 1.5, 08= 0dB, 00= 12dB
                    */
        0xc388,     /*
                        right aux 1 control reg
                        b7  : 1=right aux 1 mute
                        b6-5: res
                        b4-0: gain/atten x 1.5, 08= 0dB, 00= 12dB
                    */
        0xc488,     /*
                        left aux 2 control reg
                        b7  : 1=left aux 2 mute
                        b6-5: res
                        b4-0: gain/atten x 1.5, 08= 0dB, 00= 12dB
                    */
        0xc588,     /*
                        right aux 2 control reg
                        b7  : 1=right aux 2 mute
                        b6-5: res
                        b4-0: gain/atten x 1.5, 08= 0dB, 00= 12dB
                    */
        0xc680,     /*
                        left DAC control reg
                        b7  : 1=left DAC mute
                        b6  : res
                        b5-0: attenuation x 1.5 dB
                    */
        0xc780,     /*
                        right DAC control reg
                        b7  : 1=right DAC mute
                        b6  : res
                        b5-0: attenuation x 1.5 dB
                    */
        0xc85b,     /*
                        data format register
                        b7  : res
                        b5-6: 0=8-bit unsigned linear PCM
                              1=8-bit u-law companded
                              2=16-bit signed linear PCM
                              3=8-bit A-law companded
                        b4  : 0=mono, 1=stereo
                        b0-3: 0=  8.
                              1=  5.5125
                              2= 16.
                              3= 11.025
                              4= 27.42857
                              5= 18.9
                              6= 32.
                              7= 22.05
                              8=   .
                              9= 37.8
                              a=   .
                              b= 44.1
                              c= 48.
                              d= 33.075
                              e=  9.6
                              f=  6.615
                       (b0) : 0=XTAL1 24.576 MHz; 1=XTAL2 16.9344 MHz
                    */
        0xc909,     /*
                        interface configuration reg
                        b7-4: res
                        b3  : 1=autocalibrate
                        b2-1: res
                        b0  : 1=playback enabled
                    */
        0xca00,     /*
                        pin control reg
                        b7  : logic state of pin XCTL1
                        b6  : logic state of pin XCTL0
                        b5  : master - 1=tri-state CLKOUT
                              slave  - x=tri-state CLKOUT
                        b4-0: res
                    */
        0xcc40,     /*
                        miscellaneous information reg
                        b7  : 1=16 slots per frame, 0=32 slots per frame
                        b6  : 1=2-wire system, 0=1-wire system
                        b5-0: res
                    */
        0xcd00};     /*
                        digital mix control reg
                        b7-2: attenuation x 1.5 dB
                        b1  : res
                        b0  : 1=digital mix enabled
                    */


.section/pm interrupts;
/*******************************************************************************
 *
 *  Interrupt vector table
 *
 *******************************************************************************/
        jump start;  rti; rti; rti;     /*00: reset */
        rti;         rti; rti; rti;     /*04: IRQ2 */
        rti;         rti; rti; rti;     /*08: IRQL1 */
        rti;         rti; rti; rti;     /*0c: IRQL0 */
        ar = dm(stat_flag);             /*10: SPORT0 tx */
        ar = pass ar;
        if eq rti;
        jump next_cmd;
        jump input_samples;             /*14: SPORT1 rx */
                     rti; rti; rti;
        jump irqe;   rti; rti; rti;     /*18: IRQE */
        rti;         rti; rti; rti;     /*1c: BDMA */
        rti;         rti; rti; rti;     /*20: SPORT1 tx or IRQ1 */
        rti;         rti; rti; rti;     /*24: SPORT1 rx or IRQ0 */
        rti;         rti; rti; rti;     /*28: timer */
        rti;         rti; rti; rti;     /*2c: power down */


.section/pm pmbssdata0 SHT_NOBITS;

.VAR/CIRC comb5[COMB5_LENGTH];
.VAR/CIRC comb6[COMB6_LENGTH];
.VAR/CIRC comb1[COMB1_LENGTH];
.VAR/CIRC er_gain[18];

.section/pm program0;
/*******************************************************************************
 *
 *  ADSP 2181 intialization
 *
 *******************************************************************************/
start:

   ENA AR_SAT;

	I0 = rx_buf;
   L0 = LENGTH(rx_buf);
   I1 = tx_buf;
   L1 = LENGTH(tx_buf);
   I3 = init_cmds;
   L3 = LENGTH(init_cmds);

	M0 = 0;
	M1 = 1;
	M6 = 0;
	M7 = 1;

	L2 = 0;
	L4 = 0;
	L5 = 0;
	L6 = 0;
	L7 = 0;

	I5 = er_length;		/* initialize early reflection */ 
	DM(I5,M7) = -190;		/* delay tap lengths */
	DM(I5,M7) = -759;			
	DM(I5,M7) = -44;			
	DM(I5,M7) = -190;                
	DM(I5,M7) = -9;			
	DM(I5,M7) = -123;			
	DM(I5,M7) = -706;			
	DM(I5,M7) = -119;                
	DM(I5,M7) = -384;			
	DM(I5,M7) = -66;			
	DM(I5,M7) = -35;         
	DM(I5,M7) = -75;			
	DM(I5,M7) = -419;			
	DM(I5,M7) = -4;			
	DM(I5,M7) = -79;			
	DM(I5,M7) = -66;			
	DM(I5,M7) = -53;			
	DM(I5,M6) = -194;			

	I5 = er_gain;			/* initialize early reflection gains */				  
	AX0 = 0x6BA6;				
	PM(I5,M7) = AX0;		
	AX0 = 0x4083;
	PM(I5,M7) = AX0;
	AX0 = 0x3ED9;
	PM(I5,M7) = AX0;
	AX0 = 0x3083;
	PM(I5,M7) = AX0;
	AX0 = 0x30A4;
	PM(I5,M7) = AX0;
	AX0 = 0x2C4A;
	PM(I5,M7) = AX0;
	AX0 = 0x24FE;
	PM(I5,M7) = AX0;
	AX0 = 0x22D1;
	PM(I5,M7) = AX0;
	AX0 = 0x1893;
	PM(I5,M7) = AX0;
	AX0 = 0x18B4;
	PM(I5,M7) = AX0;
	AX0 = 0x1BC7;
	PM(I5,M7) = AX0;
	AX0 = 0x172B;
	PM(I5,M7) = AX0;
	AX0 = 0x170A;
	PM(I5,M7) = AX0;
	AX0 = 0x172B;
	PM(I5,M7) = AX0;
	AX0 = 0x1687;
	PM(I5,M7) = AX0;
	AX0 = 0x122D;
	PM(I5,M7) = AX0;
	AX0 = 0x1560;
	PM(I5,M7) = AX0;
	AX0 = 0x1127;
	PM(I5,M6) = AX0;

	AX0 = comb1;				/* initialize pointers to */ 	
	DM(comb1_ptr) = AX0;		/* comb filter buffers */
	AX0 = comb2;
	DM(comb2_ptr) = AX0;
	AX0 = comb3;
	DM(comb3_ptr) = AX0;
	AX0 = comb4;
	DM(comb4_ptr) = AX0;
	AX0 = comb5;
	DM(comb5_ptr) = AX0;
	AX0 = comb6;
	DM(comb6_ptr) = AX0;
	AX0 = all_pass;
	DM(all_pass_ptr) = AX0;
	AX0 = early_refl;
	DM(early_refl_ptr) = AX0;


/*================== S E R I A L   P O R T   #0   S T U F F ==================*/
        ax0 = b#0000001010000111;   dm (SPORT0_Autobuf) = ax0;
            /*   |||!|-/!/|-/|/|+- receive autobuffering 0=off, 1=on
                |||!|  ! |  | +-- transmit autobuffering 0=off, 1=on
                |||!|  ! |  +---- | receive m?
                |||!|  ! |        | m1
                |||!|  ! +------- ! receive i?
                |||!|  !          ! i0
                |||!|  !          !
                |||!|  +========= | transmit m?
                |||!|             | m1
                |||!+------------ ! transmit i?
                |||!              ! i1
                |||!              !
                |||+============= | BIASRND MAC biased rounding control bit
                ||+-------------- 0
                |+--------------- | CLKODIS CLKOUT disable control bit
                +---------------- 0
            */

        ax0 = 0;    dm (SPORT0_RFSDIV) = ax0;
            /*   RFSDIV = SCLK Hz/RFS Hz - 1 */
        ax0 = 0;    dm (SPORT0_SCLKDIV) = ax0;
            /*   SCLK = CLKOUT / (2  (SCLKDIV + 1) */
        ax0 = b#1000011000001111;   dm (SPORT0_Control_Reg) = ax0;
            /*   multichannel
                ||+--/|!||+/+---/ | number of bit per word - 1
                |||   |!|||       | = 15
                |||   |!|||       |
                |||   |!|||       |
                |||   |!||+====== ! 0=right just, 0-fill; 1=right just, signed
                |||   |!||        ! 2=compand u-law; 3=compand A-law
                |||   |!|+------- receive framing logic 0=pos, 1=neg
                |||   |!+-------- transmit data valid logic 0=pos, 1=neg
                |||   |+========= RFS 0=ext, 1=int
                |||   +---------- multichannel length 0=24, 1=32 words
                ||+-------------- | frame sync to occur this number of clock
                ||                | cycle before first bit
                ||                |
                ||                |
                |+--------------- ISCLK 0=ext, 1=int
                +---------------- multichannel 0=disable, 1=enable
            */
            /*   non-multichannel
                |||!|||!|||!+---/ | number of bit per word - 1
                |||!|||!|||!      | = 15
                |||!|||!|||!      |
                |||!|||!|||!      |
                |||!|||!|||+===== ! 0=right just, 0-fill; 1=right just, signed
                |||!|||!||+------ ! 2=compand u-law; 3=compand A-law
                |||!|||!|+------- receive framing logic 0=pos, 1=neg
                |||!|||!+-------- transmit framing logic 0=pos, 1=neg
                |||!|||+========= RFS 0=ext, 1=int
                |||!||+---------- TFS 0=ext, 1=int
                |||!|+----------- TFS width 0=FS before data, 1=FS in sync
                |||!+------------ TFS 0=no, 1=required
                |||+============= RFS width 0=FS before data, 1=FS in sync
                ||+-------------- RFS 0=no, 1=required
                |+--------------- ISCLK 0=ext, 1=int
                +---------------- multichannel 0=disable, 1=enable
            */


        ax0 = b#0000000000000111;   dm (SPORT0_TX_Channels0) = ax0;
            /*   ^15          00^   transmit word enables: channel # == bit # */
        ax0 = b#0000000000000111;   dm (SPORT0_TX_Channels1) = ax0;
            /*   ^31          16^   transmit word enables: channel # == bit # */
        ax0 = b#0000000000000111;   dm (SPORT0_RX_Channels0) = ax0;
            /*   ^15          00^   receive word enables: channel # == bit # */
        ax0 = b#0000000000000111;   dm (SPORT0_RX_Channels1) = ax0;
            /*   ^31          16^   receive word enables: channel # == bit # */


/*============== S Y S T E M   A N D   M E M O R Y   S T U F F ==============*/
        ax0 = b#0000111111111111;   dm (DM_Wait_Reg) = ax0;
            /*   |+-/+-/+-/+-/+-/- ! IOWAIT0
                ||  |  !  |       !
                ||  |  !  |       !
                ||  |  !  +------ | IOWAIT1
                ||  |  !          |
                ||  |  !          |
                ||  |  +--------- ! IOWAIT2
                ||  |             !
                ||  |             !
                ||  +------------ | IOWAIT3
                ||                |
                ||                |
                |+=============== ! DWAIT
                |                 !
                |                 !
                +---------------- 0
            */

        ax0 = b#0001000000000000;   dm (System_Control_Reg) = ax0;
            /*   +-/!||+-----/+-/- | program memory wait states
                |  !|||           | 0
                |  !|||           |
                |  !||+---------- 0
                |  !||            0
                |  !||            0
                |  !||            0
                |  !||            0
                |  !||            0
                |  !||            0
                |  !|+----------- SPORT1 1=serial port, 0=FI, FO, IRQ0, IRQ1,..
                |  !+------------ SPORT1 1=enabled, 0=disabled
                |  +============= SPORT0 1=enabled, 0=disabled
                +---------------- 0
                                  0
                                  0
            */



        ifc = b#00000011111111;         /* clear pending interrupt */
        nop;


        icntl = b#00000;
            /*    ||||+- | IRQ0: 0=level, 1=edge
                  |||+-- | IRQ1: 0=level, 1=edge
                  ||+--- | IRQ2: 0=level, 1=edge
                  |+---- 0
                  |----- | IRQ nesting: 0=disabled, 1=enabled
            */


        mstat = b#1000000;
            /*    ||||||+- | Data register bank select
                  |||||+-- | FFT bit reverse mode (DAG1)
                  ||||+--- | ALU overflow latch mode, 1=sticky
                  |||+---- | AR saturation mode, 1=saturate, 0=wrap
                  ||+----- | MAC result, 0=fractional, 1=integer
                  |+------ | timer enable
                  +------- | GO MODE
            */



/*******************************************************************************
 *
 *  ADSP 1847 Codec intialization
 *
 *******************************************************************************/

        /*   clear flag */
        ax0 = 1;
        dm(stat_flag) = ax0;

        /*   enable transmit interrupt */
        imask = b#0001000000;
            /*     |||||||||+ | timer
                  ||||||||+- | SPORT1 rec or IRQ0
                  |||||||+-- | SPORT1 trx or IRQ1
                  ||||||+--- | BDMA
                  |||||+---- | IRQE
                  ||||+----- | SPORT0 rec
                  |||+------ | SPORT0 trx
                  ||+------- | IRQL0
                  |+-------- | IRQL1
                  +--------- | IRQ2
            */


        ax0 = dm (i1, m1);          /* start interrupt */
        tx0 = ax0;

check_init:
        ax0 = dm (stat_flag);       /* wait for entire init */
        af = pass ax0;              /* buffer to be sent to */
        if ne jump check_init;      /* the codec            */

        ay0 = 2;
check_aci1:
        ax0 = dm (rx_buf);          /* once initialized, wait for codec */
        ar = ax0 and ay0;           /* to come out of autocalibration */
        if eq jump check_aci1;      /* wait for bit set */

check_aci2:
        ax0 = dm (rx_buf);          /* wait for bit clear */
        ar = ax0 and ay0;
        if ne jump check_aci2;
        idle;

        ay0 = 0xbf3f;               /* unmute left DAC */
        ax0 = dm (init_cmds + 6);
        ar = ax0 AND ay0;
        dm (tx_buf) = ar;
        idle;

        ax0 = dm (init_cmds + 7);   /* unmute right DAC */
        ar = ax0 AND ay0;
        dm (tx_buf) = ar;
        idle;


        ifc = b#00000011111111;     /* clear any pending interrupt */
        nop;

        imask = b#0000110000;       /* enable rx0 interrupt */
            /*    |||||||||+ | timer
                  ||||||||+- | SPORT1 rec or IRQ0
                  |||||||+-- | SPORT1 trx or IRQ1
                  ||||||+--- | BDMA
                  |||||+---- | IRQE
                  ||||+----- | SPORT0 rec
                  |||+------ | SPORT0 trx
                  ||+------- | IRQL0
                  |+-------- | IRQL1
                  +--------- | IRQ2
            */



/*------------------------------------------------------------------------------
 -
 -  wait for interrupt and loop forever
 -
 ------------------------------------------------------------------------------*/

talkthru:       
	idle;
   jump talkthru;


/*******************************************************************************
 *
 *  Interrupt service routines
 *
 *******************************************************************************/

/*------------------------------------------------------------------------------
 -
 -  receive interrupt 
 -
 ------------------------------------------------------------------------------*/
input_samples:
	ena sec_reg;						/* use shadow register bank */

   mx0 = dm(rx_buf+1);				/* input sample 1 */
   mx1 = dm(rx_buf+2);				/* input sample 2 */

	DM(left_input) = mx0;			/* save input samples */
	DM(right_input) = mx1;

	my0 = 0x4000;						/* sum input samples */
	mr = mx0*my0 (ss);
	mr = mr + mx1*my0 (rnd);
	
	call early_reflections;			/* early reflections */

	ar = mr1;

	call comb;							/* comb filters */

	my0 = mr1;

	call all_pass_filter;			/* all pass filter */

	mx0 = my1;							/* add reverb to input samples */
	my0 = 0x4000;
	mr1 = DM(left_input);
	mr = mr + mx0*my0 (rnd);
   dm(tx_buf+1) = mr1;				/* output sample 1 */

	mr1 = DM(right_input);
	mr = mr + mx0*my0 (rnd);
   dm(tx_buf+2) = mr1;				/* output sample 2 */

	dis sec_reg;		

	rti;

/*------------------------------------------------------------------------------
 -
 -  transmit interrupt used for Codec initialization
 -
 ------------------------------------------------------------------------------*/
next_cmd:
        ena sec_reg;
        ax0 = dm (i3, m1);          /* fetch next control word and */
        dm (tx_buf) = ax0;          /* place in transmit slot 0    */
        ax0 = i3;
        ay0 = init_cmds;
        ar = ax0 - ay0;
        if gt rti;                  /* rti if more control words still waiting */
        ax0 = 0xaf00;               /* else set done flag and */
        dm (tx_buf) = ax0;          /* remove MCE if done initialization */
        ax0 = 0;
        dm (stat_flag) = ax0;       /* reset status flag */
        rti;

irqe:   toggle fl1;
        rti;

/*------------ Early Reflections ----------------*/
/*																*/
/*	input		->		MR1									*/
/*																*/
/*	MR1		<-		output								*/
/*																*/
/*-----------------------------------------------*/
early_reflections:

	L2 = LENGTH(early_refl);
	I2 = DM(early_refl_ptr);		/* I2 is ptr to buffer */
	DM(I2,M1) = MR1;					/* write current sample to buffer */
	DM(early_refl_ptr) = I2;		/* save updated pointer */

	I5 = er_gain;						/* I5 is ptr to tap gains */
	I3 = er_length;					/* I3 is ptr to tap lengths */

	MX1 = DM(I3,M1);					/* get first delay tap length */	
	M2 = MX1;	
	MODIFY(I2,M2);						/* buffer pointer now points to first tap */

	MX1 = DM(I3,M1);					/* get next tap length */
	M2 = MX1;		
	MX0 = DM(I2,M2),					/* get first sample */ 
		MY0 = PM(I5,M7);				/* get first tap gain */

	CNTR = 17;							/* number of early reflections */ 
	DO er_sop UNTIL CE;				
			MX1 = DM(I3,M1);			/* get next tap length */
			M2 = MX1;					/* put tap length in M2 */
er_sop:	MR = MR + MX0*MY0 (SS),	/* compute sum of products */
				MX0 = DM(I2,M2),		/* get next sample */
				MY0 = PM(I5,M7);		/* get next tap gain */

	MR = MR + MX0*MY0 (RND);		/* last sample */
	IF MV SAT MR;

	RTS;
/*----------------- Comb Filter Routine -------------------*/
/*																			 */
/*	AR			<-		input												 */ 	
/*																			 */
/*	output	->		MR1 												 */ 	
/*																			 */
/*---------------------------------------------------------*/
comb:

	L3 = LENGTH(comb_output);
	I3 = comb_output;

	/* comb 1 */
	MY0 = 0x5071;				 		/* gf = Gf/(1+gl) -- comb feedback gain */
	MY1 = 0x2666;						/* gl -- low pass filter gain */

	L5 = COMB1_LENGTH;
	I5 = DM(comb1_ptr);			
	MX0 = PM(I5,M6);					/* read comb buffer -> output */

	MX1 = DM(comb1_lpf_state);		/* read previous low pass filter state */
	DM(I3,M1) = MX0,					/* save output */
		MR = MX0*MY0 (SS);			/* feedback comb output */
	MR = MR + MX1*MY1 (RND);		/* add low pass filter state */
	DM(comb1_lpf_state) = MR1;		/* replace with new filter state */

	MR1 = MX1;							/* get old low pass filter output */
	MY0 = 0x4676;						/* gi = 1/(1 + gf + gf*gl) */
	MR = MR + AR*MY0 (RND);			/* mac lpf output with input */
	PM(I5,M7) = MR1;					/* write sample to buffer */
	DM(comb1_ptr) = I5;				/* save updated pointer */


	/* comb 2 */
	MY0 = 0x4FD4;				 		/* gf = Gf/(1+gl) -- comb feedback gain */
	MY1 = 0x27AE;						/* gl -- low pass filter gain */

	L5 = COMB2_LENGTH;
	I5 = DM(comb2_ptr);			
	MX0 = DM(I5,M6);					/* read comb buffer -> output */

	MX1 = DM(comb2_lpf_state);		/* read previous low pass filter state */
	DM(I3,M1) = MX0,					/* save output */
		MR = MX0*MY0 (SS);			/* feedback comb output */
	MR = MR + MX1*MY1 (RND);		/* add low pass filter state */
	DM(comb2_lpf_state) = MR1;		/* replace with new filter state */

	MR1 = MX1;							/* get old low pass filter output */
	MY0 = 0x4671;						/* gi = 1/(1 + gf + gf*gl) */
	MR = MR + AR*MY0 (RND);			/* mac lpf output with input */
	DM(I5,M7) = MR1;					/* write sample to buffer */
	DM(comb2_ptr) = I5;				/* save updated pointer */


	/* comb 3 */
	MY0 = 0x4F39;				 		/* gf = Gf/(1+gl) -- comb feedback gain */
	MY1 = 0x28F6;						/* gl -- low pass filter gain */

	L5 = COMB3_LENGTH;
	I5 = DM(comb3_ptr);			
	MX0 = DM(I5,M6);					/* read comb buffer -> output */

	MX1 = DM(comb3_lpf_state);		/* read previous low pass filter state */
	DM(I3,M1) = MX0,					/* save output */
		MR = MX0*MY0 (SS);			/* feedback comb output */
	MR = MR + MX1*MY1 (RND);		/* add low pass filter state */
	DM(comb3_lpf_state) = MR1;		/* replace with new filter state */

	MR1 = MX1;							/* get old low pass filter output */
	MY0 = 0x4673;						/* gi = 1/(1 + gf + gf*gl) */
	MR = MR + AR*MY0 (RND);			/* mac lpf output with input */
	DM(I5,M7) = MR1;					/* write sample to buffer */
	DM(comb3_ptr) = I5;				/* save updated pointer */


	/* comb 4 */
	MY0 = 0x4EA1;				 		/* gf = Gf/(1+gl) -- comb feedback gain */
	MY1 = 0x2A3D;						/* gl -- low pass filter gain */

	L5 = COMB4_LENGTH;
	I5 = DM(comb4_ptr);			
	MX0 = DM(I5,M6);					/* read comb buffer -> output */

	MX1 = DM(comb4_lpf_state);		/* read previous low pass filter state */
	DM(I3,M1) = MX0,					/* save output */
		MR = MX0*MY0 (SS);			/* feedback comb output */
	MR = MR + MX1*MY1 (RND);		/* add low pass filter state */
	DM(comb4_lpf_state) = MR1;		/* replace with new filter state */

	MR1 = MX1;							/* get old low pass filter output */
	MY0 = 0x4672;						/* gi = 1/(1 + gf + gf*gl) */
	MR = MR + AR*MY0 (RND);			/* mac lpf output with input */
	DM(I5,M7) = MR1;					/* write sample to buffer */
	DM(comb4_ptr) = I5;				/* save updated pointer */


	/* comb 5 */
	MY0 = 0x4E0B;				 		/* gf = Gf/(1+gl) -- comb feedback gain */
	MY1 = 0x2B85;						/* gl -- low pass filter gain */

	L5 = COMB5_LENGTH;
	I5 = DM(comb5_ptr);			
	MX0 = PM(I5,M6);					/* read comb buffer -> output */

	MX1 = DM(comb5_lpf_state);		/* read previous low pass filter state */
	DM(I3,M1) = MX0,					/* save output */
		MR = MX0*MY0 (SS);			/* feedback comb output */
	MR = MR + MX1*MY1 (RND);		/* add low pass filter state */
	DM(comb5_lpf_state) = MR1;		/* replace with new filter state */

	MR1 = MX1;							/* get old low pass filter output */
	MY0 = 0x4672;						/* gi = 1/(1 + gf + gf*gl) */
	MR = MR + AR*MY0 (RND);			/* mac lpf output with input */
	PM(I5,M7) = MR1;					/* write sample to buffer */
	DM(comb5_ptr) = I5;				/* save updated pointer */


	/* comb 6 */
	MY0 = 0x4D77;				 		/* gf = Gf/(1+gl) -- comb feedback gain */
	MY1 = 0x2CCD;						/* gl -- low pass filter gain */

	L5 = COMB6_LENGTH;
	I5 = DM(comb6_ptr);			
	MX0 = PM(I5,M6);					/* read comb buffer -> output */

	MX1 = DM(comb6_lpf_state);		/* read previous low pass filter state */
	DM(I3,M1) = MX0,					/* save output */
		MR = MX0*MY0 (SS);			/* feedback comb output */
	MR = MR + MX1*MY1 (RND);		/* add low pass filter state */
	DM(comb6_lpf_state) = MR1;		/* replace with new filter state */

	MR1 = MX1;							/* get old low pass filter output */
	MY0 = 0x4672;						/* gi = 1/(1 + gf + gf*gl) */
	MR = MR + AR*MY0 (RND);			/* mac lpf output with input */
	PM(I5,M7) = MR1;					/* write sample to buffer */
	DM(comb6_ptr) = I5;				/* save updated pointer */


	I3 = comb_output;				/* sum outputs of comb filters */
	MY0 = 0x1555;						/* scale comb outputs by 1/6 */
	MX0 = DM(I3,M1);					/* load comb output */
	MR = MX0*MY0 (SS),				/* compute product */
		MX0 = DM(I3,M1);				/* load next comb output */
	MR = MR + MX0*MY0 (SS),			/* compute sum of products */
		MX0 = DM(I3,M1);				/* and so on ... */
	MR = MR + MX0*MY0 (SS), 
		MX0 = DM(I3,M1);
	MR = MR + MX0*MY0 (SS), 
		MX0 = DM(I3,M1);
	MR = MR + MX0*MY0 (SS), 
		MX0 = DM(I3,M1);
	MR = MR + MX0*MY0 (RND);

	RTS;
/*--------------- All Pass Filter Routine -----------------*/
/*																			 */
/*	MY0		<-		input												 */ 	
/*																			 */
/*	output	->		MY1 												 */ 	
/*																			 */
/*---------------------------------------------------------*/
all_pass_filter:

	I5 = DM(all_pass_ptr);
	L5 = LENGTH(all_pass);
	MX0 = 0x599A;						/* feedback gain */

	MR1 = DM(I5,M6);					/* load output of buffer */				
	MR = MR + MX0*MY0 (RND);		/* add to (feedback gain)*(input) */
	IF MV SAT MR;
	MY1 = MR1;							/* output of all pass in MY1 */				

	MR1 = MY0;							/* put input of all pass in MR1 */
	MR = MR - MX0*MY1 (RND);		/* input - (feedback gain)*(output) */
	IF MV SAT MR;
	DM(I5,M7) = MR1;					/* save to input of buffer */
	DM(all_pass_ptr) = I5;				

	RTS;
/*---------------------------------------------------------*/

