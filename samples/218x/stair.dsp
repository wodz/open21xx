/******************************************************************************
 *
 *  This program will play Stairway To Heaven
 *  This sample program is organized into the following sections:
 *
 *  Constant Declarations
 *  Interrupt vector table
 *  ADSP 2181 intialization
 *  ADSP 1847 Codec intialization
 *  Interrupt service routines
 ******************************************************************************/



/******************************************************************************
 *
 *  Constant Declarations
 *
 ******************************************************************************/

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

.section/dm data0;
.var/circ                tx_buf[3] =     /* Cmd + L data + R data    */
	{ 0xc000, 0x0000, 0x0000 }; /* Initially set MCE        */

.var/circ                init_cmds[13] =
{
        0xc04f,     /*
                        Left input control reg
                        b7-6: 0=left line 1
                              1=left aux 1
                              2=left line 2
                              3=left line 1 post-mixed loopback
                        b5-4: res
                        b3-0: left input gain x 1.5 dB
                    */
        0xc14f,     /*
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
        0xc85c,     /*
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
        0xcd00 };   /*
                        digital mix control reg
                        b7-2: attenuation x 1.5 dB
                        b1  : res
                        b0  : 1=digital mix enabled
                    */

.var/circ                string1[32] =
	     { 218, 183, 146, 109,   97, 183, 231,  97,   92, 146, 183,  92, 
               130, 163, 218, 163,  146, 183, 218, 183,  146, 183, 218, 183, 
               245, 218, 218, 10,    10,  10,  10,  10 };
.var/circ                string2[32] =
	     { 218,  10,  10,  10,  231,  10,  10, 231,  245,  10,  10, 245, 
               327,  10,  10,  10,  275,  10,  10,  10,   10,  10,  10,  10,
               327, 183, 183,  10,   10, 436, 275, 291 };

.section/dm bssdata0 SHT_NOBITS;
.var/circ                    l_buff[600];     /* Data buffer,string 1*/
.var/circ                    l_buff2[600];    /* Data buffer,string 2*/
.var/circ                    l_buff3[600];    /* Data buffer,string 3*/
.var/circ                    l_buff4[600];    /* Data buffer,string 4*/
.var/circ                    l_buff5[600];    /* Data buffer,string 5*/
.var/circ                    l_buff6[600];    /* Data buffer,string 6*/
.var/circ                rx_buf[3];      /* Status + L data + R data */
.var/circ                string3[32];
.var/circ                string4[32];
.var/circ                string5[32];
.var/circ                string6[32];

.var                         stat_flag;
.var                         save_1i;
.var                         save_1l;
.var                         note_1;
.var                         save_2i;
.var                         save_2l;
.var                         note_2;
.var                         save_3i;
.var                         save_3l;
.var                         note_3;
.var                         save_4i;
.var                         save_4l;
.var                         note_4;
.var                         save_5i;
.var                         save_5l;
.var                         note_5;
.var                         save_6i;
.var                         save_6l;
.var                         note_6;
.var                         start_flag;

/*******************************************************************************
 *
 *  Interrupt vector table
 *
 *******************************************************************************/
.section/PM interrupts;
        jump start;  rti; rti; rti;     /*00: reset */
        rti;         rti; rti; rti;     /*04: IRQ2 */
        rti;         rti; rti; rti;     /*08: IRQL1 */
        rti;         rti; rti; rti;     /*0c: IRQL0 */

        ar = dm(stat_flag);             /*10: SPORT0 tx */
        ar = pass ar;
        if eq rti;
        jump next_cmd;

        jump input_samples;             /*14: SPORT0 rx */
        rti; rti; rti;

        rti;         rti; rti; rti;     /*18: IRQE */
        rti;         rti; rti; rti;     /*1c: BDMA */
        rti;         rti; rti; rti;     /*20: SPORT1 tx or IRQ1 */
        rti;         rti; rti; rti;     /*24: SPORT1 rx or IRQ0 */
        jump random; rti; rti; rti;     /*28: timer */
        rti;         rti; rti; rti;     /*2c: power down */


/*******************************************************************************
 *
 *  ADSP 2181 intialization
 *
 *******************************************************************************/
.section/PM program0;
start:
        ay0 = 0;
        dm(start_flag) = ay0;
        i2 = rx_buf;    /* Used for receive autobuffering */
        l2 = LENGTH(rx_buf);
        i3 = tx_buf;    /* Used for transmit autobuffering */
        l3 = LENGTH(tx_buf);
        i0 = init_cmds;     /* Used for 1847 commands */
        l0 = LENGTH(init_cmds);
        i1 = string6;
        dm(note_6) = i1;
        i1 = string5;
        dm(note_5) = i1;
        i1 = string4;
        dm(note_4) = i1;
        i1 = string3;
        dm(note_3) = i1;
        i1 = string2;
        dm(note_2) = i1;
        i1 = string1;
        dm(note_1) = i1;
        l1 = LENGTH(string1);
      
        m1 = 1;
        m3 = 1;      /* Used for Autobuffering */

/*================== S E R I A L   P O R T   #0   S T U F F ==================*/
        ax0 = b#0000011110101111;   dm (SPORT0_Autobuf) = ax0;
            /*   |||!|-/!/|-/|/|+- receive autobuffering 0=off, 1=on
                |||!|  ! |  | +-- transmit autobuffering 0=off, 1=on
                |||!|  ! |  +---- | receive m?
                |||!|  ! |        | m3
                |||!|  ! +------- ! receive i?
                |||!|  !          ! i2
                |||!|  !          !
                |||!|  +========= | transmit m?
                |||!|             | m3
                |||!+------------ ! transmit i?
                |||!              ! i3
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


/*================== S E R I A L   P O R T   #1   S T U F F ==================*/
        ax0=0;      dm(SPORT1_Autobuf)=ax0;     /* autobuffering disabled */
        ax0=0;      dm(SPORT1_RFSDIV)=ax0;      /* RFSDIV not used */
        ax0=0;      dm(SPORT1_SCLKDIV)=ax0;     /* SCLKDIV not used */
        ax0=0;      dm(SPORT1_Control_Reg)=ax0; /* ctrl reg functions disabled */


/*================ T I M E R   S T U F F ==================*/
        ax0=0;      dm(TSCALE)=ax0;             /* timer not being used */
        ax0=0;      dm(TCOUNT)=ax0;
        ax0=0;      dm(TPERIOD)=ax0;

/*============== S Y S T E M   A N D   M E M O R Y   S T U F F ==============*/
        ax0 = b#0000000000000000;   dm (DM_Wait_Reg) = ax0;
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
                |  !|+----------- SPORT1 1=serial port, 1=FI, FO, IRQ0, IRQ1,..
                |  !+------------ SPORT1 1=enabled, 0=disabled
                |  +============= SPORT0 1=enabled, 0=disabled
                +---------------- 0
                                  0
                                  0
            */


        ifc = b#00000011111111;         /* clear pending interrupt */
        nop;


        icntl = b#00000;
            /*     ||||+- | IRQ0: 0=level, 1=edge
                  |||+-- | IRQ1: 0=level, 1=edge
                  ||+--- | IRQ2: 0=level, 1=edge
                  |+---- 0
                  |----- | IRQ nesting: 0=disabled, 1=enabled
            */


        mstat = b#1000000;
            /*     ||||||+- | Data register bank select
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


        ax0 = dm (i3, m1);          /* start interrupt */
        tx0 = ax0;

check_init:
        ax0 = dm (stat_flag);       /* wait for entire init */
        af = pass ax0;              /* buffer to be sent to */
        if ne jump check_init;      /* the codec            */

        ay0 = 2;

check_acih:
        ax0 = dm (rx_buf);          /* once initialized, wait */
        ar = ax0 and ay0;           /* for codec to come out  */
        if eq jump check_acih;       /* of autocalibration     */

check_acil:
        ax0 = dm (rx_buf);          /* once initialized, wait */
        ar = ax0 and ay0;           /* for codec to come out  */
        if ne jump check_acil;       /* of autocalibration     */

        /*idle;*/

        ay0 = 0xbf3f;               /* unmute left DAC */
        ax0 = dm (init_cmds + 6);
        ar = ax0 AND ay0;
        dm (tx_buf) = ar;
        idle;

        ax0 = dm (init_cmds + 7);   /* unmute right DAC */
        ar = ax0 AND ay0;
        dm (tx_buf) = ar;
        idle;

        ax1 = 0x804f;               /* control word to clear over-range flags */
        dm (tx_buf) = ax1;

/* Set up registers for data buffer used to hold samples */        
        i5 = l_buff6;
        l5 = LENGTH(l_buff6);
        dm(save_6i) = i5;
        dm(save_6l) = l5;
        i5 = l_buff5;
        l5 = LENGTH(l_buff5);
        dm(save_5i) = i5;
        dm(save_5l) = l5;
        i5 = l_buff4;
        l5 = LENGTH(l_buff4);
        dm(save_4i) = i5;
        dm(save_4l) = l5;
        i5 = l_buff3;
        l5 = LENGTH(l_buff3);
        dm(save_3i) = i5;
        dm(save_3l) = l5;
        i5 = l_buff2;
        l5 = LENGTH(l_buff2);
        dm(save_2i) = i5;
        dm(save_2l) = l5;
        i5 = l_buff;
        l5 = LENGTH(l_buff);
        dm(save_1i) = i5;
        dm(save_1l) = l5;

        m5 = 1; m6 = -1;

/* Set up timer for tempo */        
        ax0 = 0xff;
        dm(TSCALE) = ax0;
        ax0 = 0xffff;
        dm(TPERIOD) = ax0;
        dm(TCOUNT) = ax0;
        ena timer;


        ifc = b#00000011111111;     /* clear any pending interrupt */
        nop;

        imask = b#0000100001;       /* enable rx0 interrupt */
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
        reset flag_out;
        af = pass -1;

/*------------------------------------------------------------------------------
 -
 -  wait for interrupt and loop forever
 -
 ------------------------------------------------------------------------------*/

talkthru:       idle;
        jump talkthru;




/*******************************************************************************
 *
 *  Interrupt service routines
 *
 *******************************************************************************/

/*------------------------------------------------------------------------------
 -
 -  receive interrupt used for loopback
 -
 ------------------------------------------------------------------------------*/
input_samples:    /* sport0 receive interrupt */
        se = -1;
        ar = dm(i5,m5);       /* get sample and point to next */
        ay0 = dm(i5,m6);      /* get next sample and point back to last */
        ar = ar + ay0;
        sr = ashift ar (hi);
        dm(i5,m5) = sr1;      /* put back average of two samples */
        dm(save_1i) = i5;
        dm(save_1l) = l5;

        i5 = dm(save_2i);
        l5 = dm(save_2l);
        ar = dm(i5,m5);       /* get sample and point to next */
        ay0 = dm(i5,m6);      /* get next sample and point back to last */
        ar = ar + ay0;
        ay0 = sr1;             /* save last note */  
        sr = ashift ar (hi);
        dm(i5,m5) = sr1;      /* put back average of two samples */
        dm(save_2i) = i5;
        dm(save_2l) = l5;

        i5 = dm(save_1i);
        l5 = dm(save_1l);

        
/*        af = pass af;     */
/*        if gt jump right_out;   */
/*        dm(tx_buf+1) = sr1;    */
/*        toggle FLAG_OUT;          */
/*        rti;                        */

right_out:
        ar = sr1 + ay0;         /* add first note to second note */
        sr = ashift ar (hi);
        ay0 = dm(start_flag);
        ar = 0;
        none = ar - ay0;
        if ne jump out_ok;
        sr1 = 0;
out_ok: dm(tx_buf+1) = sr1;        
        dm(tx_buf+2) = sr1;
/*         toggle FLAG_OUT;	*/	/* messes up ez21 */
        rti;


/*------------------------------------------------------------------------------
 -
 -  transmit interrupt used for Codec initialization
 -
 ------------------------------------------------------------------------------*/
next_cmd:
        ena sec_reg;
        ax0 = dm (i0, m1);          /* fetch next control word and */
        dm (tx_buf) = ax0;          /* place in transmit slot 0    */
        ax0 = i0;
        ay0 = init_cmds;
        ar = ax0 - ay0;
        if gt rti;                  /* rti if more control words still waiting */
        ax0 = 0x804f;               /* else set done flag and */
        dm (tx_buf) = ax0;          /* remove MCE if done initialization */
        ax0 = 0;
        dm (stat_flag) = ax0;       /* reset status flag */
        rti;


random: 
        ay0 = 10;
        dm(start_flag) = ay0;
        ay0 = dm(i1, m1);       /* get buffer length from tone table */
        dm(note_1) = i1;

        /* check for length reg of 10, rest and no note */
        ar = 10;       /* put length into alu */
        none = ar - ay0;
        if ne jump do_note;
        jump note2;


do_note:        
        MY1=25;                                 /*Upper half of a*/
        MY0=26125;                              /*Lower half of a*/

        l5 = ay0;               /* load length into lenth register */
        i5 = l_buff;           /* reset pointer to start of buffer */


do_rand: cntr = l5;
        DO randloop_l UNTIL CE;
                DM(i5,m5)=SR1, MR=SR0*MY1(UU);  /*a(hi)*x(lo)*/
                MR=MR+SR1*MY0(UU);              /*a(hi)*x(lo) + a(lo)*x(hi)*/
                SI=MR1;
                MR1=MR0;
                MR2=SI;
                MR0=0xFFFE;                     /*c=32767, left-shifted by 1*/
                MR=MR+SR0*MY0(UU);              /*(above) + a(lo)*x(lo) + c*/
                SR=ASHIFT MR2 BY 15 (HI);
                SR=SR OR LSHIFT MR1 BY -1 (HI); /*right-shift by 1*/
randloop_l:       SR=SR OR LSHIFT MR0 BY -1 (LO);
        dm(save_1i) = i5;        
        dm(save_1l) = l5;

note2:  
        i1 = dm(note_2);
        ay0 = dm(i1, m1);       /* get buffer length from tone table */
        dm(note_2) = i1;
        /* check for length reg of 10, rest and no note */
        ar = 10;       /* put length into alu */
        none = ar - ay0;
        if ne jump do_note2;
        i1 = dm(note_1);
        rti;
        
do_note2:        
        MY1=25;                                 /*Upper half of a*/
        MY0=26125;                              /*Lower half of a*/

        l5 = ay0;               /* load length into lenth register */
        i5 = l_buff2;           /* reset pointer to start of buffer */

do_rand2: cntr = l5;
        DO randloop_2 UNTIL CE;
                DM(i5,m5)=SR1, MR=SR0*MY1(UU);  /*a(hi)*x(lo)*/
                MR=MR+SR1*MY0(UU);              /*a(hi)*x(lo) + a(lo)*x(hi)*/
                SI=MR1;
                MR1=MR0;
                MR2=SI;
                MR0=0xFFFE;                     /*c=32767, left-shifted by 1*/
                MR=MR+SR0*MY0(UU);              /*(above) + a(lo)*x(lo) + c*/
                SR=ASHIFT MR2 BY 15 (HI);
                SR=SR OR LSHIFT MR1 BY -1 (HI); /*right-shift by 1*/
randloop_2:       SR=SR OR LSHIFT MR0 BY -1 (LO);
        dm(save_2i) = i5;
        dm(save_2l) = l5;
        i5 = dm(save_1i);
        l5 = dm(save_1l);

        i1 = dm(note_1);
        nop;
        af = pass af;
        if gt jump other_chan;
        af = pass 1;
        rti;

other_chan:
        af = pass -1;

        rti;
