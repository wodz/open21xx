/*
 * 219x.dsp
 *
 * Part of the Open21xx assembler toolkit
 *
 * Copyright (C) 2002 by Keith B. Clifford
 *
 * The Open21xx toolkit is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as published
 * by the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * The Open21xx toolkit is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Open21xx toolkit; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/*
 * This file contains a cross section of assembler instructions and
 * directives for verifying the assembler output.
 */
    .extern extpm, extdm;
	.list_data;
	.list_datfile;
	.section/data data0;
	/* first .var is circular regression test */
	.var/circ some_data[3];			// =0 0x0 0x0 0x0

	.var = {4, 5, 6};			// 4 5 6
	.var = 7, 8, 9;				// 7 8 9
	.var = {"filename.dat"};		// 0 1 2 3 4 5 6 7 8
	.var = "filename.dat";			// 0 1 2 3 4 5 6 7 8
	.var varName2 = {10};			// 10
	.var varName3 = 11;			// 11
	.var bufName[5] = {12, 13, 14};		// 12 13 14 0 0
	.var bufName2[5] = 15, 16, 17;		// 15 16 17 0 0
	.var bufName3[] = {18, 19, 20};		// 18 19 20
	.var bufName4[] = 21, 22, 23;		// 21 22 23
	.var bufName5[9] = {"filename.dat"};	// 0 1 2 3 4 5 6 7 8
	.var bufName6[9] = "filename.dat";	// 0 1 2 3 4 5 6 7 8
	.var bufName7[] = {"filename.dat"};	// 0 1 2 3 4 5 6 7 8
	.var bufName8[] = "filename.dat";	// 0 1 2 3 4 5 6 7 8

	// multiple var declarations 
	.VAR ={24}, varName4 ={25};		// 24 25
	.VAR varName6 ={26},varName7 ={27};	// 26 27
	.VAR bufName9 [5]={28, 29, 30},		// 28 29 30 0 0
	     bufName10[]={31, 32, 33, 34};	// 31 32 33 34
	.VAR bufName11[9]={"filename.dat"},	// 0 1 2 3 4 5 6 7 8
     		bufName12[]={"filename.dat"};	// 0 1 2 3 4 5 6 7 8

	.VAR symbolString [15]= 'initString' , 0;	// 'i' 'n' 'i' 't' 'S' 't' 'r' 'i' 'n' 'g' 0 0 0 0 0 
	.VAR symbolString2 [ ] = 'initString' , 0 ;	// 'i' 'n' 'i' 't' 'S' 't' 'r' 'i' 'n' 'g' 0
	.var x [17]= 'Hello world!' ,0;		// 'H' 'e' 'l' 'l' 'o' ' ' 'w' 'o' 'r' 'l' 'd' '!' 0 0 0 0 0
	.var x2 [] = 'Hello world!', 0;		// 'H' 'e' 'l' 'l' 'o' ' ' 'w' 'o' 'r' 'l' 'd' '!' 0
	.var x4[]= '\n\t\v\b\r\f\a\\\?\"\'\365\xc3\0\123\xab',0;	// '\n' '\t' '\v' '\b' '\r' '\f' '\a' '\\' '\?' '\"' '\'' 0365 0xc3 0 0123 0xab 0
    .var x5[]= '\n','\365','\xc3','\0','\123','\xab'; // '\n' 0365 0xc3 0 0123 0xab

	.var datalimit1={-0x8000},		// 0x8000
	     datalimit2={0},			// 0
	     datalimit3={0x7fff},		// 0x7fff
	     datalimit4={0xffff};		// 0xffff
	.var/circ roundbuf[5] ={0x1234,0x5678,0x9abc,0xdef0,0x1234};	// 0x1234 0x5678 0x9abc 0xdef0 0x1234
	
	/* expression evaluation test */
	.var math1 = { 1234 + 3456 };		// 4690
	.var math2 = { 1234 - 4321 };		// 0xf3f1
	.var math3 = { 127 * 112 };		// 14224
	.var math4 = { 48792 / 213 };		// 229
	.var math5 = { 48792 % 213 };		// 15
	.var math6 = { -9321 };			// 0xdb97
	.var math7 = { 1+3*9-31/2%4 };		// 25
	.var math8 = { (1+3)*(9-31)/2%4 };	// 0

	.var shift1 = { 16 << 8 };		// 4096
	.var shift2 = { 4096 >> 8 };		// 16

	.var rel1 = { 1234 == 1234 };		// 1
	.var rel2 = { 1234 == 1233 };		// 0
	.var rel3 = { 1234 != 1233 };		// 1
	.var rel4 = { 1234 != 1234 };		// 0
	.var rel5 = { 1234 > 1235 };		// 0
	.var rel6 = { 1234 > 1234 };		// 0
	.var rel7 = { 1234 > 1233 };		// 1
	.var rel8 = { 1234 >= 1235 };		// 0
	.var rel9 = { 1234 >= 1234 };		// 1
	.var rel10 = { 1234 >= 1233 };		// 1
	.var rel11 = { 1234 < 1235 };		// 1
	.var rel12 = { 1234 < 1234 };		// 0
	.var rel13 = { 1234 < 1233 };		// 0
	.var rel14 = { 1234 <= 1235 };		// 1
	.var rel15 = { 1234 <= 1234 };		// 1
	.var rel16 = { 1234 <= 1233 };		// 0

	.var logical1 = { 23 && 44 };		// 1
	.var logical2 = { 98 && 0 };		// 0
	.var logical3 = { 0 && 57 };		// 0
	.var logical4 = { 0 && 0 };		// 0
	.var logical5 = { 23 || 44 };		// 1
	.var logical6 = { 98 || 0 };		// 1
	.var logical7 = { 0 || 57 };		// 1
	.var logical8 = { 0 || 0 };		// 0
	.var logical9 = { !0 };			// 1
	.var logical10 = { !1 };		// 0
	.var logical11 = { !293 };		// 0

	.var bit1 = { 0xa5a5 & 0x80ca };	// 0x8080
	.var bit2 = { 0xa5c1 | 0x1c5a };	// 0xbddb
	.var bit3 = { 0x139d ^ 0x9a45 };	// 0x89d8
	.var bit4 = { ~0x83d1 };		// 0x7c2e

	.var mixed1 = { 5 > 3 && 2 * 3 -1 <= 5 };	// 1

    .var addr_expdm[] = { 0, 1, 2, 3, -5};       // 0 1 2 3 0xfffb
    .var = {-3+extpm};                                      // 0x0000
    .var = {2+extdm};                                       // 0x0000

	.section/code program0;
	.var / init24 q1=0x123456;		// = 0 0x123456
	.align 8;				// = 8
	.var/circ/init24 q3={0x12345}, q4={123};	// =8 0x12345 123
	.var q2=0x4321;				// 0x432100
	.align 32;
	.var q5;				// = 32 0
	.align 16;
	.var q6;				// = 48 0
	.var/circ q7[20]={1,2,3};		// 0x100 0x200 0x300 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
	.var codelimit1={-0x8000},		// (0x8000<<8)
	     codelimit2={0},			// 0
	     codelimit3={0x7fff},		// (0x7fff<<8)
	     codelimit4={0xffff};		// (0xffff<<8)
	.var/init24 codelimit5={-0x800000},	// 0x800000
		    codelimit6={0},		// 0
		    codelimit7={0x7fffff},	// 0x7fffff
	 	    codelimit8={0xffffff};	// 0xffffff

    .var addr_exppm[] = { 0, 1, 2, 3, -5};       // 0x000000 0x000100 0x000200 0x000300 0xfffb00
    .var = -3+extpm;                                        // 0x000000
    .var = 2+extdm;                                         // 0x000000
    .var/init24 addr_exppm24[] = { 0, 1, 2, 3, -5};  // 0x000000 0x000001 0x00002 0x000003 0xfffffb
    .var/init24 = -3+extpm;                                 // 0x000000
    .var/init24 = 2+extdm;                                  // 0x000000

add_symbol:
	/* add / add with carry */
	ar = ax0+ay0;				// 0x22600f
	ar = ax1+ay0;				// 0x22610f
	ar = ar+ay0;				// 0x22620f
	ar = mr0+ay0;				// 0x22630f
	ar = mr1+ay0;				// 0x22640f
	ar = mr2+ay0;				// 0x22650f
	ar = sr0+ay0;				// 0x22660f
	ar = sr1+ay0;				// 0x22670f
	ar = ax0+ay1;				// 0x22680f
	ar = ax0+af;				// 0x22700f
	af = ax0+ay0;				// 0x26600f
	ar = ax0+c;				// 0x22580f
	ar = ax0+ay0+c;				// 0x22400f
	ar = ax0+0;				// 0x22780f
	ar = ax0+1;				// 0x22601f
	ar = ax0+2;				// 0x22605f
	ar = ax0+4;				// 0x22609f
	ar = ax0+8;				// 0x2260df
	ar = ax0+16;				// 0x22681f
	ar = ax0+32;				// 0x22685f
	ar = ax0+64;				// 0x22689f
	ar = ax0+128;				// 0x2268df
	ar = ax0+0x100;				// 0x22701f
	ar = ax0+512;				// 0x22705f
	ar = ax0+1024;				// 0x22709f
	ar = ax0+2048;				// 0x2270df
	ar = ax0+4096;				// 0x22781f
	ar = ax0+8192;				// 0x22785f
	ar = ax0+16384;				// 0x22789f
	ar = ax0+32767;				// 0x2278ff
	ar = ax0+-2;				// 0x22603f
	ar = ax0+-3;				// 0x22607f
	ar = ax0+-5;				// 0x2260bf
	ar = ax0+-9;				// 0x2260ff
	ar = ax0+-17;				// 0x22683f
	ar = ax0+-33;				// 0x22687f
	ar = ax0+-65;				// 0x2268bf
	ar = ax0+-129;				// 0x2268ff
	ar = ax0+-257;				// 0x22703f
	ar = ax0+-513;				// 0x22707f
	ar = ax0+-1025;				// 0x2270bf
	ar = ax0+-2049;				// 0x2270ff
	ar = ax0+-4097;				// 0x22783f
	ar = ax0+-8193;				// 0x22787f
	ar = ax0+-16385;			// 0x2278bf
	ar = ax0+-32768;			// 0x2278df
	ar = ax0+0xfffe;			// 0x22603f
	ar = ax0+0xfffd;			// 0x22607f
	ar = ax0+0xfffb;			// 0x2260bf
	ar = ax0+0xfff7;			// 0x2260ff
	ar = ax0+0xffef;			// 0x22683f
	ar = ax0+0xffdf;			// 0x22687f
	ar = ax0+0xffbf;			// 0x2268bf
	ar = ax0+0xff7f;			// 0x2268ff
	ar = ax0+0xfeff;			// 0x22703f
	ar = ax0+0xfdff;			// 0x22707f
	ar = ax0+0xfbff;			// 0x2270bf
	ar = ax0+0xf7ff;			// 0x2270ff
	ar = ax0+0xefff;			// 0x22783f
	ar = ax0+0xdfff;			// 0x22787f
	ar = ax0+0xbfff;			// 0x2278bf
	ar = ax0+0x8000;			// 0x2278df

	/* same as ar = ax0 - -constant */
	ar = ax0+3;				// 0x22e07f
	ar = ax0+5;				// 0x22e0bf
	ar = ax0+9;				// 0x22e0ff
	ar = ax0+17;				// 0x22e83f
	ar = ax0+33;				// 0x22e87f
	ar = ax0+65;				// 0x22e8bf
	ar = ax0+129;				// 0x22e8ff
	ar = ax0+257;				// 0x22f03f
	ar = ax0+513;				// 0x22f07f
	ar = ax0+1025;				// 0x22f0bf
	ar = ax0+2049;				// 0x22f0ff
	ar = ax0+4097;				// 0x22f83f
	ar = ax0+8193;				// 0x22f87f
	ar = ax0+16385;				// 0x22f8bf
	ar = ax0+32768;				// 0x2278df

	ar = ax0+0+c;				// 0x22580f
	ar = ax0+1+c;				// 0x22401f
	ar = ax0+2+c;				// 0x22405f
	ar = ax0+4+c;				// 0x22409f
	ar = ax0+8+c;				// 0x2240df
	ar = ax0+16+c;				// 0x22481f
	ar = ax0+32+c;				// 0x22485f
	ar = ax0+64+c;				// 0x22489f
	ar = ax0+128+c;				// 0x2248df
	ar = ax0+0x100+c;			// 0x22501f
	ar = ax0+512+c;				// 0x22505f
	ar = ax0+1024+c;			// 0x22509f
	ar = ax0+2048+c;			// 0x2250df
	ar = ax0+4096+c;			// 0x22581f
	ar = ax0+8192+c;			// 0x22585f
	ar = ax0+16384+c;			// 0x22589f
	ar = ax0+32767+c;			// 0x2258ff
	ar = ax0+-2+c;				// 0x22403f
	ar = ax0+-3+c;				// 0x22407f
	ar = ax0+-5+c;				// 0x2240bf
	ar = ax0+-9+c;				// 0x2240ff
	ar = ax0+-17+c;				// 0x22483f
	ar = ax0+-33+c;				// 0x22487f
	ar = ax0+-65+c;				// 0x2248bf
	ar = ax0+-129+c;			// 0x2248ff
	ar = ax0+-257+c;			// 0x22503f
	ar = ax0+-513+c;			// 0x22507f
	ar = ax0+-1025+c;			// 0x2250bf
	ar = ax0+-2049+c;			// 0x2250ff
	ar = ax0+-4097+c;			// 0x22583f
	ar = ax0+-8193+c;			// 0x22587f
	ar = ax0+-16385+c;			// 0x2258bf
	ar = ax0+-32768+c;			// 0x2258df

above_add_symbol:
	// the above with conditions
	if eq ar = ax0+ay0;   			// 0x226000
	if ne ar = ax0+ay0;   			// 0x226001
	if gt ar = ax0+ay0;   			// 0x226002
	if le ar = ax0+ay0;   			// 0x226003
	if lt ar = ax0+ay0;   			// 0x226004
	if ge ar = ax0+ay0;   			// 0x226005
	if av ar = ax0+ay0;   			// 0x226006
	if not av ar = ax0+ay0; 		// 0x226007
	if ac ar = ax0+ay0;   			// 0x226008
	if not ac ar = ax0+ay0; 		// 0x226009
	if swcond ar = ax0+ay0;   		// 0x22600a
	if not swcond ar = ax0+ay0;		// 0x22600b
	if mv ar = ax0+ay0;   			// 0x22600c
	if not mv ar = ax0+ay0; 		// 0x22600d
	if not ce ar = ax0+ay0; 		// 0x22600e

subtract_symbol:
	/* subtract x-y / subtract x-y with borrow */
	af = ax1-af;				// 0x26f10f
	af = ax1-af+c-1;			// 0x26d10f
	af = ax1+c-1;				// 0x26d90f
	af = ax1-0;				// 0x26f90f
	af = ax1--32768;			// 0x26f9df
	af = ax1-32767+c-1;			// 0x26d9ff
	af = ax1-1;				// 0x26e11f
	af = ax1-2;				// 0x26e15f
	af = ax1-4;				// 0x26e19f
	af = ax1-8;				// 0x26e1df
	af = ax1-16;				// 0x26e91f
	af = ax1-32;				// 0x26e95f
	af = ax1-64;				// 0x26e99f
	af = ax1-128;				// 0x26e9df
	af = ax1-256;				// 0x26f11f
	af = ax1-512;				// 0x26f15f
	af = ax1-1024;				// 0x26f19f
	af = ax1-2048;				// 0x26f1df
	af = ax1-4096;				// 0x26f91f
	af = ax1-8192;				// 0x26f95f
	af = ax1-16384;				// 0x26f99f
	af = ax1-32767;				// 0x26f9ff
	af = ax1--2;				// 0x26e13f
	af = ax1--3;				// 0x26e17f
	af = ax1--5;				// 0x26e1bf
	af = ax1--9;				// 0x26e1ff
	af = ax1--17;				// 0x26e93f
	af = ax1--33;				// 0x26e97f
	af = ax1--65;				// 0x26e9bf
	af = ax1--129;				// 0x26e9ff
	af = ax1--257;				// 0x26f13f
	af = ax1--513;				// 0x26f17f
	af = ax1--1025;				// 0x26f1bf
	af = ax1--2049;				// 0x26f1ff
	af = ax1--4097;				// 0x26f93f
	af = ax1--8193;				// 0x26f97f
	af = ax1--16385;			// 0x26f9bf
	af = ax1--32768;			// 0x26f9df

	/* the same as af = ax1 + -constant */
	af = ax1-3;				// 0x26617f
	af = ax1-5;				// 0x2661bf
	af = ax1-9;				// 0x2661ff
	af = ax1-17;				// 0x26693f
	af = ax1-33;				// 0x26697f
	af = ax1-65;				// 0x2669bf
	af = ax1-129;				// 0x2669ff
	af = ax1-257;				// 0x26713f
	af = ax1-513;				// 0x26717f
	af = ax1-1025;				// 0x2671bf
	af = ax1-2049;				// 0x2671ff
	af = ax1-4097;				// 0x26793f
	af = ax1-8193;				// 0x26797f
	af = ax1-16385;				// 0x2679bf
	af = ax1-32768;				// 0x26f9df

subtract_yx_symbol:
	// subtract y-x / subtract y-x with borrow */
	ar = ay0-ax0;				// 0x23200f
	ar = ay0-ax0+c-1;			// 0x23400f
	ar = -ax0;				// 0x23380f
	ar = -ax0+c-1;				// 0x23580f
	ar = -ax0+2;				// 0x23205f
	ar = -ax0+-5+c-1;			// 0x2340bf

and_or_xor_symbol:
	// and or xor
	ar = mr0 and ay0;			// 0x23830f
	ar = mr1 or ay1;			// 0x23ac0f
	af = mr2 xor af;			// 0x27d50f
	ar = sr0 and 2;				// 0x23865f
	ar = sr1 or -0x5;			// 0x23a7bf
	af = ar xor 0x4000;			// 0x27da9f

test_set_clear_toggle_bit_symbol:
	// test bit, set bit, clear bit, toggle bit
	ar = tstbit 1 of ax0;			// 0x23805f
	ar = setbit 2 of ax0;			// 0x23a09f
	ar = clrbit 3 of ax0;			// 0x2380ff
	ar = tglbit 4 of ax0;			// 0x23c81f

pass_clear_symbol:
	/* pass / clear */
	ar = pass -1;				// 0x23180f
	ar = pass 0;				// 0x22180f
	ar = pass 1;				// 0x22380f
	ar = pass ax0;				// 0x22780f
	ar = pass ay1;				// 0x22080f
	ar = pass 63;				// 0x23089f
	ar = pass 64;				// 0x22089f
	ar = pass 65;				// 0x22289f
	ar = pass 32766;			// 0x2318ff
	ar = pass 32767;			// 0x2218ff
	ar = pass -4096;			// 0x22383f
	ar = pass -4097;			// 0x22183f
	ar = pass -4098;			// 0x23183f
	ar = pass -32767;			// 0x2238df
	ar = pass -32768;			// 0x2218df

negate_symbol:
	/* negate */
	ar = -ax0;				// 0x23380f
	af = -ay1;				// 0x26a80f

not_symbol:
	/* not */
	ar = NOT ax1;				// 0x23610f
	af = NOT ay1;				// 0x26880f

absolute_value_symbol:
	// absolute value
	if eq ar = abs ar;			// 0x23e200
	if ne af = abs mr2;			// 0x27e501
	
increment_symbol:
	// increment
	if not ac ar = af +1;			// 0x223009

decrement_symbol:
	// decrement
	if not mv af = ay0-1;			// 0x27000d

divide_symbol:
	// divide
	divs AY1, AX0;				// 0x038800
	divs af, AX0;				// 0x039000
	divs AY1, AX1;				// 0x038900
	divs AF, AX1;				// 0x039100
	divs AY1, AR;				// 0x038a00
	divs AF, AR;				// 0x039200
	divs AY1, MR2;				// 0x038d00
	divs AF, MR2;				// 0x039500
	divs AY1, MR1;				// 0x038c00
	divs AF, MR1;				// 0x039400
	divs AY1, Mr0;				// 0x038b00
	divs AF, Mr0;				// 0x039300
	divs AY1, sR1;				// 0x038f00
	divs AF, sR1;				// 0x039700
	divs AY1, sR0;				// 0x038e00
	divs AF, sR0;				// 0x039600
	
	divq ax0;				// 0x03d000
	divq ax1;				// 0x03d100
	divq ar;				// 0x03d200
	divq mr2;				// 0x03d500
	divq mr1;				// 0x03d400
	divq mr0;				// 0x03d300
	divq sr1;				// 0x03d700
	divq sr0;				// 0x03d600
	
generate_alu_status_symbol:
	// generate alu status
	NONE=ax0-ay0;				// 0x2ae0aa
	NONE=pass sr0;				// 0x2a7eaa

	// ALU using DREG
	ar = ax0 + ax1;				// 0x226021
	af = mx0 + mx1 + C;			// 0x264223
	ar = ay0 + C;				// 0x225420
	af = ay1 - my0;				// 0x26e526
	ar = my1 - mr2 + C-1;			// 0x22c728
	af = sr2 + C-1;				// 0x26d920
	ar = -mx0;				// 0x22a022
	// Y-X [+C-1] will never be generated
	ar = ar and si;				// 0x238a2b
	af = mr1 or sr1;			// 0x27ac2d
	ar = mr0 xor sr0;			// 0x23ce2f
	af = pass mx0;				// 0x260022
	ar = not mx1;				// 0x236320
	af = abs my0;				// 0x27e620
	ar = my1 + 1;				// 0x222027
	af = my1-1;				// 0x270027

	// invalid xop, valid yop
	ar = mx0 + ay0;				// 0x226224
	ar = mx1 + ay0;				// 0x226324
	ar = ay0 + ay0;				// 0x226424
	ar = ay1 + ay0;				// 0x226524
	ar = my0 + ay0;				// 0x226624
	ar = my1 + ay0;				// 0x226724
	ar = sr2 + ay0;				// 0x226924
	ar = si + ay0;				// 0x226b24

	// all dregs, invalid yop
	ar = ax0 + ax0;				// 0x226020
	ar = ax1 + ax0;				// 0x226120
	ar = mx0 + ax0;				// 0x226220
	ar = mx1 + ax0;				// 0x226320
	ar = ay0 + ax0;				// 0x226420
	ar = ay1 + ax0;				// 0x226520
	ar = my0 + ax0;				// 0x226620
	ar = my1 + ax0;				// 0x226720
	ar = mr2 + ax0;				// 0x226820
	ar = sr2 + ax0;				// 0x226920
	ar = ar + ax0;				// 0x226a20
	ar = si + ax0;				// 0x226b20
	ar = mr1 + ax0;				// 0x226c20
	ar = sr1 + ax0;				// 0x226d20
	ar = mr0 + ax0;				// 0x226e20
	ar = sr0 + ax0;				// 0x226f20
	
	// valid xop, invalid yop
	ar = ax0 + ax0;				// 0x226020
	ar = ax0 + ax1;				// 0x226021
	ar = ax0 + mx0;				// 0x226022
	ar = ax0 + mx1;				// 0x226023
	ar = ax0 + my0;				// 0x226026
	ar = ax0 + my1;				// 0x226027
	ar = ax0 + mr2;				// 0x226028
	ar = ax0 + sr2;				// 0x226029
	ar = ax0 + ar;				// 0x22602a
	ar = ax0 + si;				// 0x22602b
	ar = ax0 + mr1;				// 0x22602c
	ar = ax0 + sr1;				// 0x22602d
	ar = ax0 + mr0;				// 0x22602e
	ar = ax0 + sr0;				// 0x22602f

	// invalid xop, all dregs
	ar = ay0 + ax0;				// 0x226420
	ar = ay0 + ax1;				// 0x226421
	ar = ay0 + mx0;				// 0x226422
	ar = ay0 + mx1;				// 0x226423
	ar = ay0 + ay0;				// 0x226424
	ar = ay0 + ay1;				// 0x226425
	ar = ay0 + my0;				// 0x226426
	ar = ay0 + my1;				// 0x226427
	ar = ay0 + mr2;				// 0x226428
	ar = ay0 + sr2;				// 0x226429
	ar = ay0 + ar;				// 0x22642a
	ar = ay0 + si;				// 0x22642b
	ar = ay0 + mr1;				// 0x22642c
	ar = ay0 + sr1;				// 0x22642d
	ar = ay0 + mr0;				// 0x22642e
	ar = ay0 + sr0;				// 0x22642f

	// unary xop or yop
	af = pass mx0;				// 0x260022
	af = pass mx1;				// 0x260023
	af = pass my0;				// 0x260026
	af = pass my1;				// 0x260027
	af = pass sr2;				// 0x260029
	af = pass si;				// 0x26002b
	
	// unary xop
	af = abs mx0;				// 0x27e220
	af = abs mx1;				// 0x27e320
	af = abs ay0;				// 0x27e420
	af = abs ay1;				// 0x27e520
	af = abs my0;				// 0x27e620
	af = abs my1;				// 0x27e720
	af = abs sr2;				// 0x27e920
	af = abs si;				// 0x27eb20

	// unary yop
	// yop only operations xop+1 is covered by xop+constant
	ar = mx0 + 1;				// 0x222022
	ar = mx1 + 1;				// 0x222023
	ar = my0 + 1;				// 0x222026
	ar = my1 + 1;				// 0x222027
	ar = sr2 + 1;				// 0x222029
	ar = si + 1;				// 0x22202b

multiply_symbol:
	// multiply
	mr=mx0*my0(ss);				// 0x20800f
	mr=mx0*my1(su);				// 0x20a80f
	mr=mx0*sr1(us);				// 0x20d00f
	mr=mx1*my0(uu);				// 0x20e10f
	mr=mx1*my1(rnd);			// 0x20290f
	mr=mx1*sr1(ss);				// 0x20910f
	mr=ar*my0(su);				// 0x20a20f
	mr=ar*my1(us);				// 0x20ca0f
	mr=ar*sr1(uu);				// 0x20f20f
	mr=mr0*my0(rnd);			// 0x20230f
	mr=mr0*my1(ss);				// 0x208b0f
	mr=mr0*sr1(su);				// 0x20b30f
	sr=mr1*my0(us);				// 0x24c40f
	sr=mr1*my1(uu);				// 0x24ec0f
	sr=mr1*sr1(rnd);			// 0x24340f
	sr=mr2*my0(ss);				// 0x24850f
	sr=mr2*my1(su);				// 0x24ad0f
	sr=mr2*sr1(us);				// 0x24d50f
	sr=sr0*my0(uu);				// 0x24e60f
	sr=sr0*my1(rnd);			// 0x242e0f
	sr=sr0*sr1(ss);				// 0x24960f
	sr=sr1*my0(su);				// 0x24a70f
	sr=sr1*my1(us);				// 0x24cf0f
	sr=sr1*sr1(uu);				// 0x24e71f

	mr = mx0*mx0(ss);			// 0x20801f
	mr = mx1*mx1(uu);			// 0x20e11f
	mr = ar*ar(rnd);			// 0x20221f

multiply_accumulate_symbol:
	// multiply accumulate
	mr = mR+mx0*my0(ss);			// 0x21000f
	mr = mR+mx0*my0(su);			// 0x21200f
	mr = mR+mx0*my0(us);			// 0x21400f
	mr = mR+mx0*my0(uu);			// 0x21600f
	mr = mR+mx0*my0(rnd);			// 0x20400f

	mr = mR+mx0*mx0(ss);			// 0x21001f
	mr = mR+mx0*mx0(uu);			// 0x21601f
	mr = mR+mx0*mx0(rnd);			// 0x20401f

multiply_subtract_symbol:
	// multiply / subtract
	sr=sr-mr0*my1(ss);			// 0x258b0f
	sr=sr-mr0*my1(su);			// 0x25ab0f
	sr=sr-mr0*my1(us);			// 0x25cb0f
	sr=sr-mr0*my1(uu);			// 0x25eb0f
	sr=sr-mr0*my1(rnd);			// 0x246b0f

	mr=mr-mr2*mr2(ss);			// 0x21851f
	mr=mr-mr2*mr2(uu);			// 0x21e51f
	mr=mr-mr2*mr2(rnd);			// 0x20651f

clear_symbol:
	// clear
	mr=0;					// 0x20980f
	sr=0;					// 0x24980f

	// transfer mr
	mr = mr(rnd);				// 0x20580f
	sr = sr(rnd);				// 0x24580f
	if eq mr=mr (rnd);			// 0x205800
	if ne sr=sr(rnd);			// 0x245801

	// conditional mr saturation
	sat mr;					// 0x030000
	sat sr;					// 0x034000
	
	// MAC using DREG
	mr = ax0 * ax1(rnd);			// 0x202021
	sr = mx0 * mx1(ss);			// 0x248223
	mr = ay0 * ay1(su);			// 0x20a425
	sr = my0 * my1(us);			// 0x24c627
	mr = mr2 * sr2(uu);			// 0x20e829
	sr = sr + ar * si(rnd);			// 0x244a2b
	mr = mr + mr1 * sr0 (ss);		// 0x210c2f
	sr = sr + mr0 * sr0 (su);		// 0x252e2f
	mr = mr + ax0 * sr0 (us);		// 0x21402f
	sr = sr + ax1 * mr0 (uu);		// 0x25612e
	mr = mr - ay0 * sr1 (rnd);		// 0x20642d
	sr = sr - ay1 * mr1(ss);		// 0x25852c
	mr = mr - my0 * si (su);		// 0x21a62b
	sr = sr - my1 * ar (us);		// 0x25c72a
	mr = mr - mr2 * sr2 (uu);		// 0x21e829

	// squaring using DREG
	mr = ax0 * ax0(rnd);			// 0x202020
	sr = ax1 * ax1(ss);			// 0x248121
	mr = ay0 * ay0(uu);			// 0x20e424
	sr = sr + ay1 * ay1(rnd);		// 0x244525
	mr = mr + my0 * my0 (ss);		// 0x210626
	sr = sr + my1 * my1 (uu);		// 0x256727
	mr = mr - sr2 * sr2 (rnd);		// 0x206929
	sr = sr - si * si(ss);			// 0x258b2b

	// invalid xop, valid yop
	mr = ax0 * my0 (rnd);			// 0x202026
	mr = ax1 * my0 (rnd);			// 0x202126
	mr = ay0 * my0 (rnd);			// 0x202426
	mr = ay1 * my0 (rnd);			// 0x202526
	mr = my0 * my0 (rnd);			// 0x202626
	mr = my1 * my0 (rnd);			// 0x202726
	mr = sr2 * my0 (rnd);			// 0x202926
	mr = si * my0 (rnd);			// 0x202b26

	// all dregs, invalid yop
	mr = ax0 * ax0 (rnd);			// 0x202020
	mr = ax1 * ax0 (rnd);			// 0x202120
	mr = mx0 * ax0 (rnd);			// 0x202220
	mr = mx1 * ax0 (rnd);			// 0x202320
	mr = ay0 * ax0 (rnd);			// 0x202420
	mr = ay1 * ax0 (rnd);			// 0x202520
	mr = my0 * ax0 (rnd);			// 0x202620
	mr = my1 * ax0 (rnd);			// 0x202720
	mr = mr2 * ax0 (rnd);			// 0x202820
	mr = sr2 * ax0 (rnd);			// 0x202920
	mr = ar * ax0 (rnd);			// 0x202a20
	mr = si * ax0 (rnd);			// 0x202b20
	mr = mr1 * ax0 (rnd);			// 0x202c20
	mr = sr1 * ax0 (rnd);			// 0x202d20
	mr = mr0 * ax0 (rnd);			// 0x202e20
	mr = sr0 * ax0 (rnd);			// 0x202f20

	// valid xop, invalid yop
	mr = mx0 * ax0 (rnd);			// 0x202220
	mr = mx0 * ax1 (rnd);			// 0x202221
	mr = mx0 * mx1 (rnd);			// 0x202223
	mr = mx0 * ay0 (rnd);			// 0x202224
	mr = mx0 * ay1 (rnd);			// 0x202225
	mr = mx0 * mr2 (rnd);			// 0x202228
	mr = mx0 * sr2 (rnd);			// 0x202229
	mr = mx0 * ar (rnd);			// 0x20222a
	mr = mx0 * si (rnd);			// 0x20222b
	mr = mx0 * mr1 (rnd);			// 0x20222c
	mr = mx0 * mr0 (rnd);			// 0x20222e
	mr = mx0 * sr0 (rnd);			// 0x20222f

	// invalid xop, all dregs
	mr = ax0 * ax0 (rnd);			// 0x202020
	mr = ax0 * ax1 (rnd);			// 0x202021
	mr = ax0 * mx0 (rnd);			// 0x202022
	mr = ax0 * mx1 (rnd);			// 0x202023
	mr = ax0 * ay0 (rnd);			// 0x202024
	mr = ax0 * ay1 (rnd);			// 0x202025
	mr = ax0 * my0 (rnd);			// 0x202026
	mr = ax0 * my1 (rnd);			// 0x202027
	mr = ax0 * mr2 (rnd);			// 0x202028
	mr = ax0 * sr2 (rnd);			// 0x202029
	mr = ax0 * ar (rnd);			// 0x20202a
	mr = ax0 * si (rnd);			// 0x20202b
	mr = ax0 * mr1 (rnd);			// 0x20202c
	mr = ax0 * sr1 (rnd);			// 0x20202d
	mr = ax0 * mr0 (rnd);			// 0x20202e
	mr = ax0 * sr0 (rnd);			// 0x20202f

	// arithmetic shift
	sr=ashift ax0(lo);			// 0x0e600f
	sr=ashift ax1(lo);			// 0x0e610f
	sr=ashift mx0(lo);			// 0x0e620f
	sr=ashift mx1(lo);			// 0x0e630f
	sr=ashift ay0(lo);			// 0x0e640f
	sr=ashift ay1(lo);			// 0x0e650f
	sr=ashift my0(lo);			// 0x0e660f
	sr=ashift my1(hi);			// 0x0e470f
	sr=ashift mr2(hi);			// 0x0e480f
	sr=ashift sr2(hi);			// 0x0e490f
	sr=ashift ar(hi);			// 0x0e4a0f
	sr=ashift si(hi);			// 0x0e4b0f
	sr=ashift mr1(hi);			// 0x0e4c0f
	sr=ashift sr1(hi);			// 0x0e4d0f
	sr=sr or ashift mr0(lo);		// 0x0e7e0f
	sr=sr or ashift sr0(lo);		// 0x0e7f0f
	sr=sr or ashift ax0(lo);		// 0x0e700f
	sr=sr or ashift ax1(lo);		// 0x0e710f
	sr=sr or ashift mx0(lo);		// 0x0e720f
	sr=sr or ashift mx1(lo);		// 0x0e730f
	sr=sr or ashift ay0(lo);		// 0x0e740f
	sr=sr or ashift ay1(hi);		// 0x0e550f
	sr=sr or ashift my0(hi);		// 0x0e560f
	sr=sr or ashift my1(hi);		// 0x0e570f
	sr=sr or ashift mr2(hi);		// 0x0e580f
	sr=sr or ashift sr2(hi);		// 0x0e590f
	sr=sr or ashift ar(hi); 		// 0x0e5a0f
	sr=sr or ashift si(hi);	        	// 0x0e5b0f

	// logical shift
	sr=lshift si(lo);			// 0x0e2b0f
	sr=lshift ar(hi);			// 0x0e0a0f
	sr=sr or lshift mr0(lo);		// 0x0e3e0f
	sr=sr or lshift mr1(hi);		// 0x0e1c0f

	// normalize
	sr=norm mr2(lo);			// 0x0ea80f
	sr=norm sr0(hi);			// 0x0e8f0f
	sr=sr or norm sr1(lo);			// 0x0ebd0f
	sr=sr or norm si(hi);			// 0x0e9b0f
	
	// derive exponent
	se=exp ar(lo);				// 0x0eea0f
	se=exp mr0(hi);				// 0x0ece0f
	se=exp mr1(hix);			// 0x0edc0f

	// exponent adjust
	sb=expadj mr2;				// 0x0ef80f

	// arithmetic shift immediate
	sr=ashift si by -128(lo);		// 0x0f6b80
	sr=ashift si by 0(lo);			// 0x0f6b00
	sr=ashift si by 127(lo);		// 0x0f6b7f
	sr=ashift si by -128(hi);		// 0x0f4b80
	sr=ashift si by 0(hi);			// 0x0f4b00
	sr=ashift si by 127(hi);		// 0x0f4b7f
	sr=sr or ashift si by -128(lo);		// 0x0f7b80
	sr=sr or ashift si by 0(lo);		// 0x0f7b00
	sr=sr or ashift si by 127(lo);		// 0x0f7b7f
	sr=sr or ashift si by -128(hi);		// 0x0f5b80
	sr=sr or ashift si by 0(hi);		// 0x0f5b00
	sr=sr or ashift si by 127(hi);		// 0x0f5b7f

	// logical shift immediate
	sr=lshift si by -128(lo);		// 0x0f2b80
	sr=lshift si by 0(lo);			// 0x0f2b00
	sr=lshift si by 127(lo);		// 0x0f2b7f
	sr=lshift si by -128(hi);		// 0x0f0b80
	sr=lshift si by 0(hi);			// 0x0f0b00
	sr=lshift si by 127(hi);		// 0x0f0b7f
	sr=sr or lshift si by -128(lo);		// 0x0f3b80
	sr=sr or lshift si by 0(lo);		// 0x0f3b00
	sr=sr or lshift si by 127(lo);		// 0x0f3b7f
	sr=sr or lshift si by -128(hi);		// 0x0f1b80
	sr=sr or lshift si by 0(hi);		// 0x0f1b00
	sr=sr or lshift si by 127(hi);		// 0x0f1b7f
	
	// normalize immediate
	sr=norm si by -128(lo);		// 0x0fab80
	sr=norm si by 0(lo);			// 0x0fab00
	sr=norm si by 127(lo);		// 0x0fab7f
	sr=norm si by -128(hi);		// 0x0f8b80
	sr=norm si by 0(hi);			// 0x0f8b00
	sr=norm si by 127(hi);		// 0x0f8b7f
	sr=sr or norm si by -128(lo);		// 0x0fbb80
	sr=sr or norm si by 0(lo);		// 0x0fbb00
	sr=sr or norm si by 127(lo);		// 0x0fbb7f
	sr=sr or norm si by -128(hi);		// 0x0f9b80
	sr=sr or norm si by 0(hi);		// 0x0f9b00
	sr=sr or norm si by 127(hi);		// 0x0f9b7f
	
	// register move
	ax0=l1;					// 0x0d0109
	ax1=l0;					// 0x0d0118
	mx0=m3;					// 0x0d0127
	mx1=m2;					// 0x0d0136
	ay0=m1;					// 0x0d0145
	ay1=m0;					// 0x0d0154
	my0=i3;					// 0x0d0163
	my1=i2;					// 0x0d0172
	mr2=i1;					// 0x0d0181
	sr2=i0;					// 0x0d0190
	ar=stackp;				// 0x0d03af
	si=ijpg;				// 0x0d03bb
	mr1=iopg;				// 0x0d03ca
	sr1=dmpg2;				// 0x0d03d9
	mr0=dmpg1;				// 0x0d03e8
	sr0=px;					// 0x0d03f7

	i0=sb;					// 0x0d0706
	i1=se;					// 0x0d0715
	i2=ccode;				// 0x0d0724
	i3=lpstackp;				// 0x0d0733
	m0=sstat;				// 0x0d0742
	m1=mstat;				// 0x0d0751
	m2=astat;				// 0x0d0760
	m3=lpstacka;				// 0x0d067f
	l0=cntr;				// 0x0d068e
	l1=l7;					// 0x0d069b
	l2=l6;					// 0x0d06aa
	l3=l5;					// 0x0d06b9
	imask=l4;				// 0x0d06c8
	IRPTL=m7;				// 0x0d06d7
	icntl=m6;				// 0x0d06e6
	stacka=m5;				// 0x0d06f5

	i4=m4;					// 0x0d0a04
	i5=i7;					// 0x0d0a13
	i6=i6;					// 0x0d0a22
	i7=i5;					// 0x0d0a31
	m4=i4;					// 0x0d0a40
	m5=stacka;				// 0x0d095f
	m6=icntl;				// 0x0d096e
	m7=irptl;				// 0x0d097d
	l4=imask;				// 0x0d098c
	l5=l3;					// 0x0d099b
	l6=l2;					// 0x0d09aa
	l7=sr0;					// 0x0d08bf
	cntr=mr0;				// 0x0d08ee
	lpstacka=sr1;				// 0x0d08fd

	AStat=mr1;				// 0x0d0c0c
	mstat=si;				// 0x0d0c1b
	mstat=ar;				// 0x0d0c1a
	lpstackp=sr2;				// 0x0d0c39
	ccode=mr2;				// 0x0d0c48
	se=my1;					// 0x0d0c57
	sb=my0;					// 0x0d0c66
	px=ay1;					// 0x0d0c75
	dmpg1=ay0;				// 0x0d0c84
	dmpg2=mx1;				// 0x0d0c93
	iopg=mx0;				// 0x0d0ca2
	ijpg=ax1;				// 0x0d0cb1
	stackp=ax0;				// 0x0d0cf0

	// load register immediate
	ax0=0;					// 0x400000
	ax1=0xffff;				// 0x4ffff1
	mx0=0;					// 0x400002
	mx1=0;					// 0x400003
	ay0=0;					// 0x400004
	ay1=0;					// 0x400005
	my0=0;					// 0x400006
	my1=0;					// 0x400007
	mr2=0;					// 0x400008
	sr2=0;					// 0x400009
	ar=0;					// 0x40000a
	si=0;					// 0x40000b
	mr1=0;					// 0x40000c
	sr1=0;					// 0x40000d
	mr0=0;					// 0x40000e
	sr0=0;					// 0x40000f

	i0=0;					// 0x500000
	i1=0xffff;				// 0x5ffff1
	i2=0;					// 0x500002
	i3=0;					// 0x500003
	m0=0;					// 0x500004
	m1=0;					// 0x500005
	m2=0;					// 0x500006
	m3=0;					// 0x500007
	l0=0;					// 0x500008
	l1=0;					// 0x500009
	l2=0;					// 0x50000a
	l3=0;					// 0x50000b
	imask=0;				// 0x50000c
	irptl=0;				// 0x50000d
	icntl=0;				// 0x50000e
	stacka=0;				// 0x50000f

	i4=0;					// 0x300000
	i5=0xffff;				// 0x3ffff1
	i6=0;					// 0x300002
	i7=0;					// 0x300003
	m4=0;					// 0x300004
	m5=0;					// 0x300005
	m6=0;					// 0x300006
	m7=0;					// 0x300007
	l4=0;					// 0x300008
	l5=0;					// 0x300009
	l6=0;					// 0x30000a
	l7=0;					// 0x30000b
	cntr=0;					// 0x30000e
	lpstacka=0;				// 0x30000f

	astat=0;				// 0x100000
	mstat=0xfff;				// 0x10fff1
	/* sstat=0; */
	lpstackp=0;				// 0x100003
	ccode=0;				// 0x100004
	se=0;					// 0x100005
	sb=0;					// 0x100006
	px=0;					// 0x100007
	dmpg1=0;				// 0x100008
	dmpg2=0;				// 0x100009
	iopg=0;					// 0x10000a
	ijpg=0;					// 0x10000b
	stackp=0;				// 0x10000f


	ax0=LENGTH(roundbuf);			// 0x400000
	mx0=roundbuf;				// 0x400002
	ay1=roundbuf+0x38;			// 0x400005
	my1=roundbuf+0xffff;			// 0x400007
	i3=roundbuf;				// 0x500003
	m6=roundbuf+0x79;			// 0x300006
	px=roundbuf+0xfff;			// 0x100007
	stackp=LENGTH(roundbuf);		// 0x10000f
    ar = length(bufName9);          // 0x40000a
character_constants:
    ar = 'A';                       // 0x40041a
    ar = '\x234';                   // 0x40234a
    ar = '\0';                      // 0x40000a
extern_addrs:
    ar = extpm + 3;                 // 0x40000a
    ar = -5 + extdm + 3;            // 0x40000a

	// data memory read (Direct Address)
	ax0=dm(some_data);			// 0x800000
	ax1=dm(some_data);			// 0x800001
	mx0=dm(some_data);			// 0x800002
	mx1=dm(some_data);			// 0x800003
	ay0=dm(some_data);			// 0x800004
	ay1=dm(some_data);			// 0x800005
	my0=dm(some_data);			// 0x800006
	my1=dm(some_data);			// 0x800007
	mr2=dm(some_data);			// 0x800008
	sr2=dm(some_data);			// 0x800009
	ar=dm(some_data);			// 0x80000a
	si=dm(some_data);			// 0x80000b
	mr1=dm(some_data);			// 0x80000c
	sr1=dm(some_data);			// 0x80000d
	mr0=dm(some_data);			// 0x80000e
	sr0=dm(some_data);			// 0x80000f

	i0=dm(some_data);			// 0xa00000
	i1=dm(some_data);			// 0xa00001
	i2=dm(some_data);			// 0xa00002
	i3=dm(some_data);			// 0xa00003
	i4=dm(some_data);			// 0xa00004
	i5=dm(some_data);			// 0xa00005
	i6=dm(some_data);			// 0xa00006
	i7=dm(some_data);			// 0xa00007
	m0=dm(some_data);			// 0xa00008
	m1=dm(some_data);			// 0xa00009
	m2=dm(some_data);			// 0xa0000a
	m3=dm(some_data);			// 0xa0000b
	m4=dm(some_data);			// 0xa0000c
	m5=dm(some_data);			// 0xa0000d
	m6=dm(some_data);			// 0xa0000e
	m7=dm(some_data);			// 0xa0000f

	ax0=dm(0);				// 0x800000
	ax1=dm(0xffff);				// 0x8ffff1
	ax0=dm(some_data+5);			// 0x800000

	i0=dm(0);				// 0xa00000
	i5=dm(0xffff);				// 0xaffff5
	m2=dm(some_data+0xff);			// 0xa0000a
	m7=dm(some_data-5);			// 0xa0000f

	// Data Memory Write (Direct Address)
	dm(some_data) = ax0;			// 0x900000
	dm(some_data) = ax1;			// 0x900001
	dm(some_data) = mx0;			// 0x900002
	dm(some_data) = mx1;			// 0x900003
	dm(some_data) = ay0;			// 0x900004
	dm(some_data) = ay1;			// 0x900005
	dm(some_data) = my0;			// 0x900006
	dm(some_data) = my1;			// 0x900007
	dm(some_data) = mr2;			// 0x900008
	dm(some_data) = sr2;			// 0x900009
	dm(some_data) = ar;			// 0x90000a
	dm(some_data) = si;			// 0x90000b
	dm(some_data) = mr1;			// 0x90000c
	dm(some_data) = sr1;			// 0x90000d
	dm(some_data) = mr0;			// 0x90000e
	dm(some_data) = sr0;			// 0x90000f

	dm(some_data) = i0;			// 0xb00000
	dm(some_data) = i1;			// 0xb00001
	dm(some_data) = i2;			// 0xb00002
	dm(some_data) = i3;			// 0xb00003
	dm(some_data) = i4;			// 0xb00004
	dm(some_data) = i5;			// 0xb00005
	dm(some_data) = i6;			// 0xb00006
	dm(some_data) = i7;			// 0xb00007
	dm(some_data) = m0;			// 0xb00008
	dm(some_data) = m1;			// 0xb00009
	dm(some_data) = m2;			// 0xb0000a
	dm(some_data) = m3;			// 0xb0000b
	dm(some_data) = m4;			// 0xb0000c
	dm(some_data) = m5;			// 0xb0000d
	dm(some_data) = m6;			// 0xb0000e
	dm(some_data) = m7;			// 0xb0000f

	dm(0) = ax0;				// 0x900000
	dm(0xffff) = ax1;			// 0x9ffff1
	dm(some_data+5)=ax0;			// 0x900000
    dm(extdm-5) = ax1;              // 0x900001

	dm(0)=i0; 				// 0xb00000
	dm(0xffff)=i5;				// 0xbffff5
	dm(some_data+0xff)=m2;			// 0xb0000a
	dm(some_data-5)=m7;			// 0xb0000f

	// Data Memory read (Indirect address)
	ax0=DM(I0+=m3);				// 0x154003
	i1=dm(i1+m2);				// 0x150116
	i6=dm(i2,m1);				// 0x154229
	lpstackp=dm(m0,i3);			// 0x15033c
	mx0=dm(i4+=m7);				// 0x156023
	i3=dm(i5+m6);				// 0x152136
	m4=dm(i6,m5);				// 0x156249
	se=dm(m4,i7);				// 0x15235c
	si=dm(i0+=m0);				// 0x1540b0
	imask=dm(i1+m1);			// 0x1501c5
	cntr=dm(i2,m2);				// 0x1542ea
	stackp=dm(m3,i3);			// 0x1503ff
	mr0=dm(i4+=m4);				// 0x1560e0
	stacka=dm(i5+m5);			// 0x1521f5
	i4=dm(i6,m6);				// 0x15620a
	mstat=dm(m7,i7);			// 0x15231f

	// Program Memory Read
	ax1=PM(I7+=m4);				// 0x15e01c
	i2=pm(i6+m5);				// 0x15a129
	i7=pm(i5,m6);				// 0x15e236
	ccode=pm(m7,i4);			// 0x15a343
	mx1=pm(i3+=m0);				// 0x15c03c
	m0=pm(i2+m1);				// 0x158149
	m5=pm(i1,m2);				// 0x15c256
	sb=pm(m3,i0);				// 0x158363
	mr1=pm(i7+=m7);				// 0x15e0cf
	irptl=pm(i6+m6);			// 0x15a1da
	lpstacka=pm(i5,m5);			// 0x15e2f5
	astat=pm(m4,i4);			// 0x15a300
	sr0=pm(i3+=m3);				// 0x15c0ff
	i0=pm(i2+m2);				// 0x15810a
	i5=pm(i1,m1);				// 0x15c215
	sstat=pm(m0,i0);			// 0x158320

	// Data Memory Write (Indirect Address)
	DM(I0+=m3)=mx0;				// 0x155023
	dm(i1+m2)=i3;				// 0x151136
	dm(i2,m1)=m4;				// 0x155249
	dm(m0,i3)=se;				// 0x15135c
	dm(i4+=m7)=ay0;				// 0x157043
	dm(i5+m6)=m1;				// 0x153156
	dm(i6,m5)=m6;				// 0x157269
	dm(m4,i7)=px;				// 0x15337c
	dm(i0+=m0)=sr1;				// 0x1550d0
	dm(i1+m1)=icntl;			// 0x1511e5
	dm(i2,m2)=lpstacka;			// 0x1552fa
	dm(m3,i3)=astat;			// 0x15130f
	dm(i4+=m4)=ax0;				// 0x157000
	dm(i5+m5)=i1;				// 0x153115
	dm(i6,m6)=i6;				// 0x15722a
	dm(m7,i7)=lpstackp;			// 0x15333f

	// Program Memory Write (Indirect Address)
	PM(I7+=m4)=mx1;				// 0x15f03c
	pm(i6+m5)=m0;				// 0x15b149
	pm(i5,m6)=m5;				// 0x15f256
	pm(m7,i4)=sb;				// 0x15b363
	pm(i3+=m0)=ay1;				// 0x15d05c
	pm(i2+m1)=m2;				// 0x159169
	pm(i1,m2)=m7;				// 0x15d276
	pm(m3,i0)=dmpg1;			// 0x159383
	pm(i7+=m7)=mr0;				// 0x15f0ef
	pm(i6+m6)=stacka;			// 0x15b1fa
	pm(i5,m5)=i4;				// 0x15f205
	pm(m4,i4)=mstat;			// 0x15b310
	pm(i3+=m3)=ax1;				// 0x15d01f
	pm(i2+m2)=i2;				// 0x15912a
	pm(i1,m1)=i7;				// 0x15d235
	pm(m0,i0)=ccode;			// 0x159340

	// Indirect DAG reg write with DAG reg move
	dm(i0+=m2)=l2, l2=i0;			// 0x1559a2
	dm(i1,m1)=l3, l3=i1;			// 0x1559b5
	dm(i5+m6)=l4, l4=i5;			// 0x153a86
	dm(m5,i4)=l5, l5=i4;			// 0x153a91
	dm(i7+=m4)=l6, l6=i7;			// 0x157aac
	dm(i6,m7)=l7, l7=i6;			// 0x157abb
	dm(i3+m3)=i0, i0=i3;			// 0x15190f
	dm(m0,i2)=i1, i1=i2;			// 0x151918
	dm(i1+=m1)=i2, i2=i1;			// 0x155925
	dm(i0,m2)=i3, i3=i0;			// 0x155932
	dm(i5+m5)=i4, i4=i5;			// 0x153a05
	dm(m4,i4)=i5, i5=i4;			// 0x153a10
	dm(i7+=m7)=i6, i6=i7;			// 0x157a2f
	dm(i6,m6)=i7, i7=i6;			// 0x157a3a
	dm(i1+m0)=m0, m0=i1;			// 0x151944
	dm(m1,i0)=m1, m1=i0;			// 0x151951
	dm(i3+=m2)=m2, m2=i3;			// 0x15596e
	dm(i2,m3)=m3, m3=i2;			// 0x15597b
	dm(i6+m4)=m4, m4=i6;			// 0x153a48
	dm(m5,i7)=m5, m5=i7;			// 0x153a5d
	dm(i4+=m6)=m6, m6=i4;			// 0x157a62
	dm(i5,m7)=m7, m7=i5;			// 0x157a77
	dm(i2+m0)=l0, l0=i2;			// 0x151988
	dm(m3,i3)=l1, l1=i3;			// 0x15199f

        // Indirect read/write immediate pre/post modify
	ax0 = dm(i0+=0);			// 0x090000
	mx1 = dm(i1,-128);			// 0x090807
	ay1 = dm(i2+0);				// 0x084009
	my0 = dm(-128,i3);			// 0x08480e
	mr2 = dm(i4+=-1);			// 0x09aff0
	ar = dm(i5,127);			// 0x09a7f6
	sr1 = dm(i6+-1);			// 0x08eff9
	mr0 = dm(127,i7);			// 0x08e7fe
	dm(i0+=0) = ax1;			// 0x091001
	dm(i1,-128) = mx0;			// 0x091806
	dm(i2+0) = ay0;				// 0x085008
	dm(-128,i3) = my1;			// 0x08580f
	dm(i4+=-1) = sr2;			// 0x09bff1
	dm(i5,127) = si;			// 0x09b7f7
	dm(i6+-1) = mr1;			// 0x08fff8
	dm(127,i7) = sr0;			// 0x08f7ff
	
	dm(i0+=m3) = 0;				// 0x078003 0x0
	dm(i1,m2) = 0xffff;			// 0x078ff6 0x0ff000
	dm(i2+=m1) = 0;				// 0x078009 0x0
	dm(i3,m0) = 0xffff;			// 0x078ffc 0x0ff000
	dm(i4+=m6) = 0;				// 0x07a002 0x0
	dm(i5,m7) = 0xffff;			// 0x07aff7 0x0ff000
	dm(i6+=m4) = 0;				// 0x07a008 0x0
	dm(i7,m5) = 0xffff;			// 0x07affd 0x0ff000
    dm(i7,m5) = extpm+3;        // 0x07a00d 0x000000
    dm(i7,m5) = extdm-5;        // 0x07a00d 0x000000

    // PM : 24 immediate write
	pm(i1+=m2) = 0 : 24;			// 0x07c006 0x0
	pm(i5,m7) = -1 : 24;			// 0x07eff7 0x0ff0ff
	pm(i3+=m1) = 0x123456 : 24;		// 0x07c34d 0x012056
	pm(i7,m4) = 0x7fffff : 24;		// 0x07effc 0x07f0ff
	pm(i7,m4) = extpm+3 : 24;		// 0x07e00c 0x000000
	pm(i7,m4) = extpm-5 : 24;		// 0x07e00c 0x000000

	// IO space read/write
	IO(0)=ax0;				// 0x069000
	IO(511)=ax1;				// 0x06bff1
	IO(1023)=mx0;				// 0x06fff2
	IO(0)=mx1;				// 0x069003
	IO(0)=ay0;				// 0x069004
	IO(0)=ay1;				// 0x069005
	IO(0)=my0;				// 0x069006
	IO(0)=my1;				// 0x069007
	IO(0)=mr2;				// 0x069008
	IO(0)=sr2;				// 0x069009
	IO(0)=ar;				// 0x06900a
	IO(0)=si;				// 0x06900b
	IO(0)=mr1;				// 0x06900c
	IO(0)=sr1;				// 0x06900d
	IO(0)=mr0;				// 0x06900e
	IO(0)=sr0;				// 0x06900f

	ax0 = IO(0);				// 0x068000
	ax1 = IO(511);				// 0x06aff1
	mx0=IO(1023);				// 0x06eff2
	mx1=IO(0);				// 0x068003
	ay0=IO(0);				// 0x068004
	ay1=IO(0);				// 0x068005
	my0=IO(0);				// 0x068006
	my1=IO(0);				// 0x068007
	mr2=IO(0);				// 0x068008
	sr2=IO(0);				// 0x068009
	ar=IO(0);				// 0x06800a
	si=IO(0);				// 0x06800b
	mr1=IO(0);				// 0x06800c
	sr1=IO(0);				// 0x06800d
	mr0=IO(0);				// 0x06800e
	sr0=IO(0);				// 0x06800f

	// sysreg read/write
	ax0 = reg(b7);				// 0x060070
	ax1 = reg(b6);				// 0x060061
	mx0 = reg(b5);				// 0x060052
	mx1 = reg(b4);				// 0x060043
	ay0 = reg(b3);				// 0x060034
	ay1 = reg(b2);				// 0x060025
	my0 = reg(b1);				// 0x060016
	my1 = reg(b0);				// 0x060007
	mr2 = reg(sysctl);			// 0x060088
	sr2 = reg(cactl);			// 0x0600f9
	ar = reg(0);				// 0x06000a
	si = reg(0xff);		 		// 0x060ffb
	mr1 = reg(128);				// 0x06080c

	reg(b7) = sr1;				// 0x06107d
	reg(b6) = mr0;				// 0x06106e
	reg(b5) = sr0;				// 0x06105f
	reg(b4) = ax0;				// 0x061040
	reg(b3) = ax1;				// 0x061031
	reg(b2) = mx0;				// 0x061022
	reg(b1) = mx1;				// 0x061013
	reg(b0) = ay0;				// 0x061004
	reg(sysctl) = ay1;			// 0x061085
	reg(cactl) = my0;			// 0x0610f6
	reg(0) = my1;				// 0x061007
	reg(0xff) = mr2;			// 0x061ff8
	reg(128) = sr2;				// 0x061809

	// modify address register
	modify(i1+=m3);				// 0x018007
	modify(i3,m2);				// 0x01800e
	modify(i2+=m1);				// 0x018009
	modify(i0,m0);				// 0x018000
	modify(i7+=m7);				// 0x01a00f
	modify(i4,m6);				// 0x01a002
	modify(i5+=m4);				// 0x01a004
	modify(i6,m5);				// 0x01a009

	// modify immediate
	modify(i0+=-128);			// 0x010800
	modify(i1,0);				// 0x010004
	modify(i2+=127);			// 0x0107f8
	modify(i3,-127);			// 0x01081c
	modify(i4+=-91);			// 0x012a50
	modify(i5,-11);				// 0x012f54
	modify(i6+=23);				// 0x012178
	modify(i7,102);				// 0x01266c

	// JUMP
	if ne jump Ptop_loop;			// 0x180001
	if not ce jump 0x1fff;			// 0x19fffe
	if av jump (i0);			// 0x0b0060
	if not av call(i5);			// 0x0b6074
Ptop_loop:
	jump Ptop_loop;				// 0x1c0000
	jump (i2);				// 0x0b00f8
	jump (i7);				// 0x0b20fc
	jump 0;					// 0x1c0000
	jump -1;				// 0x1ffff3
	jump Ptop_loop+10;			// 0x1c0000
	jump Ptop_loop-10;			// 0x1c0000

	// call
	call Pscale_down;			// 0x1c0004
	call (i1);				// 0x0b40f4
	call (i4);				// 0x0b60f0
	call 0;					// 0x1c0004
	call -1;				// 0x1ffff7
	call Pscale_down+25;			// 0x1c0004
	call Pscale_down-25;			// 0x1c0004

	if ne jump Ptop_loop (db);		// 0x1a0001
	if not ce jump 0x1fff (db);		// 0x1bfffe
	if av jump (i0) (db);			// 0x0b8060
	if not av call(i5) (db);		// 0x0be074
	jump Ptop_loop (db);			// 0x1c0008
	jump (i2) (db);				// 0x0b80f8
	jump (i7) (db);				// 0x0ba0fc
	jump 0 (db);				// 0x1c0008
	jump -1 (db);				// 0x1ffffb
	jump Ptop_loop+10 (db);			// 0x1c0008
	jump Ptop_loop-10 (db);			// 0x1c0008
	jump extpm-10 (db);			    // 0x1c0008

	// call
	call Pscale_down (db);			// 0x1c000c
	call (i1) (db);				// 0x0bc0f4
	call (i4) (db);				// 0x0be0f0
	call 0 (db);				// 0x1c000c
	call -1 (db);				// 0x1fffff
	call Pscale_down+25 (db);		// 0x1c000c
	call Pscale_down-25 (db);		// 0x1c000c

	// long jump or long call
	if ac lcall Pscale_down;		// 0x051008 0x0
	ljump Pscale_down;			// 0x05000f 0x0
	lcall Pscale_down+0x7fffff;		// 0x05100f 0x000000
	if swcond ljump Pscale_down-1;		// 0x05000a 0x000000
	ljump -1;				// 0x050fff 0x0ffff0
	if not mv lcall -1;			// 0x051ffd 0x0ffff0
    lcall extpm-5;              // 0x05100f 0x000000

	// rts/rti
	rts;					// 0x0a00f0
	rti;					// 0x0a40f0
	if le rts;				// 0x0a0030
	if mv rti;				// 0x0a40c0
	rts(db);				// 0x0a80f0
	rti(db);				// 0x0ac0f0
	if le rts (db);				// 0x0a8030
	if mv rti (db);				// 0x0ac0c0
	rti(db)(ss);				// 0x0ae0f0

	// do until
	do Ploop until ce;			// 0x16000e
	do Ploop until forever;			// 0x16000f
	do -1 until forever;			// 0x16ffff
	do extpm-5 until forever;		// 0x16000f

	// idle
	idle;					// 0x020000
	idle (1);				// 0x020001
	idle (2);				// 0x020002
	idle (4);				// 0x020004
	idle (8);				// 0x020008
	idle (0xf);				// 0x02000f

	// stack control
	push pc;				// 0x040040
	push loop;				// 0x040010
	push sts;				// 0x040002
	pop pc;					// 0x040060
	pop loop;				// 0x040018
	pop sts;				// 0x040003
	pop pc, pop loop, pop sts;		// 0x04007b
	pop pc, push loop, push sts;		// 0x040072
	flush cache;				// 0x040080

Ploop:
	// Mode control
	ena int;				// 0x0c0003
	ena sec_dag;				// 0x0c000c
	ENA sec_reg;				// 0x0c0030
	ENA bit_rev;				// 0x0c00c0
	ENA av_latch;				// 0x0c0300
	ENA ar_sat;				// 0x0c0c00
	ENA m_mode;				// 0x0c3000
	ENA timer;				// 0x0cc000
	dis int;				// 0x0c0002
	dis sec_dag;				// 0x0c0008
	DIS sec_reg;				// 0x0c0020
	DIS bit_rev;				// 0x0c0080
	DIS av_latch;				// 0x0c0200
	DIS ar_sat;				// 0x0c0800
	DIS m_mode;				// 0x0c2000
	DIS timer;				// 0x0c8000
	// should be ENA bit_rev, dis av_latch, ...;
	ENA int, ENA sec_dag, ena sec_reg, ena bit_rev,
	ena av_latch, ena ar_sat, ena m_mode, ena timer;	// 0x0cffff
	dis int, dis sec_dag, dis sec_reg, dis bit_rev,
	dis av_latch, dis ar_sat, dis m_mode, dis timer;	// 0x0caaaa
	ena bit_rev, dis av_latch;		// 0x0c02c0

	clrint 0;				// 0x070020
	setint 1;				// 0x070001
	clrint 2;				// 0x070022
	setint 3;				// 0x070003
	clrint 4;				// 0x070024
	setint 5;				// 0x070005
	clrint 6;				// 0x070026
	setint 7;				// 0x070007
	clrint 8;				// 0x070028
	setint 9;				// 0x070009
	clrint 10;				// 0x07002a
	setint 11;				// 0x07000b
	clrint 12;				// 0x07002c
	setint 13;				// 0x07000d
	clrint 14;				// 0x07002e
	setint 15;				// 0x07000f

	// NOP
	nop;					// 0x0

	// computation and memory read
	mr=mx0*sr1(rnd), sr0=dm(i0,m3);		// 0x6030f3
	sr=sr+mx1*my1(rnd), mr0=pm(i1,m2);	// 0x6449e6
	sr=sr-ar*my0(rnd), sr1=dm(i2,m1);	// 0x6462d9
	sr=mr0*sr1(ss), mr1=pm(i3,m0);		// 0x6493cc
	sr=mr1*my1(su), si=dm(i4,m7);		// 0x74acb3
	sr=mr2*my0(us), ar=pm(i5,m6);		// 0x74c5a6
	sr=sr0*sr1(uu), sr2=dm(i6,m5);		// 0x74f699
	sr=sr+sr1*my1(ss), mr2=pm(i7,m4);	// 0x750f8c
	mr=mr+mx0*my0(su), my1=dm(i4,m7);	// 0x712073
	mr=mr+mx1*sr1(us), my0=pm(i5,m6);	// 0x715166
	mr=mr+ar*my1(uu), ay1=dm(i6,m5);	// 0x716a59
	mr=mr-mr0*my0(ss), ay0=pm(i7,m4);	// 0x71834c
	mr=mr-mr1*sr1(su), mx1=dm(i0,m3);	// 0x61b433
	sr=sr-mr2*my1(us), mx0=pm(i1,m2);	// 0x65cd26
	mr=mr-sr0*my0(uu), ax1=dm(i2,m1);	// 0x61e619
	mr=0, ax0=pm(i3,m0);			// 0x60980c
	sr=0, ax0=dm(i3,m0);			// 0x64980c
	mr=mr(rnd), ax0=pm(i3,m0);		// 0x60580c
	sr=sr (rnd), ax0=dm(i3,m0);		// 0x64580c
	
	ar=pass af, ax0 = dm(i3,m0);		// 0x62100c
	af=ay1+1, sr0=pm(i4,m7);		// 0x7628f3
	ar=ax0+ay0+c, mr0=dm(i5,m6);		// 0x7240e6
	af=ax1+af, sr1=pm(i6,m5);		// 0x7671d9
	ar=not ay1, mr1=dm(i7,m4);		// 0x7288cc
	af=-ay0, si=pm(i4,m7);			// 0x76a0b3
	af=ar-af+c-1, ar=dm(i5,m6);		// 0x76d2a6
	af=mr0-ay1, sr2=pm(i6,m5);		// 0x76eb99
	ar=ay0-1, mr2=dm(i7,m4);		// 0x73008c
	af=af-mr1, my1=pm(i0,m3);		// 0x673473
	ar=ay1-mr2+c-1, my0=dm(i1,m2);		// 0x634d66
	af=not sr0, ay1=pm(i2,m1);		// 0x676659
	ar=sr1 and ay0, ay0=dm(i3,m0);		// 0x63874c
	af=ax0 or af, mx1=pm(i4,m7);		// 0x77b033
	ar=ax1 xor ay1, mx0=dm(i5,m6);		// 0x73c926
	af=abs ar, ax1=pm(i6,m5);		// 0x77e219

	sr = lshift si (hi), mr2 = dm(i7,m4);		// 0x13008c
	sr = sr or lshift sr2 (hi), sr2 = pm(i4,m7);	// 0x131193
	sr = lshift ar (lo), ar = dm(i5,m6);		// 0x1322a6
	sr = sr or lshift mr0 (lo), si = pm(i6,m5);	// 0x1333b9
	sr = ashift mr1 (hi), mr1 = dm(i7,m4);		// 0x1344cc
	sr = sr or ashift mr2 (hi), sr1 = pm(i0,m3);	// 0x1255d3
	sr = ashift sr0 (lo), mr0 = dm(i1,m2);		// 0x1266e6
	sr = sr or ashift sr1 (lo), sr0 = pm(i2,m1);	// 0x1277f9
	sr = norm si (hi), ax0 = dm(i3,m0);		// 0x12800c
	sr = sr or norm sr2 (hi), ax1 = pm(i4,m7);	// 0x139113
	sr = norm ar(lo), mx0 = dm(i5,m6);		// 0x13a226
	sr = sr or norm mr0(lo), mx1 = pm(i6,m5);	// 0x13b339
	se = exp mr1(hi), ay0 = dm(i7,m4);		// 0x13c44c
	se = exp mr2(hix), ay1 = pm(i4,m7);		// 0x13d553
	se = exp sr0(lo), my0 = dm(i5,m6);		// 0x13e666
	sb = expadj sr1, my1 = pm(i6,m5);		// 0x13f779

	// computation with register to register move
	mr=mx0*sr1(rnd), sr0=ax0;		// 0x2830f0
	sr=sr+mx1*my1(rnd), mr0=ax1;		// 0x2c49e1
	sr=sr-ar*my0(rnd), sr1=mx0;		// 0x2c62d2
	sr=mr0*sr1(ss), mr1=mx1;		// 0x2c93c3
	sr=mr1*my1(su), si=ay0;			// 0x2cacb4
	sr=mr2*my0(us), ar=ay1;			// 0x2cc5a5
	sr=sr0*sr1(uu), sr2=my0;		// 0x2cf696
	sr=sr+sr1*my1(ss), mr2=my1;		// 0x2d0f87
	mr=mr+mx0*my0(su), my1=mr2;		// 0x292078
	sr=sr+mx1*sr1(us), my0=sr2;		// 0x2d5169
	mr=mr+ar*my1(uu), ay1=ar;		// 0x296a5a
	sr=sr-mr0*my0(ss), ay0=si;		// 0x2d834b
	sr=sr-mr1*sr1(su), mx1=mr1;		// 0x2db43c
	sr=sr-mr2*my1(us), mx0=sr1;		// 0x2dcd2d
	mr=mr-sr0*my0(uu), ax1=mr0;		// 0x29e61e
	
	ar=pass af, ax0 = sr0;			// 0x2a100f
	af=ay1+1, sr0=ax0;			// 0x2e28f0
	ar=ax0+ay0+c, mr0=ax1;			// 0x2a40e1
	af=ax1+af, sr1=mx0;			// 0x2e71d2
	ar=not ay1, mr1=mx1;			// 0x2a88c3
	af=-ay0, si=ay0;			// 0x2ea0b4
	af=ar-af+c-1, ar=ay1;			// 0x2ed2a5
	af=mr0-ay1, sr2=my0;			// 0x2eeb96
	ar=ay0-1, mr2=my1;			// 0x2b0087
	af=af-mr1, my1=mr2;			// 0x2f3478
	ar=ay1-mr2+c-1, my0=sr2;		// 0x2b4d69
	af=not sr0, ay1=ar;			// 0x2f665a
	ar=sr1 and ay0, ay0=si;			// 0x2b874b
	af=ax0 or af, mx1=mr1;			// 0x2fb03c
	ar=ax1 xor ay1, mx0=sr1;		// 0x2bc92d
	af=abs ar, ax1=mr0;			// 0x2fe21e

	sr = lshift ay1 (hi), mr1 = si;			// 0x1405cb
	sr = sr or lshift my0 (hi), mr2 = mr1;		// 0x14168c
	sr = lshift my1 (lo), my1 = sr1;		// 0x14277d
	sr = sr or lshift mr2(lo), my0 = mr0;		// 0x14386e
	sr = ashift sr2 (hi), ay1 = sr0;		// 0x14495f
	sr = sr or ashift ar (hi), ay0 = ax0;		// 0x145a40
	sr = ashift si (lo), mx1 = ax1;			// 0x146b31
	sr = sr or ashift mr1 (lo), mx0 = mx0;		// 0x147c22
	sr = norm sr1 (hi), ax1 = mx1;			// 0x148d13
	sr = sr or norm mr0(hi), ax0 = ay0;		// 0x149e04
	sr = norm sr0(lo), ar = ay1;			// 0x14afa5
	sr = sr or norm ax0(lo), mr0 = my0;		// 0x14b0e6
	se = exp ax1(hi), sr1 = my1;			// 0x14c1d7
	se = exp mx0(hix), sr2 = mr2;			// 0x14d298
	se = exp mx1(lo), si = sr2;			// 0x14e3b9
	sb = expadj ay0, sr0 = ar;			// 0x14f4fa

	// computation with memory write
	dm(i0,m3)=sr0, mr=mx0*sr1(rnd);		// 0x6830f3
	mr=mx0*sr1(rnd), dm(i0,m3)=sr0;		// 0x6830f3
	pm(i1,m2)=mr0, sr=sr+mx1*my1(rnd);	// 0x6c49e6
	sr=sr+mx1*my1(rnd), pm(i1,m2)=mr0;	// 0x6c49e6
	dm(i2,m1)=sr1, sr=sr-ar*my0(rnd);	// 0x6c62d9
	sr=sr-ar*my0(rnd), dm(i2,m1)=sr1;	// 0x6c62d9
	pm(i3,m0)=mr1, sr=mr0*sr1(ss);		// 0x6c93cc
	sr=mr0*sr1(ss), pm(i3,m0)=mr1;		// 0x6c93cc
	dm(i4,m7)=si, sr=mr1*my1(su);		// 0x7cacb3
	sr=mr1*my1(su), dm(i4,m7)=si;		// 0x7cacb3
	pm(i5,m6)=ar, sr=mr2*my0(us);		// 0x7cc5a6
	sr=mr2*my0(us), pm(i5,m6)=ar;		// 0x7cc5a6
	dm(i6,m5)=sr2, mr=sr0*sr1(uu);		// 0x78f699
	mr=sr0*sr1(uu), dm(i6,m5)=sr2;		// 0x78f699
	sr=sr+sr1*my1(ss), pm(i7,m4)=mr2;	// 0x7d0f8c
	pm(i7,m4)=mr2, sr=sr+sr1*my1(ss);	// 0x7d0f8c
	dm(i4,m7)=my1, mr=mr+mx0*my0(su);	// 0x792073
	mr=mr+mx0*my0(su), dm(i4,m7)=my1;	// 0x792073
	pm(i5,m6)=my0, sr=sr+mx1*sr1(us);	// 0x7d5166
	sr=sr+mx1*sr1(us), pm(i5,m6)=my0;	// 0x7d5166
	dm(i6,m5)=ay1, mr=mr+ar*my1(uu);	// 0x796a59
	mr=mr+ar*my1(uu), dm(i6,m5)=ay1;	// 0x796a59
	pm(i7,m4)=ay0, sr=sr-mr0*my0(ss);	// 0x7d834c
	sr=sr-mr0*my0(ss), pm(i7,m4)=ay0;	// 0x7d834c
	dm(i0,m3)=mx1, mr=mr-mr1*sr1(su);	// 0x69b433
	mr=mr-mr1*sr1(su), dm(i0,m3)=mx1;	// 0x69b433
	pm(i1,m2)=mx0, sr=sr-mr2*my1(us);	// 0x6dcd26
	sr=sr-mr2*my1(us), pm(i1,m2)=mx0;	// 0x6dcd26
	dm(i2,m1)=ax1, mr=mr-sr0*my0(uu);	// 0x69e619
	mr=mr-sr0*my0(uu), dm(i2,m1)=ax1;	// 0x69e619
	
	dm(i3,m0)=ax0, ar=pass af;		// 0x6a100c
	ar=pass af, dm(i3,m0)=ax0;		// 0x6a100c
	pm(i4,m7)=sr0, af=ay1+1;		// 0x7e28f3
	af=ay1+1, pm(i4,m7)=sr0;		// 0x7e28f3
	dm(i5,m6)=mr0, ar=ax0+ay0+c;		// 0x7a40e6
	ar=ax0+ay0+c, dm(i5,m6)=mr0;		// 0x7a40e6
	pm(i6,m5)=sr1, af=ax1+af;		// 0x7e71d9
	af=ax1+af, pm(i6,m5)=sr1; 		// 0x7e71d9
	dm(i7,m4)=mr1, ar=not ay1;		// 0x7a88cc
	ar=not ay1, dm(i7,m4)=mr1;		// 0x7a88cc
	pm(i4,m7)=si, af=-ay0;			// 0x7ea0b3
	af=-ay0, pm(i4,m7)=si;			// 0x7ea0b3
	dm(i5,m6)=ar, af=ar-af+c-1;		// 0x7ed2a6
	af=ar-af+c-1, dm(i5,m6)=ar;		// 0x7ed2a6
	pm(i6,m5)=sr2, af=mr0-ay1;		// 0x7eeb99
	af=mr0-ay1, pm(i6,m5)=sr2;		// 0x7eeb99
	dm(i7,m4)=mr2, ar=ay0-1;		// 0x7b008c
	ar=ay0-1, dm(i7,m4)=mr2;		// 0x7b008c
	pm(i0,m3)=my1, af=af-mr1;		// 0x6f3473
	af=af-mr1, pm(i0,m3)=my1;		// 0x6f3473
	dm(i1,m2)=my0, ar=ay1-mr2+c-1;		// 0x6b4d66
	ar=ay1-mr2+c-1, dm(i1,m2)=my0;		// 0x6b4d66
	pm(i2,m1)=ay1, af=not sr0;		// 0x6f6659
	af=not sr0, pm(i2,m1)=ay1;		// 0x6f6659
	dm(i3,m0)=ay0, ar=sr1 and ay0;		// 0x6b874c
	ar=sr1 and ay0, dm(i3,m0)=ay0;		// 0x6b874c
	pm(i4,m7)=mx1, af=ax0 or af;		// 0x7fb033
	af=ax0 or af, pm(i4,m7)=mx1;		// 0x7fb033
	dm(i5,m6)=mx0, ar=ax1 xor ay1;		// 0x7bc926
	ar=ax1 xor ay1, dm(i5,m6)=mx0;		// 0x7bc926
	pm(i6,m5)=ax1, af=abs ar;		// 0x7fe219
	af=abs ar, pm(i6,m5)=ax1;		// 0x7fe219

	dm(i7,m4)=ax0, sr = lshift si (hi);		// 0x13080c
	sr = lshift si (hi), dm(i7,m4)=ax0;		// 0x13080c
	pm(i4,m7)=sr0, sr = sr or lshift ar (hi);	// 0x131af3
	sr = sr or lshift ar (hi), pm(i4,m7)=sr0;	// 0x131af3
	pm(i5,m6)=mr0, sr = lshift mr0 (lo);		// 0x132be6
	sr = lshift mr0 (lo), pm(i5,m6)=mr0;		// 0x132be6
	pm(i6,m5)=sr1, sr = sr or lshift mr1(lo);	// 0x133cd9
	sr = sr or lshift mr1(lo), pm(i6,m5)=sr1;	// 0x133cd9
	pm(i7,m4)=mr1, sr = ashift mr2 (hi);		// 0x134dcc
	sr = ashift mr2 (hi), pm(i7,m4)=mr1;		// 0x134dcc
	dm(i0,m3)=si, sr = sr or ashift sr0 (hi);	// 0x125eb3
	sr = sr or ashift sr0 (hi), dm(i0,m3)=si;	// 0x125eb3
	dm(i1,m2)=ar, sr = ashift sr1 (lo);		// 0x126fa6
	sr = ashift sr1 (lo), dm(i1,m2)=ar;		// 0x126fa6
	dm(i2,m1)=sr2, sr = sr or ashift si (lo);	// 0x127899
	sr = sr or ashift si (lo), dm(i2,m1)=sr2;	// 0x127899
	dm(i3,m0)=mr2, sr = norm ar (hi);		// 0x128a8c
	sr = norm ar (hi), dm(i3,m0)=mr2;		// 0x128a8c
	dm(i4,m7)=my1, sr = sr or norm mr0(hi);		// 0x139b73
	sr = sr or norm mr0(hi), dm(i4,m7)=my1;		// 0x139b73
	dm(i5,m6)=my0, sr = norm mr1(lo);		// 0x13ac66
	sr = norm mr1(lo), dm(i5,m6)=my0;		// 0x13ac66
	dm(i6,m5)=ay1, sr = sr or norm mr2(lo);		// 0x13bd59
	sr = sr or norm mr2(lo), dm(i6,m5)=ay1;		// 0x13bd59
	dm(i7,m4)=ay0, se = exp sr0(hi);		// 0x13ce4c
	se = exp sr0(hi), dm(i7,m4)=ay0;		// 0x13ce4c
	pm(i4,m7)=mx1, se = exp sr1(hix);		// 0x13df33
	se = exp sr1(hix), pm(i4,m7)=mx1;		// 0x13df33
	pm(i5,m6)=mx0, se = exp si(lo);			// 0x13e826
	se = exp si(lo), pm(i5,m6)=mx0;			// 0x13e826
	pm(i6,m5)=ax1, sb = expadj ar;			// 0x13fa19
	sb = expadj ar, pm(i6,m5)=ax1;			// 0x13fa19
	
	// data and program memory read
	ax0=dm(i1,m2),my1=pm(i5,m5);			// 0xf00056
	my1=pm(i5,m5),ax0=dm(i1,m2);			// 0xf00056
	ax1=dm(i2,m1),my0=pm(i4,m6);			// 0xe40029
	my0=pm(i4,m6),ax1=dm(i2,m1);			// 0xe40029
	mx0=dm(i3,m0),ay1=pm(i7,m7);			// 0xd800fc
	ay1=pm(i7,m7),mx0=dm(i3,m0);			// 0xd800fc
	mx1=dm(i0,m3),ay0=pm(i6,m4);			// 0xcc0083
	ay0=pm(i6,m4),mx1=dm(i0,m3);			// 0xcc0083
	ax0=dm(i1,m2),ay0=pm(i5,m5);			// 0xc00056
	ay0=pm(i5,m5),ax0=dm(i1,m2);			// 0xc00056
	ax1=dm(i2,m1),ay1=pm(i4,m6);			// 0xd40029
	ay1=pm(i4,m6),ax1=dm(i2,m1);			// 0xd40029
	mx1=dm(i3,m0),my0=pm(i7,m7);			// 0xec00fc
	my0=pm(i7,m7),mx1=dm(i3,m0);			// 0xec00fc
	mx0=dm(i0,m3),my1=pm(i6,m4);			// 0xf80083
	my1=pm(i6,m4),mx0=dm(i0,m3);			// 0xf80083

	// alu/mac with data and program memory read
	mr=mx0*sr1(rnd), ax0=dm(i1,m2),my1=pm(i5,m5);		// 0xf03056
	mr=mx0*sr1(rnd), my1=pm(i5,m5),ax0=dm(i1,m2);		// 0xf03056
	ax0=dm(i1,m2),mr=mx0*sr1(rnd), my1=pm(i5,m5);		// 0xf03056
	my1=pm(i5,m5),mr=mx0*sr1(rnd), ax0=dm(i1,m2);		// 0xf03056
	ax0=dm(i1,m2),my1=pm(i5,m5),mr=mx0*sr1(rnd);		// 0xf03056
	my1=pm(i5,m5), ax0=dm(i1,m2),mr=mx0*sr1(rnd);		// 0xf03056
	mr=mr+mx1*my1(rnd), ax1=dm(i2,m1),my0=pm(i4,m6); 	// 0xe44929
	mr=mr+mx1*my1(rnd),my0=pm(i4,m6), ax1=dm(i2,m1); 	// 0xe44929
	ax1=dm(i2,m1),mr=mr+mx1*my1(rnd), my0=pm(i4,m6); 	// 0xe44929
	my0=pm(i4,m6),mr=mr+mx1*my1(rnd), ax1=dm(i2,m1); 	// 0xe44929
	ax1=dm(i2,m1),my0=pm(i4,m6),mr=mr+mx1*my1(rnd); 	// 0xe44929
	my0=pm(i4,m6),ax1=dm(i2,m1),mr=mr+mx1*my1(rnd); 	// 0xe44929
	mr=mr-ar*my0(rnd), mx0=dm(i3,m0),ay1=pm(i7,m7);		// 0xd862fc
	mr=mr-ar*my0(rnd),ay1=pm(i7,m7), mx0=dm(i3,m0);		// 0xd862fc
	mx0=dm(i3,m0),mr=mr-ar*my0(rnd), ay1=pm(i7,m7);		// 0xd862fc
	ay1=pm(i7,m7),mr=mr-ar*my0(rnd), mx0=dm(i3,m0);		// 0xd862fc
	mx0=dm(i3,m0),ay1=pm(i7,m7),mr=mr-ar*my0(rnd);		// 0xd862fc
	ay1=pm(i7,m7), mx0=dm(i3,m0),mr=mr-ar*my0(rnd);		// 0xd862fc
	mr=mr0*sr1(ss), mx1=dm(i0,m3),ay0=pm(i6,m4);		// 0xcc9383
	mr=mr0*sr1(ss),ay0=pm(i6,m4), mx1=dm(i0,m3);		// 0xcc9383
	mx1=dm(i0,m3),mr=mr0*sr1(ss), ay0=pm(i6,m4);		// 0xcc9383
	ay0=pm(i6,m4),mr=mr0*sr1(ss), mx1=dm(i0,m3);		// 0xcc9383
	mx1=dm(i0,m3),ay0=pm(i6,m4),mr=mr0*sr1(ss);		// 0xcc9383
	ay0=pm(i6,m4),mx1=dm(i0,m3),mr=mr0*sr1(ss);		// 0xcc9383
	mr=mr1*my1(su), ax0=dm(i1,m2),ay0=pm(i5,m5);		// 0xc0ac56
	mr=mr1*my1(su),ay0=pm(i5,m5), ax0=dm(i1,m2);		// 0xc0ac56
	ax0=dm(i1,m2),mr=mr1*my1(su), ay0=pm(i5,m5);		// 0xc0ac56
	ay0=pm(i5,m5),mr=mr1*my1(su), ax0=dm(i1,m2);		// 0xc0ac56
	ax0=dm(i1,m2),ay0=pm(i5,m5),mr=mr1*my1(su);		// 0xc0ac56
	ay0=pm(i5,m5),ax0=dm(i1,m2),mr=mr1*my1(su);		// 0xc0ac56
	mr=mr2*my0(us), ax1=dm(i2,m1),ay1=pm(i4,m6);		// 0xd4c529
	mr=mr2*my0(us),ay1=pm(i4,m6), ax1=dm(i2,m1);		// 0xd4c529
	ax1=dm(i2,m1),mr=mr2*my0(us), ay1=pm(i4,m6);		// 0xd4c529
	ay1=pm(i4,m6),mr=mr2*my0(us), ax1=dm(i2,m1);		// 0xd4c529
	ax1=dm(i2,m1),ay1=pm(i4,m6),mr=mr2*my0(us);		// 0xd4c529
	ay1=pm(i4,m6), ax1=dm(i2,m1),mr=mr2*my0(us);		// 0xd4c529
	mr=sr0*sr1(uu), mx1=dm(i3,m0),my0=pm(i7,m7);		// 0xecf6fc
	mr=sr0*sr1(uu), my0=pm(i7,m7),mx1=dm(i3,m0);		// 0xecf6fc
	mx1=dm(i3,m0),mr=sr0*sr1(uu), my0=pm(i7,m7);		// 0xecf6fc
	my0=pm(i7,m7),mr=sr0*sr1(uu), mx1=dm(i3,m0);		// 0xecf6fc
	mx1=dm(i3,m0),my0=pm(i7,m7), mr=sr0*sr1(uu);		// 0xecf6fc
	my0=pm(i7,m7), mx1=dm(i3,m0),mr=sr0*sr1(uu);		// 0xecf6fc
	mr=mr+sr1*my1(ss), mx0=dm(i0,m3),my1=pm(i6,m4);		// 0xf90f83
	mr=mr+sr1*my1(ss),my1=pm(i6,m4), mx0=dm(i0,m3);		// 0xf90f83
	mx0=dm(i0,m3),mr=mr+sr1*my1(ss), my1=pm(i6,m4);		// 0xf90f83
	my1=pm(i6,m4),mr=mr+sr1*my1(ss), mx0=dm(i0,m3);		// 0xf90f83
	mx0=dm(i0,m3),my1=pm(i6,m4),mr=mr+sr1*my1(ss);		// 0xf90f83
	my1=pm(i6,m4),mx0=dm(i0,m3),mr=mr+sr1*my1(ss);		// 0xf90f83
	mr=mr+mx0*my0(su), ax0=dm(i1,m2),my1=pm(i5,m5);		// 0xf12056
	mr=mr+mx0*my0(su),my1=pm(i5,m5), ax0=dm(i1,m2);		// 0xf12056
	ax0=dm(i1,m2),mr=mr+mx0*my0(su), my1=pm(i5,m5);		// 0xf12056
	my1=pm(i5,m5), mr=mr+mx0*my0(su),ax0=dm(i1,m2);		// 0xf12056
	ax0=dm(i1,m2),my1=pm(i5,m5),mr=mr+mx0*my0(su);		// 0xf12056
	my1=pm(i5,m5), ax0=dm(i1,m2),mr=mr+mx0*my0(su);		// 0xf12056
	mr=mr+mx1*sr1(us), ax1=dm(i2,m1),my0=pm(i4,m6);		// 0xe55129
	mr=mr+mx1*sr1(us),my0=pm(i4,m6), ax1=dm(i2,m1);		// 0xe55129
	ax1=dm(i2,m1),mr=mr+mx1*sr1(us), my0=pm(i4,m6);		// 0xe55129
	my0=pm(i4,m6),mr=mr+mx1*sr1(us), ax1=dm(i2,m1);		// 0xe55129
	ax1=dm(i2,m1),my0=pm(i4,m6),mr=mr+mx1*sr1(us);		// 0xe55129
	my0=pm(i4,m6),ax1=dm(i2,m1),mr=mr+mx1*sr1(us);		// 0xe55129
	mr=mr+ar*my1(uu), mx0=dm(i3,m0),ay1=pm(i7,m7);		// 0xd96afc
	mr=mr+ar*my1(uu),ay1=pm(i7,m7), mx0=dm(i3,m0);		// 0xd96afc
	mx0=dm(i3,m0),mr=mr+ar*my1(uu), ay1=pm(i7,m7);		// 0xd96afc
	ay1=pm(i7,m7),mr=mr+ar*my1(uu), mx0=dm(i3,m0);		// 0xd96afc
	mx0=dm(i3,m0),ay1=pm(i7,m7), mr=mr+ar*my1(uu);		// 0xd96afc
	ay1=pm(i7,m7), mx0=dm(i3,m0),mr=mr+ar*my1(uu);		// 0xd96afc
	mr=mr-mr0*my0(ss), mx1=dm(i0,m3),ay0=pm(i6,m4);		// 0xcd8383
	mr=mr-mr0*my0(ss),ay0=pm(i6,m4), mx1=dm(i0,m3);		// 0xcd8383
	mx1=dm(i0,m3),mr=mr-mr0*my0(ss), ay0=pm(i6,m4);		// 0xcd8383
	ay0=pm(i6,m4),mr=mr-mr0*my0(ss), mx1=dm(i0,m3);		// 0xcd8383
	mx1=dm(i0,m3),ay0=pm(i6,m4),mr=mr-mr0*my0(ss);		// 0xcd8383
	ay0=pm(i6,m4),mx1=dm(i0,m3),mr=mr-mr0*my0(ss);		// 0xcd8383
	mr=mr-mr1*sr1(su), ax0=dm(i1,m2),ay0=pm(i5,m5);		// 0xc1b456
	mr=mr-mr1*sr1(su),ay0=pm(i5,m5), ax0=dm(i1,m2);		// 0xc1b456
	ax0=dm(i1,m2),mr=mr-mr1*sr1(su), ay0=pm(i5,m5);		// 0xc1b456
	ay0=pm(i5,m5),mr=mr-mr1*sr1(su), ax0=dm(i1,m2);		// 0xc1b456
	ax0=dm(i1,m2),ay0=pm(i5,m5), mr=mr-mr1*sr1(su);		// 0xc1b456
	ay0=pm(i5,m5),ax0=dm(i1,m2),mr=mr-mr1*sr1(su);		// 0xc1b456
	mr=mr-mr2*my1(us), ax1=dm(i2,m1),ay1=pm(i4,m6);		// 0xd5cd29
	mr=mr-mr2*my1(us),ay1=pm(i4,m6), ax1=dm(i2,m1);		// 0xd5cd29
	ax1=dm(i2,m1),mr=mr-mr2*my1(us), ay1=pm(i4,m6);		// 0xd5cd29
	ay1=pm(i4,m6),mr=mr-mr2*my1(us), ax1=dm(i2,m1);		// 0xd5cd29
	ax1=dm(i2,m1),ay1=pm(i4,m6),mr=mr-mr2*my1(us);		// 0xd5cd29
	ay1=pm(i4,m6), ax1=dm(i2,m1),mr=mr-mr2*my1(us);		// 0xd5cd29
	mr=mr-sr0*my0(uu), mx1=dm(i3,m0),my0=pm(i7,m7);		// 0xede6fc
	mr=mr-sr0*my0(uu),my0=pm(i7,m7), mx1=dm(i3,m0);		// 0xede6fc
	mx1=dm(i3,m0),mr=mr-sr0*my0(uu), my0=pm(i7,m7);		// 0xede6fc
	my0=pm(i7,m7),mr=mr-sr0*my0(uu), mx1=dm(i3,m0);		// 0xede6fc
	mx1=dm(i3,m0),my0=pm(i7,m7),mr=mr-sr0*my0(uu);		// 0xede6fc
	my0=pm(i7,m7),mx1=dm(i3,m0),mr=mr-sr0*my0(uu);		// 0xede6fc
	
	ar=pass af, mx0=dm(i0,m3),my1=pm(i6,m4);		// 0xfa1083
	ar=pass af,my1=pm(i6,m4), mx0=dm(i0,m3);		// 0xfa1083
	mx0=dm(i0,m3),ar=pass af, my1=pm(i6,m4);		// 0xfa1083
	my1=pm(i6,m4),ar=pass af, mx0=dm(i0,m3);		// 0xfa1083
	mx0=dm(i0,m3),my1=pm(i6,m4), ar=pass af;		// 0xfa1083
	my1=pm(i6,m4), mx0=dm(i0,m3),ar=pass af;		// 0xfa1083
	ar=ay1+1, ax0=dm(i1,m2),my1=pm(i5,m5);			// 0xf22856
	ar=ay1+1,my1=pm(i5,m5), ax0=dm(i1,m2);			// 0xf22856
	ax0=dm(i1,m2),ar=ay1+1, my1=pm(i5,m5);			// 0xf22856
	my1=pm(i5,m5),ar=ay1+1, ax0=dm(i1,m2);			// 0xf22856
	ax0=dm(i1,m2),my1=pm(i5,m5), ar=ay1+1;			// 0xf22856
	my1=pm(i5,m5),ax0=dm(i1,m2),ar=ay1+1;			// 0xf22856
	ar=ax0+ay0+c, ax1=dm(i2,m1),my0=pm(i4,m6);		// 0xe64029
	ar=ax0+ay0+c,my0=pm(i4,m6), ax1=dm(i2,m1);		// 0xe64029
	ax1=dm(i2,m1),ar=ax0+ay0+c, my0=pm(i4,m6);		// 0xe64029
	my0=pm(i4,m6),ar=ax0+ay0+c, ax1=dm(i2,m1);		// 0xe64029
	ax1=dm(i2,m1),my0=pm(i4,m6),ar=ax0+ay0+c;		// 0xe64029
	my0=pm(i4,m6),ax1=dm(i2,m1),ar=ax0+ay0+c;		// 0xe64029
	ar=ax1+af, mx0=dm(i3,m0),ay1=pm(i7,m7);			// 0xda71fc
	ar=ax1+af,ay1=pm(i7,m7), mx0=dm(i3,m0);			// 0xda71fc
	mx0=dm(i3,m0),ar=ax1+af, ay1=pm(i7,m7);			// 0xda71fc
	ay1=pm(i7,m7),ar=ax1+af, mx0=dm(i3,m0);			// 0xda71fc
	mx0=dm(i3,m0),ay1=pm(i7,m7), ar=ax1+af;			// 0xda71fc
	ay1=pm(i7,m7),mx0=dm(i3,m0),ar=ax1+af;			// 0xda71fc
	ar=not ay1, mx1=dm(i0,m3),ay0=pm(i6,m4);		// 0xce8883
	ar=not ay1,ay0=pm(i6,m4), mx1=dm(i0,m3);		// 0xce8883
	mx1=dm(i0,m3),ar=not ay1, ay0=pm(i6,m4);		// 0xce8883
	ay0=pm(i6,m4),ar=not ay1, mx1=dm(i0,m3);		// 0xce8883
	mx1=dm(i0,m3), ay0=pm(i6,m4),ar=not ay1;		// 0xce8883
	ay0=pm(i6,m4), mx1=dm(i0,m3),ar=not ay1;		// 0xce8883
	ar=-ay0, ax0=dm(i1,m2),ay0=pm(i5,m5);			// 0xc2a056
	ar=-ay0,ay0=pm(i5,m5), ax0=dm(i1,m2);			// 0xc2a056
	ax0=dm(i1,m2),ar=-ay0, ay0=pm(i5,m5);			// 0xc2a056
	ay0=pm(i5,m5),ar=-ay0, ax0=dm(i1,m2);			// 0xc2a056
	ax0=dm(i1,m2),ay0=pm(i5,m5), ar=-ay0;			// 0xc2a056
	ay0=pm(i5,m5), ax0=dm(i1,m2),ar=-ay0;			// 0xc2a056
	ar=ar-af+c-1, ax1=dm(i2,m1),ay1=pm(i4,m6);		// 0xd6d229
	ar=ar-af+c-1,ay1=pm(i4,m6), ax1=dm(i2,m1);		// 0xd6d229
	ax1=dm(i2,m1),ar=ar-af+c-1, ay1=pm(i4,m6);		// 0xd6d229
	ay1=pm(i4,m6),ar=ar-af+c-1, ax1=dm(i2,m1);		// 0xd6d229
	ax1=dm(i2,m1),ay1=pm(i4,m6), ar=ar-af+c-1;		// 0xd6d229
	ay1=pm(i4,m6), ax1=dm(i2,m1),ar=ar-af+c-1;		// 0xd6d229
	ar=mr0-ay1, mx1=dm(i3,m0),my0=pm(i7,m7);		// 0xeeebfc
	ar=mr0-ay1,my0=pm(i7,m7), mx1=dm(i3,m0);		// 0xeeebfc
	mx1=dm(i3,m0),ar=mr0-ay1, my0=pm(i7,m7);		// 0xeeebfc
	my0=pm(i7,m7),ar=mr0-ay1, mx1=dm(i3,m0);		// 0xeeebfc
	mx1=dm(i3,m0),my0=pm(i7,m7), ar=mr0-ay1;		// 0xeeebfc
	my0=pm(i7,m7),mx1=dm(i3,m0), ar=mr0-ay1;		// 0xeeebfc
	ar=ay0-1, mx0=dm(i0,m3),my1=pm(i6,m4);			// 0xfb0083
	ar=ay0-1,my1=pm(i6,m4), mx0=dm(i0,m3);			// 0xfb0083
	mx0=dm(i0,m3),ar=ay0-1, my1=pm(i6,m4);			// 0xfb0083
	my1=pm(i6,m4),ar=ay0-1, mx0=dm(i0,m3);			// 0xfb0083
	mx0=dm(i0,m3),my1=pm(i6,m4),ar=ay0-1;			// 0xfb0083
	my1=pm(i6,m4),mx0=dm(i0,m3),ar=ay0-1;			// 0xfb0083
	ar=af-mr1, ax0=dm(i1,m2),my1=pm(i5,m5);			// 0xf33456
	ar=af-mr1,my1=pm(i5,m5), ax0=dm(i1,m2);			// 0xf33456
	ax0=dm(i1,m2),ar=af-mr1, my1=pm(i5,m5);			// 0xf33456
	my1=pm(i5,m5),ar=af-mr1, ax0=dm(i1,m2);			// 0xf33456
	ax0=dm(i1,m2),my1=pm(i5,m5),ar=af-mr1;			// 0xf33456
	my1=pm(i5,m5), ax0=dm(i1,m2),ar=af-mr1;			// 0xf33456
	ar=ay1-mr2+c-1, ax1=dm(i2,m1),my0=pm(i4,m6);		// 0xe74d29
	ar=ay1-mr2+c-1,my0=pm(i4,m6), ax1=dm(i2,m1);		// 0xe74d29
	ax1=dm(i2,m1),ar=ay1-mr2+c-1, my0=pm(i4,m6);		// 0xe74d29
	my0=pm(i4,m6),ar=ay1-mr2+c-1, ax1=dm(i2,m1);		// 0xe74d29
	ax1=dm(i2,m1),my0=pm(i4,m6), ar=ay1-mr2+c-1;		// 0xe74d29
	my0=pm(i4,m6),ax1=dm(i2,m1), ar=ay1-mr2+c-1;		// 0xe74d29
	ar=not sr0, mx0=dm(i3,m0),ay1=pm(i7,m7);		// 0xdb66fc
	ar=not sr0,ay1=pm(i7,m7), mx0=dm(i3,m0);		// 0xdb66fc
	mx0=dm(i3,m0),ar=not sr0, ay1=pm(i7,m7);		// 0xdb66fc
	ay1=pm(i7,m7),ar=not sr0, mx0=dm(i3,m0);		// 0xdb66fc
	mx0=dm(i3,m0),ay1=pm(i7,m7), ar=not sr0;		// 0xdb66fc
	ay1=pm(i7,m7), mx0=dm(i3,m0),ar=not sr0;		// 0xdb66fc
	ar=sr1 and ay0, mx1=dm(i0,m3),ay0=pm(i6,m4);		// 0xcf8783
	ar=sr1 and ay0,ay0=pm(i6,m4), mx1=dm(i0,m3);		// 0xcf8783
	mx1=dm(i0,m3),ar=sr1 and ay0, ay0=pm(i6,m4);		// 0xcf8783
	ay0=pm(i6,m4),ar=sr1 and ay0, mx1=dm(i0,m3);		// 0xcf8783
	mx1=dm(i0,m3),ay0=pm(i6,m4),ar=sr1 and ay0;		// 0xcf8783
	ay0=pm(i6,m4),mx1=dm(i0,m3),ar=sr1 and ay0;		// 0xcf8783
	ar=ax0 or af, ax0=dm(i1,m2),ay0=pm(i5,m5);		// 0xc3b056
	ar=ax0 or af,ay0=pm(i5,m5), ax0=dm(i1,m2);		// 0xc3b056
	ax0=dm(i1,m2),ar=ax0 or af, ay0=pm(i5,m5);		// 0xc3b056
	ay0=pm(i5,m5),ar=ax0 or af, ax0=dm(i1,m2);		// 0xc3b056
	ax0=dm(i1,m2),ay0=pm(i5,m5), ar=ax0 or af;		// 0xc3b056
	ay0=pm(i5,m5), ax0=dm(i1,m2),ar=ax0 or af;		// 0xc3b056
	ar=ax1 xor ay1, ax1=dm(i2,m1),ay1=pm(i4,m6);		// 0xd7c929
	ar=ax1 xor ay1,ay1=pm(i4,m6), ax1=dm(i2,m1);		// 0xd7c929
	ax1=dm(i2,m1),ar=ax1 xor ay1, ay1=pm(i4,m6);		// 0xd7c929
	ay1=pm(i4,m6), ar=ax1 xor ay1, ax1=dm(i2,m1);		// 0xd7c929
	ax1=dm(i2,m1),ay1=pm(i4,m6),ar=ax1 xor ay1;		// 0xd7c929
	ax1=dm(i2,m1),ay1=pm(i4,m6), ar=ax1 xor ay1;		// 0xd7c929
	ar=abs ar, mx1=dm(i3,m0),my0=pm(i7,m7);			// 0xefe2fc
	ar=abs ar,my0=pm(i7,m7), mx1=dm(i3,m0);			// 0xefe2fc
	mx1=dm(i3,m0),ar=abs ar, my0=pm(i7,m7);			// 0xefe2fc
	my0=pm(i7,m7),ar=abs ar, mx1=dm(i3,m0);			// 0xefe2fc
	mx1=dm(i3,m0),my0=pm(i7,m7),ar=abs ar;			// 0xefe2fc
	my0=pm(i7,m7),mx1=dm(i3,m0),ar=abs ar;			// 0xefe2fc

Pservice_proc:
	rts;					// 0x0a00f0

Pscale_down:
	jump not_symbol;			// 0x1c0000
