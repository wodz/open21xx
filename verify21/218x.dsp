/*
 * 218x.dsp
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
	.var/circ roundbuf[5] ={0x1234,0x5678,0x9abc,0xdef0,0x1234};	// &=8 0x1234 0x5678 0x9abc 0xdef0 0x1234
	
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

    .var addr_expdm[] = { 0, 1, 2, extpm+3, extdm-5};       // 0 1 2 0 0
    .var = {-3+extpm};                                      // 0
    .var = {2+extdm};                                       // 0
    .var addr_expdm_2[] = { -1, -5000, -0x8000};       // 0xffff 0xec78 0x8000

	.section/code program0;
	.var / init24 q1=0x123456;		// = 0 0x123456
	.align 8;				// = 8
	.var/circ/init24 q3={0x12345}, q4={123};	// = 8 0x12345 123
	.var q2=0x4321;				// 0x432100
	.align 32;
	.var q5;				// = 32 0
	.align 16;
	.var q6;				// = 48 0
	.var/circ q7[20]={1,2,3};		// = 64 0x100 0x200 0x300 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
	.var codelimit1={-0x8000},		// (0x8000<<8)
	     codelimit2={0},			// 0
	     codelimit3={0x7fff},		// (0x7fff<<8)
	     codelimit4={0xffff};		// (0xffff<<8)
	.var/init24 codelimit5={-0x800000},	// 0x800000
		    codelimit6={0},		// 0
		    codelimit7={0x7fffff},	// 0x7fffff
	 	    codelimit8={0xffffff};	// 0xffffff

    .var addr_exppm[] = { 0, 1, 2, extpm+3, extdm-5};       // 0x000000 0x000100 0x000200 0x000000 0x000000
    .var = -3+extpm;                                        // 0x000000
    .var = 2+extdm;                                         // 0x000000
    .var/init24 addr_exppm24[] = { 0, 1, 2, extpm+3, extdm-5};  // 0x000000 0x000001 0x00002 0x000000 0x000000
    .var/init24 = -3+extpm;                                 // 0x000000
    .var/init24 = 2+extdm;                                  // 0x000000
    .var/init24 addr_exppm24_2[] = { -1, -5000, -0x800000 };  // 0xffffff 0xffec78 0x800000

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
	if ge ar = ax0+ay0;   			// 0x226005
	if lt ar = ax0+ay0;   			// 0x226004
	if le ar = ax0+ay0;   			// 0x226003
	if neg ar = ax0+ay0;   			// 0x22600a
	if pos ar = ax0+ay0;   			// 0x22600b
	if av ar = ax0+ay0;   			// 0x226006
	if not av ar = ax0+ay0; 		// 0x226007
	if ac ar = ax0+ay0;   			// 0x226008
	if not ac ar = ax0+ay0; 		// 0x226009
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
	divs AY1, AX0;				// 0x060800
	divs af, AX0;				// 0x061000
	divs AY1, AX1;				// 0x060900
	divs AF, AX1;				// 0x061100
	divs AY1, AR;				// 0x060a00
	divs AF, AR;				// 0x061200
	divs AY1, MR2;				// 0x060d00
	divs AF, MR2;				// 0x061500
	divs AY1, MR1;				// 0x060c00
	divs AF, MR1;				// 0x061400
	divs AY1, Mr0;				// 0x060b00
	divs AF, Mr0;				// 0x061300
	divs AY1, sR1;				// 0x060f00
	divs AF, sR1;				// 0x061700
	divs AY1, sR0;				// 0x060e00
	divs AF, sR0;				// 0x061600
	
	divq ax0;				// 0x071000
	divq ax1;				// 0x071100
	divq ar;				// 0x071200
	divq mr2;				// 0x071500
	divq mr1;				// 0x071400
	divq mr0;				// 0x071300
	divq sr1;				// 0x071700
	divq sr0;				// 0x071600
	
generate_alu_status_symbol:
	// generate alu status
	NONE=ax0-ay0;				// 0x2ae0aa
	NONE=pass sr0;				// 0x2a7eaa

multiply_symbol:
	// multiply
	mr=mx0*my0(ss);				// 0x20800f
	mr=mx0*my1(su);				// 0x20a80f
	mr=mx0*mf(us);				// 0x20d00f
	mr=mx1*my0(uu);				// 0x20e10f
	mr=mx1*my1(rnd);			// 0x20290f
	mr=mx1*mf(ss);				// 0x20910f
	mr=ar*my0(su);				// 0x20a20f
	mr=ar*my1(us);				// 0x20ca0f
	mr=ar*mf(uu);				// 0x20f20f
	mr=mr0*my0(rnd);			// 0x20230f
	mr=mr0*my1(ss);				// 0x208b0f
	mr=mr0*mf(su);				// 0x20b30f
	mf=mr1*my0(us);				// 0x24c40f
	mf=mr1*my1(uu);				// 0x24ec0f
	mf=mr1*mf(rnd);				// 0x24340f
	mf=mr2*my0(ss);				// 0x24850f
	mf=mr2*my1(su);				// 0x24ad0f
	mf=mr2*mf(us);				// 0x24d50f
	mf=sr0*my0(uu);				// 0x24e60f
	mf=sr0*my1(rnd);			// 0x242e0f
	mf=sr0*mf(ss);				// 0x24960f
	mf=sr1*my0(su);				// 0x24a70f
	mf=sr1*my1(us);				// 0x24cf0f
	mf=sr1*mf(uu);				// 0x24f70f

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
	mf=mr-mr0*my1(ss);			// 0x258b0f
	mf=mr-mr0*my1(su);			// 0x25ab0f
	mf=mr-mr0*my1(us);			// 0x25cb0f
	mf=mr-mr0*my1(uu);			// 0x25eb0f
	mf=mr-mr0*my1(rnd);			// 0x246b0f

	mr=mr-mr2*mr2(ss);			// 0x21851f
	mr=mr-mr2*mr2(uu);			// 0x21e51f
	mr=mr-mr2*mr2(rnd);			// 0x20651f

clear_symbol:
	// clear
	mr=0;					// 0x20980f
	mf=0;					// 0x24980f

	// transfer mr
	if eq mr=mr;				// 0x211800
	if ne mf=mr(rnd);			// 0x245801

	// conditional mr saturation
	if mv sat mr;				// 0x050000
	
	// arithmetic shift
	sr=ashift si(lo);			// 0x0e300f
	sr=ashift ar(lo);			// 0x0e320f
	sr=ashift mr0(lo);			// 0x0e330f
	sr=ashift mr1(lo);			// 0x0e340f
	sr=ashift mr2(lo);			// 0x0e350f
	sr=ashift sr0(lo);			// 0x0e360f
	sr=ashift sr1(lo);			// 0x0e370f
	sr=ashift si(hi);			// 0x0e200f
	sr=ashift ar(hi);			// 0x0e220f
	sr=ashift mr0(hi);			// 0x0e230f
	sr=ashift mr1(hi);			// 0x0e240f
	sr=ashift mr2(hi);			// 0x0e250f
	sr=ashift sr0(hi);			// 0x0e260f
	sr=ashift sr1(hi);			// 0x0e270f
	sr=sr or ashift si(lo);			// 0x0e380f
	sr=sr or ashift ar(lo);			// 0x0e3a0f
	sr=sr or ashift mr0(lo);		// 0x0e3b0f
	sr=sr or ashift mr1(lo);		// 0x0e3c0f
	sr=sr or ashift mr2(lo);		// 0x0e3d0f
	sr=sr or ashift sr0(lo);		// 0x0e3e0f
	sr=sr or ashift sr1(lo);		// 0x0e3f0f
	sr=sr or ashift si(hi);			// 0x0e280f
	sr=sr or ashift ar(hi);			// 0x0e2a0f
	sr=sr or ashift mr0(hi);		// 0x0e2b0f
	sr=sr or ashift mr1(hi);		// 0x0e2c0f
	sr=sr or ashift mr2(hi);		// 0x0e2d0f
	sr=sr or ashift sr0(hi);		// 0x0e2e0f
	sr=sr or ashift sr1(hi);		// 0x0e2f0f

	// logical shift
	sr=lshift si(lo);			// 0x0e100f
	sr=lshift ar(hi);			// 0x0e020f
	sr=sr or lshift mr0(lo);		// 0x0e1b0f
	sr=sr or lshift mr1(hi);		// 0x0e0c0f

	// normalize
	sr=norm mr2(lo);			// 0x0e550f
	sr=norm sr0(hi);			// 0x0e460f
	sr=sr or norm sr1(lo);			// 0x0e5f0f
	sr=sr or norm si(hi);			// 0x0e480f
	
	// derive exponent
	se=exp ar(lo);				// 0x0e720f
	se=exp mr0(hi);				// 0x0e630f
	se=exp mr1(hix);			// 0x0e6c0f

	// exponent adjust
	sb=expadj mr2;				// 0x0e7d0f

	// arithmetic shift immediate
	sr=ashift si by -128(lo);		// 0x0f3080
	sr=ashift si by 0(lo);			// 0x0f3000
	sr=ashift si by 127(lo);		// 0x0f307f
	sr=ashift si by -128(hi);		// 0x0f2080
	sr=ashift si by 0(hi);			// 0x0f2000
	sr=ashift si by 127(hi);		// 0x0f207f
	sr=sr or ashift si by -128(lo);		// 0x0f3880
	sr=sr or ashift si by 0(lo);		// 0x0f3800
	sr=sr or ashift si by 127(lo);		// 0x0f387f
	sr=sr or ashift si by -128(hi);		// 0x0f2880
	sr=sr or ashift si by 0(hi);		// 0x0f2800
	sr=sr or ashift si by 127(hi);		// 0x0f287f
	
	// logical shift immediate
	sr=lshift si by -128(lo);		// 0x0f1080
	sr=lshift si by 0(lo);			// 0x0f1000
	sr=lshift si by 127(lo);		// 0x0f107f
	sr=lshift si by -128(hi);		// 0x0f0080
	sr=lshift si by 0(hi);			// 0x0f0000
	sr=lshift si by 127(hi);		// 0x0f007f
	sr=sr or lshift si by -128(lo);		// 0x0f1880
	sr=sr or lshift si by 0(lo);		// 0x0f1800
	sr=sr or lshift si by 127(lo);		// 0x0f187f
	sr=sr or lshift si by -128(hi);		// 0x0f0880
	sr=sr or lshift si by 0(hi);		// 0x0f0800
	sr=sr or lshift si by 127(hi);		// 0x0f087f
	
	// register move
	ax0=si;					// 0x0d0008
	ax1=se;					// 0x0d0019
	mx0=l0;					// 0x0d0128
	mx1=l1;					// 0x0d0139
	ay0=l4;					// 0x0d0248
	ay1=l5;					// 0x0d0259
	my0=rx0;				// 0x0d0368
	my1=tx0;				// 0x0d0379
	si=ar;					// 0x0d008a
	se=mr0;					// 0x0d009b
	ar=l2;					// 0x0d01aa
	mr0=l3;					// 0x0d01bb
	mr1=l6;					// 0x0d02ca
	mr2=l7;					// 0x0d02db
	sr0=rx1;				// 0x0d03ea
	sr1=tx1;				// 0x0d03fb

	i0=mr1;					// 0x0d040c
	i1=mr2;					// 0x0d041d
	i2=i0;					// 0x0d0520
	i3=i1;					// 0x0d0531
	m0=i4;					// 0x0d0640
	m1=i5;					// 0x0d0651
	m2=astat;				// 0x0d0760
	m3=mstat;				// 0x0d0771
	l0=sr0;					// 0x0d048e
	l1=sr1;					// 0x0d049f
	l2=i2;					// 0x0d05a2
	l3=i3;					// 0x0d05b3

	i4=ax0;					// 0x0d0800
	i5=ax1;					// 0x0d0811
	i6=m0;					// 0x0d0924
	i7=m1;					// 0x0d0935
	m4=m5;					// 0x0d0a45
	m5=m4;					// 0x0d0a54
	m6=sstat;				// 0x0d0b62
	m7=imask;				// 0x0d0b73
	l4=mx0;					// 0x0d0882
	l5=mx1;					// 0x0d0893
	l6=m6;					// 0x0d0aa6
	l7=m7;					// 0x0d0ab7

	AStat=ay0;				// 0x0d0c04
	mstat=ay1;				// 0x0d0c15
	/* sstat */
	imask=m2;				// 0x0d0d36
	icntl=m3;				// 0x0d0d47
	CNTR=l4;				// 0x0d0e58
	sb=l5;					// 0x0d0e69
	px=icntl;				// 0x0d0f74
	rx0=cntr;				// 0x0d0f85
	tx0=my0;				// 0x0d0c96
	rx1=my1;				// 0x0d0ca7
	tx1=l0;					// 0x0d0db8
	ifc=l1;					// 0x0d0dc9
	owrcntr=l6;				// 0x0d0eda

	ax0=sb;					// 0x0d0306
	ax1=px;					// 0x0d0317

	// load register immediate
	ax0=0;					// 0x400000
	ax1=0xffff;				// 0x4ffff1
	mx0=0;					// 0x400002
	mx1=0;					// 0x400003
	ay0=0;					// 0x400004
	ay1=0;					// 0x400005
	my0=0;					// 0x400006
	my1=0;					// 0x400007
	si=0;					// 0x400008
	se=0;					// 0x400009
	ar=0;					// 0x40000a
	mr0=0;					// 0x40000b
	mr1=0;					// 0x40000c
	mr2=0;					// 0x40000d
	sr0=0;					// 0x40000e
	sr1=0;					// 0x40000f

	i0=0;					// 0x340000
	i1=0x3fff;				// 0x37fff1
	i2=0;					// 0x340002
	i3=0;					// 0x340003
	m0=0;					// 0x340004
	m1=0;					// 0x340005
	m2=0;					// 0x340006
	m3=0;					// 0x340007
	l0=0;					// 0x340008
	l1=0;					// 0x340009
	l2=0;					// 0x34000a
	l3=0;					// 0x34000b
	pmovlay=0;				// 0x34000e
	dmovlay=0;				// 0x34000f

	i4=0;					// 0x380000
	i5=0x3fff;				// 0x3bfff1
	i6=0;					// 0x380002
	i7=0;					// 0x380003
	m4=0;					// 0x380004
	m5=0;					// 0x380005
	m6=0;					// 0x380006
	m7=0;					// 0x380007
	l4=0;					// 0x380008
	l5=0;					// 0x380009
	l6=0;					// 0x38000a
	l7=0;					// 0x38000b

	astat=0;				// 0x3c0000
	mstat=0x3fff;				// 0x3ffff1
	/* sstat=0; */
	imask=0;				// 0x3c0003
	icntl=0;				// 0x3c0004
	cntr=0;					// 0x3c0005
	sb=0;					// 0x3c0006
	px=0;					// 0x3c0007
	rx0=0;					// 0x3c0008
	tx0=0;					// 0x3c0009
	rx1=0;					// 0x3c000a
	tx1=0;					// 0x3c000b
	ifc=0;					// 0x3c000c
	owrcntr=0;				// 0x3c000d

	ax0=LENGTH(roundbuf);		// 0x400000
	mx0=roundbuf;				// 0x400002
	ay1=roundbuf+0x38;			// 0x400005
	my1=roundbuf+0xffff;			// 0x400007
	i3=roundbuf;				// 0x340003
	m6=roundbuf+0x79;			// 0x380006
	imask=roundbuf+0x3fff;			// 0x3c0003
	owrcntr=LENGTH(roundbuf);		// 0x3c000d
    ar = length(bufName9);          // 0x40000a
character_constants:
    ar = 'A';                       // 0x40041a
    ar = '\x234';                   // 0x40234a
    ar = '\0';                      // 0x40000a
extern_addrs:
	ar = extpm + 3;	                // 0x40000a
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
	si=dm(some_data);			// 0x800008
	se=dm(some_data);			// 0x800009
	ar=dm(some_data);			// 0x80000a
	mr0=dm(some_data);			// 0x80000b
	mr1=dm(some_data);			// 0x80000c
	mr2=dm(some_data);			// 0x80000d
	sr0=dm(some_data);			// 0x80000e
	sr1=dm(some_data);			// 0x80000f

	i0=dm(some_data);			// 0x840000
	i1=dm(some_data);			// 0x840001
	i2=dm(some_data);			// 0x840002
	i3=dm(some_data);			// 0x840003
	m0=dm(some_data);			// 0x840004
	m1=dm(some_data);			// 0x840005
	m2=dm(some_data);			// 0x840006
	m3=dm(some_data);			// 0x840007
	l0=dm(some_data);			// 0x840008
	l1=dm(some_data);			// 0x840009
	l2=dm(some_data);			// 0x84000a
	l3=dm(some_data);			// 0x84000b

	i4=dm(some_data);			// 0x880000
	i5=dm(some_data);			// 0x880001
	i6=dm(some_data);			// 0x880002
	i7=dm(some_data);			// 0x880003
	m4=dm(some_data);			// 0x880004
	m5=dm(some_data);			// 0x880005
	m6=dm(some_data);			// 0x880006
	m7=dm(some_data);			// 0x880007
	l4=dm(some_data);			// 0x880008
	l5=dm(some_data);			// 0x880009
	l6=dm(some_data);			// 0x88000a
	l7=dm(some_data);			// 0x88000b

	astat=dm(some_data);			// 0x8c0000
	mstat=dm(some_data);			// 0x8c0001
	/* sstat=dm(some_data);	*/
	imask=dm(some_data);			// 0x8c0003
	icntl=dm(some_data);			// 0x8c0004
	cntr=dm(some_data);			// 0x8c0005
	sb=dm(some_data);			// 0x8c0006
	px=dm(some_data);			// 0x8c0007
	rx0=dm(some_data);			// 0x8c0008
	tx0=dm(some_data);			// 0x8c0009
	rx1=dm(some_data);			// 0x8c000a
	tx1=dm(some_data);			// 0x8c000b
	ifc=dm(some_data);			// 0x8c000c
	owrcntr=dm(some_data);			// 0x8c000d
	ax0=dm(0);				// 0x800000
	ax1=dm(0x3fff);				// 0x83fff1
	ax0=dm(some_data+5);			// 0x800000

	// Data Memory Write (Indirect address)
	ax0=DM(I0,m3);				// 0x600003
	ax1=dm(i1,m2);				// 0x600016
	mx0=dm(i2,m1);				// 0x600029
	mx1=dm(i3,m0);				// 0x60003c
	ay0=dm(i4,m7);				// 0x700043
	ay1=dm(i5,m6);				// 0x700056
	my0=dm(i6,m5);				// 0x700069
	my1=dm(i7,m4);				// 0x70007c
	si=dm(i0,m0);				// 0x600080
	se=dm(i1,m1);				// 0x600095
	ar=dm(i2,m2);				// 0x6000aa
	mr0=dm(i3,m3);				// 0x6000bf
	mr1=dm(i4,m4);				// 0x7000c0
	mr2=dm(i5,m5);				// 0x7000d5
	sr0=dm(i6,m6);				// 0x7000ea
	sr1=dm(i7,m7);				// 0x7000ff
	
	// Program Memory Read
	ax0=PM(I7,m4);				// 0x50000c
	ax1=pm(i7,m5);				// 0x50001d
	mx0=pm(i7,m6);				// 0x50002e
	mx1=pm(i7,m7);				// 0x50003f
	ay0=pm(i6,m4);				// 0x500048
	ay1=pm(i6,m5);				// 0x500059
	my0=pm(i6,m6);				// 0x50006a
	my1=pm(i6,m7);				// 0x50007b
	si=pm(i5,m4);				// 0x500084
	se=pm(i5,m5);				// 0x500095
	ar=pm(i5,m6);				// 0x5000a6
	mr0=pm(i5,m7);				// 0x5000b7
	mr1=pm(i4,m4);				// 0x5000c0
	mr2=pm(i4,m5);				// 0x5000d1
	sr0=pm(i4,m6);				// 0x5000e2
	sr1=pm(i4,m7);				// 0x5000f3

	// Data Memory Write (Direct Address)
	dm(some_data) = ax0;			// 0x900000
	dm(some_data) = ax1;			// 0x900001
	dm(some_data) = mx0;			// 0x900002
	dm(some_data) = mx1;			// 0x900003
	dm(some_data) = ay0;			// 0x900004
	dm(some_data) = ay1;			// 0x900005
	dm(some_data) = my0;			// 0x900006
	dm(some_data) = my1;			// 0x900007
	dm(some_data) = si;			// 0x900008
	dm(some_data) = se;			// 0x900009
	dm(some_data) = ar;			// 0x90000a
	dm(some_data) = mr0;			// 0x90000b
	dm(some_data) = mr1;			// 0x90000c
	dm(some_data) = mr2;			// 0x90000d
	dm(some_data) = sr0;			// 0x90000e
	dm(some_data) = sr1;			// 0x90000f

	dm(some_data) = i0;			// 0x940000
	dm(some_data) = i1;			// 0x940001
	dm(some_data) = i2;			// 0x940002
	dm(some_data) = i3;			// 0x940003
	dm(some_data) = m0;			// 0x940004
	dm(some_data) = m1;			// 0x940005
	dm(some_data) = m2;			// 0x940006
	dm(some_data) = m3;			// 0x940007
	dm(some_data) = l0;			// 0x940008
	dm(some_data) = l1;			// 0x940009
	dm(some_data) = l2;			// 0x94000a
	dm(some_data) = l3;			// 0x94000b

	dm(some_data) = i4;			// 0x980000
	dm(some_data) = i5;			// 0x980001
	dm(some_data) = i6;			// 0x980002
	dm(some_data) = i7;			// 0x980003
	dm(some_data) = m4;			// 0x980004
	dm(some_data) = m5;			// 0x980005
	dm(some_data) = m6;			// 0x980006
	dm(some_data) = m7;			// 0x980007
	dm(some_data) = l4;			// 0x980008
	dm(some_data) = l5;			// 0x980009
	dm(some_data) = l6;			// 0x98000a
	dm(some_data) = l7;			// 0x98000b

	dm(some_data) = astat;			// 0x9c0000
	dm(some_data) = mstat;			// 0x9c0001
	dm(some_data) = sstat;			// 0x9c0002
	dm(some_data) = imask;			// 0x9c0003
	dm(some_data) = icntl;			// 0x9c0004
	dm(some_data) = cntr;			// 0x9c0005
	dm(some_data) = sb;			// 0x9c0006
	dm(some_data) = px;			// 0x9c0007
	dm(some_data) = rx0;			// 0x9c0008
	dm(some_data) = tx0;			// 0x9c0009
	dm(some_data) = rx1;			// 0x9c000a
	dm(some_data) = tx1;			// 0x9c000b
	dm(0) = ax0;				// 0x900000
	dm(0x3fff) = ax1;			// 0x93fff1
    dm(extdm-5) = ax1;          // 0x900001

	// Data Memory Write (Indirect Address)
	DM(I0,m3)=ax0;				// 0x680003
	dm(i1,m2)=ax1;				// 0x680016
	dm(i2,m1)=mx0;				// 0x680029
	dm(i3,m0)=mx1;				// 0x68003c
	dm(i4,m7)=ay0;				// 0x780043
	dm(i5,m6)=ay1;				// 0x780056
	dm(i6,m5)=my0;				// 0x780069
	dm(i7,m4)=my1;				// 0x78007c
	dm(i0,m0)=si;				// 0x680080
	dm(i1,m1)=se;				// 0x680095
	dm(i2,m2)=ar;				// 0x6800aa
	dm(i3,m3)=mr0;				// 0x6800bf
	dm(i4,m4)=mr1;				// 0x7800c0
	dm(i5,m5)=mr2;				// 0x7800d5
	dm(i6,m6)=sr0;				// 0x7800ea
	dm(i7,m7)=sr1;				// 0x7800ff

	dm(i0,m3) = 0;				// 0xa00003
	dm(i1,m2) = 0xffff;			// 0xaffff6
	dm(i2,m1) = 0;				// 0xa00009
	dm(i3,m0) = 0xffff;			// 0xaffffc
	dm(i4,m6) = 0;				// 0xb00002
	dm(i5,m7) = 0xffff;			// 0xbffff7
	dm(i6,m4) = 0;				// 0xb00008
	dm(i7,m5) = 0xffff;			// 0xbffffd
	dm(i7,m5) = extpm+3;		// 0xb0000d
	dm(i7,m5) = extdm-5;		// 0xb0000d

	// Program Memory Write (Indirect Address)
	PM(I7,m4)=ax0;				// 0x58000c
	pm(i7,m5)=ax1;				// 0x58001d
	pm(i7,m6)=mx0;				// 0x58002e
	pm(i7,m7)=mx1;				// 0x58003f
	pm(i6,m4)=ay0;				// 0x580048
	pm(i6,m5)=ay1;				// 0x580059
	pm(i6,m6)=my0;				// 0x58006a
	pm(i6,m7)=my1;				// 0x58007b
	pm(i5,m4)=si;				// 0x580084
	pm(i5,m5)=se;				// 0x580095
	pm(i5,m6)=ar;				// 0x5800a6
	pm(i5,m7)=mr0;				// 0x5800b7
	pm(i4,m4)=mr1;				// 0x5800c0
	pm(i4,m5)=mr2;				// 0x5800d1
	pm(i4,m6)=sr0;				// 0x5800e2
	pm(i4,m7)=sr1;				// 0x5800f3
	
	// IO space read/write
	IO(0)=ax0;				// 0x018000
	IO(511)=ax1;				// 0x019ff1
	IO(2047)=mx0;				// 0x01fff2
	IO(0)=mx1;				// 0x018003
	IO(0)=ay0;				// 0x018004
	IO(0)=ay1;				// 0x018005
	IO(0)=my0;				// 0x018006
	IO(0)=my1;				// 0x018007
	IO(0)=si;				// 0x018008
	IO(0)=se;				// 0x018009
	IO(0)=ar;				// 0x01800a
	IO(0)=mr0;				// 0x01800b
	IO(0)=mr1;				// 0x01800c
	IO(0)=mr2;				// 0x01800d
	IO(0)=sr0;				// 0x01800e
	IO(0)=sr1;				// 0x01800f

	ax0 = IO(0);				// 0x010000
	ax1 = IO(511);				// 0x011ff1
	mx0=IO(2047);				// 0x017ff2
	mx1=IO(0);				// 0x010003
	ay0=IO(0);				// 0x010004
	ay1=IO(0);				// 0x010005
	my0=IO(0);				// 0x010006
	my1=IO(0);				// 0x010007
	si=IO(0);				// 0x010008
	se=IO(0);				// 0x010009
	ar=IO(0);				// 0x01000a
	mr0=IO(0);				// 0x01000b
	mr1=IO(0);				// 0x01000c
	mr2=IO(0);				// 0x01000d
	sr0=IO(0);				// 0x01000e
	sr1=IO(0);				// 0x01000f

	// JUMP
Ptop_loop:
	jump Ptop_loop;				// 0x18000f
	jump (i7);				    // 0x0b00cf
	jump 0;					    // 0x18000f
	jump 0x3fff;				// 0x1bffff
	jump Ptop_loop+10;			// 0x18000f

	// call
	call Pscale_down;			// 0x1c000f
	call (i4);				// 0x0b001f
	call 0;					// 0x1c000f
	call 0x3fff;				// 0x1fffff
	call Pscale_down+25;			// 0x1c000f

	// jump or call on flag in pin
	if flag_in jump Pservice_proc;		// 0x030002
	if flag_in jump 0;			        // 0x030002
	if not flag_in jump 0x3fff;		    // 0x03fffc
	if flag_in jump Ptop_loop+10;		// 0x030002
	if not flag_in jump Ptop_loop-10;	// 0x030000
	if not flag_in call Pservice_proc;	// 0x030001
	if not flag_in call 0;			    // 0x030001
	if flag_in call 0x3fff;			    // 0x03ffff


	// Modify flag out pin
	set flag_out;				// 0x02003f
	set fl0;				// 0x0200cf
	set fl1;				// 0x02030f
	set fl2;				// 0x020c0f
	reset flag_out;				// 0x02002f
	reset fl0;				// 0x02008f
	reset fl1;				// 0x02020f
	reset fl2;				// 0x02080f
	toggle flag_out;			// 0x02001f
	toggle fl0;				// 0x02004f
	toggle fl1;				// 0x02010f
	toggle fl2;				// 0x02040f
	set flag_out, reset fl1, toggle fl2, reset fl0; 	// 0x0206bf
	
	// rts
	if le rts;				// 0x0a0003

	//rti
	if mv rti;				// 0x0a001c

	// do until
	do Ploop until ne;			// 0x140000
	do Ploop until eq;			// 0x140001
	do Ploop until le;			// 0x140002
	do Ploop until gt;			// 0x140003
	do Ploop until ge;			// 0x140004
	do Ploop until lt;			// 0x140005
	do Ploop until not av;		// 0x140006
	do Ploop until av;			// 0x140007
	do Ploop until not ac;		// 0x140008
	do Ploop until ac;			// 0x140009
	do Ploop until pos;			// 0x14000a
	do Ploop until neg;			// 0x14000b
	do Ploop until not mv;		// 0x14000c
	do Ploop until mv;			// 0x14000d
	do Ploop until ce;			// 0x14000e
	do Ploop until forever;		// 0x14000f
    do extpm-10 until ce;       // 0x14000e

	// idle
	idle;					// 0x028000
	idle (16);				// 0x028001
	idle (32);				// 0x028002
	idle (64);				// 0x028004
	idle (128);				// 0x028008

	// stack control
	pop cntr, pop pc, pop loop, pop sts;	// 0x04001f
	push sts;				// 0x040002

	// topstack
	ax0=toppcstack;				// 0x0d030f
	ax1=toppcstack;				// 0x0d031f
	mx0=toppcstack;				// 0x0d032f
	mx1=toppcstack;				// 0x0d033f
	ay0=toppcstack;				// 0x0d034f
	ay1=toppcstack;				// 0x0d035f
	my0=toppcstack;				// 0x0d036f
	my1=toppcstack;				// 0x0d037f
	si=toppcstack;				// 0x0d038f
	se=toppcstack;				// 0x0d039f
	ar=toppcstack;				// 0x0d03af
	mr0=toppcstack;				// 0x0d03bf
	mr1=toppcstack;				// 0x0d03cf
	mr2=toppcstack;				// 0x0d03df
	sr0=toppcstack;				// 0x0d03ef
	sr1=toppcstack;				// 0x0d03ff
	i0=toppcstack;				// 0x0d070f
	i1=toppcstack;				// 0x0d071f
	i2=toppcstack;				// 0x0d072f
	i3=toppcstack;				// 0x0d073f
	m0=toppcstack;				// 0x0d074f
	m1=toppcstack;				// 0x0d075f
	m2=toppcstack;				// 0x0d076f
	m3=toppcstack;				// 0x0d077f
	l0=toppcstack;				// 0x0d078f
	l1=toppcstack;				// 0x0d079f
	l2=toppcstack;				// 0x0d07af
	l3=toppcstack;				// 0x0d07bf
	i4=toppcstack;				// 0x0d0b0f
	i5=toppcstack;				// 0x0d0b1f
	i6=toppcstack;				// 0x0d0b2f
	i7=toppcstack;				// 0x0d0b3f
	m4=toppcstack;				// 0x0d0b4f
	m5=toppcstack;				// 0x0d0b5f
	m6=toppcstack;				// 0x0d0b6f
	m7=toppcstack;				// 0x0d0b7f
	l4=toppcstack;				// 0x0d0b8f
	l5=toppcstack;				// 0x0d0b9f
	l6=toppcstack;				// 0x0d0baf
	l7=toppcstack;				// 0x0d0bbf
		
	toppcstack=ax0;				// 0x0d0cf0
	toppcstack=ax1;				// 0x0d0cf1
	toppcstack=mx0;				// 0x0d0cf2
	toppcstack=mx1;				// 0x0d0cf3
	toppcstack=ay0;				// 0x0d0cf4
	toppcstack=ay1;				// 0x0d0cf5
	toppcstack=my0;				// 0x0d0cf6
	toppcstack=my1;				// 0x0d0cf7
	toppcstack=si;				// 0x0d0cf8
	toppcstack=se;				// 0x0d0cf9
	toppcstack=ar;				// 0x0d0cfa
	toppcstack=mr0;				// 0x0d0cfb
	toppcstack=mr1;				// 0x0d0cfc
	toppcstack=mr2;				// 0x0d0cfd
	toppcstack=sr0;				// 0x0d0cfe
	toppcstack=sr1;				// 0x0d0cff
	toppcstack=i0;				// 0x0d0df0
	toppcstack=i1;				// 0x0d0df1
	toppcstack=i2;				// 0x0d0df2
	toppcstack=i3;				// 0x0d0df3
	toppcstack=m0;				// 0x0d0df4
	toppcstack=m1;				// 0x0d0df5
	toppcstack=m2;				// 0x0d0df6
	toppcstack=m3;				// 0x0d0df7
	toppcstack=l0;				// 0x0d0df8
	toppcstack=l1;				// 0x0d0df9
	toppcstack=l2;				// 0x0d0dfa
	toppcstack=l3;				// 0x0d0dfb
	toppcstack=i4;				// 0x0d0ef0
	toppcstack=i5;				// 0x0d0ef1
	toppcstack=i6;				// 0x0d0ef2
	toppcstack=i7;				// 0x0d0ef3
	toppcstack=m4;				// 0x0d0ef4
	toppcstack=m5;				// 0x0d0ef5
	toppcstack=m6;				// 0x0d0ef6
	toppcstack=m7;				// 0x0d0ef7
	toppcstack=l4;				// 0x0d0ef8
	toppcstack=l5;				// 0x0d0ef9
	toppcstack=l6;				// 0x0d0efa
	toppcstack=l7;				// 0x0d0efb

Ploop:
	// Mode control
	ENA bit_rev;				// 0x0c00c0
	ENA av_latch;				// 0x0c0300
	ENA ar_sat;				// 0x0c0c00
	ENA sec_reg;				// 0x0c0030
	ENA g_mode;				// 0x0c000c
	ENA m_mode;				// 0x0c3000
	ENA timer;				// 0x0cc000
	DIS bit_rev;				// 0x0c0080
	DIS av_latch;				// 0x0c0200
	DIS ar_sat;				// 0x0c0800
	DIS sec_reg;				// 0x0c0020
	DIS g_mode;				// 0x0c0008
	DIS m_mode;				// 0x0c2000
	DIS timer;				// 0x0c8000
	// should be ENA bit_rev, dis av_latch, ...;
	ENA bit_rev, ENA av_latch, ena ar_sat,
	ena sec_reg, ena g_mode, ena m_mode, ena timer;	// 0x0cfffc
	DIS bit_rev, DIS av_latch, DIS ar_sat,
	DIS sec_reg, dis g_mode, dis m_mode, dis timer;	// 0x0caaa8
	ena bit_rev, dis av_latch;			// 0x0c02c0

	// modify address register
	modify(i1,m1);				// 0x090005

	// NOP
	nop;					// 0x0

	// interrupt enable and disable
	ena ints;				// 0x040060
	dis ints;				// 0x040040

	// computation and memory read
	mr=mx0*mf(rnd), sr1=dm(i0,m3);		// 0x6030f3
	mf=mr+mx1*my1(rnd), sr0=dm(i1,m2);	// 0x6449e6
	mf=mr-ar*my0(rnd), mr2=dm(i2,m1);	// 0x6462d9
	mf=mr0*mf(ss), mr1=dm(i3,m0);		// 0x6493cc
	mf=mr1*my1(su), mr0=dm(i4,m7);		// 0x74acb3
	mf=mr2*my0(us), ar=dm(i5,m6);		// 0x74c5a6
	mr=sr0*mf(uu), se=dm(i6,m5);		// 0x70f699
	mf=mr+sr1*my1(ss), si=dm(i7,m4);	// 0x750f8c
	mr=mr+mx0*my0(su), my1=pm(i4,m7);	// 0x512073
	mf=mr+mx1*mf(us), my0=pm(i5,m6);	// 0x555166
	mr=mr+ar*my1(uu), ay1=pm(i6,m5);	// 0x516a59
	mf=mr-mr0*my0(ss), ay0=pm(i7,m4);	// 0x55834c
	mr=mr-mr1*mf(su), mx1=dm(i0,m3);	// 0x61b433
	mf=mr-mr2*my1(us), mx0=dm(i1,m2);	// 0x65cd26
	mr=mr-sr0*my0(uu), ax1=dm(i2,m1);	// 0x61e619
	mr=0, ax0=dm(i3,m0);			// 0x60980c
	mf=0, ax0=dm(i3,m0);			// 0x64980c
	mr=mr, ax0=dm(i3,m0);			// 0x61180c
	mf=mr (rnd), ax0=dm(i3,m0);		// 0x64580c
	
	ar=pass af, ax0 = dm(i3,m0);		// 0x62100c
	af=ay1+1, sr1=dm(i4,m7);		// 0x7628f3
	ar=ax0+ay0+c, sr0=dm(i5,m6);		// 0x7240e6
	af=ax1+af, mr2=dm(i6,m5);		// 0x7671d9
	ar=not ay1, mr1=dm(i7,m4);		// 0x7288cc
	af=-ay0, mr0=pm(i4,m7);			// 0x56a0b3
	af=ar-af+c-1, ar=pm(i5,m6);		// 0x56d2a6
	af=mr0-ay1, se=pm(i6,m5);		// 0x56eb99
	ar=ay0-1, si=pm(i7,m4);			// 0x53008c
	af=af-mr1, my1=dm(i0,m3);		// 0x673473
	ar=ay1-mr2+c-1, my0=dm(i1,m2);		// 0x634d66
	af=not sr0, ay1=dm(i2,m1);		// 0x676659
	ar=sr1 and ay0, ay0=dm(i3,m0);		// 0x63874c
	af=ax0 or af, mx1=dm(i4,m7);		// 0x77b033
	ar=ax1 xor ay1, mx0=dm(i5,m6);		// 0x73c926
	af=abs ar, ax1=dm(i6,m5);		// 0x77e219

	sr = lshift si (hi), ax0 = dm(i7,m4);		// 0x13000c
	sr = sr or lshift ar (hi), mr2 = pm(i4,m7);	// 0x110ad3
	sr = lshift mr0 (lo), mr1 = pm(i5,m6);		// 0x1113c6
	sr = sr or lshift mr1(lo), mr0 = pm(i6,m5);	// 0x111cb9
	sr = ashift mr2 (hi), ar = pm(i7,m4);		// 0x1125ac
	sr = sr or ashift sr0 (hi), se = dm(i0,m3);	// 0x122e93
	sr = ashift sr1 (lo), si = dm(i1,m2);		// 0x123786
	sr = sr or ashift si (lo), my1 = dm(i2,m1);	// 0x123879
	sr = norm ar (hi), my0 = dm(i3,m0);		// 0x12426c
	sr = sr or norm mr0(hi), ay1 = dm(i4,m7);	// 0x134b53
	sr = norm mr1(lo), ay0 = dm(i5,m6);		// 0x135446
	sr = sr or norm mr2(lo), mx1 = dm(i6,m5);	// 0x135d39
	se = exp sr0(hi), mx0 = dm(i7,m4);		// 0x13662c
	se = exp sr1(hix), ax1 = pm(i4,m7);		// 0x116f13
	se = exp si(lo), ax0 = pm(i5,m6);		// 0x117006
	sb = expadj ar, mr2 = pm(i6,m5);		// 0x117ad9

	// computation with register to register move
	mr=mx0*mf(rnd), sr1=ax0;		// 0x2830f0
	mf=mr+mx1*my1(rnd), sr0=ax1;		// 0x2c49e1
	mf=mr-ar*my0(rnd), mr2=mx0;		// 0x2c62d2
	mf=mr0*mf(ss), mr1=mx1;			// 0x2c93c3
	mf=mr1*my1(su), mr0=ay0;		// 0x2cacb4
	mf=mr2*my0(us), ar=ay1;			// 0x2cc5a5
	mr=sr0*mf(uu), se=my0;			// 0x28f696
	mf=mr+sr1*my1(ss), si=my1;		// 0x2d0f87
	mr=mr+mx0*my0(su), my1=si;		// 0x292078
	mf=mr+mx1*mf(us), my0=se;		// 0x2d5169
	mr=mr+ar*my1(uu), ay1=ar;		// 0x296a5a
	mf=mr-mr0*my0(ss), ay0=mr0;		// 0x2d834b
	mr=mr-mr1*mf(su), mx1=mr1;		// 0x29b43c
	mf=mr-mr2*my1(us), mx0=mr2;		// 0x2dcd2d
	mr=mr-sr0*my0(uu), ax1=sr0;		// 0x29e61e
	
	ar=pass af, ax0 = sr1;			// 0x2a100f
	af=ay1+1, sr1=ax0;			// 0x2e28f0
	ar=ax0+ay0+c, sr0=ax1;			// 0x2a40e1
	af=ax1+af, mr2=mx0;			// 0x2e71d2
	ar=not ay1, mr1=mx1;			// 0x2a88c3
	af=-ay0, mr0=ay0;			// 0x2ea0b4
	af=ar-af+c-1, ar=ay1;			// 0x2ed2a5
	af=mr0-ay1, se=my0;			// 0x2eeb96
	ar=ay0-1, si=my1;			// 0x2b0087
	af=af-mr1, my1=si;			// 0x2f3478
	ar=ay1-mr2+c-1, my0=se;			// 0x2b4d69
	af=not sr0, ay1=ar;			// 0x2f665a
	ar=sr1 and ay0, ay0=mr0;		// 0x2b874b
	af=ax0 or af, mx1=mr1;			// 0x2fb03c
	ar=ax1 xor ay1, mx0=mr2;		// 0x2bc92d
	af=abs ar, ax1=sr0;			// 0x2fe21e

	sr = lshift si (hi), ax0 = sr1;			// 0x10000f
	sr = sr or lshift ar (hi), mr2 = ax0;		// 0x100ad0
	sr = lshift mr0 (lo), mr1 = ax1;		// 0x1013c1
	sr = sr or lshift mr1(lo), mr0 = mx0;		// 0x101cb2
	sr = ashift mr2 (hi), ar = mx1;			// 0x1025a3
	sr = sr or ashift sr0 (hi), se = ay0;		// 0x102e94
	sr = ashift sr1 (lo), si = ay1;			// 0x103785
	sr = sr or ashift si (lo), my1 = my0;		// 0x103876
	sr = norm ar (hi), my0 = my1;			// 0x104267
	sr = sr or norm mr0(hi), ay1 = si;		// 0x104b58
	sr = norm mr1(lo), ay0 = se;			// 0x105449
	sr = sr or norm mr2(lo), mx1 = ar;		// 0x105d3a
	se = exp sr0(hi), mx0 = mr0;			// 0x10662b
	se = exp sr1(hix), ax1 = mr1;			// 0x106f1c
	se = exp si(lo), ax0 = mr2;			// 0x10700d
	sb = expadj ar, mr2 = sr0;			// 0x107ade

	// computation with memory write
	dm(i0,m3)=sr1, mr=mx0*mf(rnd);		// 0x6830f3
	mr=mx0*mf(rnd), dm(i0,m3)=sr1;		// 0x6830f3
	dm(i1,m2)=sr0, mf=mr+mx1*my1(rnd);	// 0x6c49e6
	mf=mr+mx1*my1(rnd), dm(i1,m2)=sr0;	// 0x6c49e6
	dm(i2,m1)=mr2, mf=mr-ar*my0(rnd);	// 0x6c62d9
	mf=mr-ar*my0(rnd), dm(i2,m1)=mr2;	// 0x6c62d9
	dm(i3,m0)=mr1, mf=mr0*mf(ss);		// 0x6c93cc
	mf=mr0*mf(ss), dm(i3,m0)=mr1;		// 0x6c93cc
	dm(i4,m7)=mr0, mf=mr1*my1(su);		// 0x7cacb3
	mf=mr1*my1(su), dm(i4,m7)=mr0;		// 0x7cacb3
	dm(i5,m6)=ar, mf=mr2*my0(us);		// 0x7cc5a6
	mf=mr2*my0(us), dm(i5,m6)=ar;		// 0x7cc5a6
	dm(i6,m5)=se, mr=sr0*mf(uu);		// 0x78f699
	dm(i6,m5)=se, mr=sr0*mf(uu);		// 0x78f699
	mf=mr+sr1*my1(ss), dm(i7,m4)=si;	// 0x7d0f8c
	pm(i4,m7)=my1, mr=mr+mx0*my0(su);	// 0x592073
	mr=mr+mx0*my0(su), pm(i4,m7)=my1;	// 0x592073
	pm(i5,m6)=my0, mf=mr+mx1*mf(us);	// 0x5d5166
	mf=mr+mx1*mf(us), pm(i5,m6)=my0;	// 0x5d5166
	pm(i6,m5)=ay1, mr=mr+ar*my1(uu);	// 0x596a59
	mr=mr+ar*my1(uu), pm(i6,m5)=ay1;	// 0x596a59
	pm(i7,m4)=ay0, mf=mr-mr0*my0(ss);	// 0x5d834c
	mf=mr-mr0*my0(ss), pm(i7,m4)=ay0;	// 0x5d834c
	dm(i0,m3)=mx1, mr=mr-mr1*mf(su);	// 0x69b433
	mr=mr-mr1*mf(su), dm(i0,m3)=mx1;	// 0x69b433
	dm(i1,m2)=mx0, mf=mr-mr2*my1(us);	// 0x6dcd26
	mf=mr-mr2*my1(us), dm(i1,m2)=mx0;	// 0x6dcd26
	dm(i2,m1)=ax1, mr=mr-sr0*my0(uu);	// 0x69e619
	mr=mr-sr0*my0(uu), dm(i2,m1)=ax1;	// 0x69e619
	
	dm(i3,m0)=ax0, ar=pass af;		// 0x6a100c
	ar=pass af, dm(i3,m0)=ax0;		// 0x6a100c
	dm(i4,m7)=sr1, af=ay1+1;		// 0x7e28f3
	af=ay1+1, dm(i4,m7)=sr1;		// 0x7e28f3
	dm(i5,m6)=sr0, ar=ax0+ay0+c;		// 0x7a40e6
	ar=ax0+ay0+c, dm(i5,m6)=sr0;		// 0x7a40e6
	dm(i6,m5)=mr2, af=ax1+af;		// 0x7e71d9
	af=ax1+af, dm(i6,m5)=mr2; 		// 0x7e71d9
	dm(i7,m4)=mr1, ar=not ay1;		// 0x7a88cc
	ar=not ay1, dm(i7,m4)=mr1;		// 0x7a88cc
	pm(i4,m7)=mr0, af=-ay0;			// 0x5ea0b3
	af=-ay0, pm(i4,m7)=mr0;			// 0x5ea0b3
	pm(i5,m6)=ar, af=ar-af+c-1;		// 0x5ed2a6
	af=ar-af+c-1, pm(i5,m6)=ar;		// 0x5ed2a6
	pm(i6,m5)=se, af=mr0-ay1;		// 0x5eeb99
	af=mr0-ay1, pm(i6,m5)=se;		// 0x5eeb99
	pm(i7,m4)=si, ar=ay0-1;			// 0x5b008c
	ar=ay0-1, pm(i7,m4)=si;			// 0x5b008c
	dm(i0,m3)=my1, af=af-mr1;		// 0x6f3473
	af=af-mr1, dm(i0,m3)=my1;		// 0x6f3473
	dm(i1,m2)=my0, ar=ay1-mr2+c-1;		// 0x6b4d66
	ar=ay1-mr2+c-1, dm(i1,m2)=my0;		// 0x6b4d66
	dm(i2,m1)=ay1, af=not sr0;		// 0x6f6659
	af=not sr0, dm(i2,m1)=ay1;		// 0x6f6659
	dm(i3,m0)=ay0, ar=sr1 and ay0;		// 0x6b874c
	ar=sr1 and ay0, dm(i3,m0)=ay0;		// 0x6b874c
	dm(i4,m7)=mx1, af=ax0 or af;		// 0x7fb033
	af=ax0 or af, dm(i4,m7)=mx1;		// 0x7fb033
	dm(i5,m6)=mx0, ar=ax1 xor ay1;		// 0x7bc926
	ar=ax1 xor ay1, dm(i5,m6)=mx0;		// 0x7bc926
	dm(i6,m5)=ax1, af=abs ar;		// 0x7fe219
	af=abs ar, dm(i6,m5)=ax1;		// 0x7fe219

	dm(i7,m4)=ax0, sr = lshift si (hi);		// 0x13800c
	sr = lshift si (hi), dm(i7,m4)=ax0;		// 0x13800c
	pm(i4,m7)=sr1, sr = sr or lshift ar (hi);	// 0x118af3
	sr = sr or lshift ar (hi), pm(i4,m7)=sr1;	// 0x118af3
	pm(i5,m6)=sr0, sr = lshift mr0 (lo);		// 0x1193e6
	sr = lshift mr0 (lo), pm(i5,m6)=sr0;		// 0x1193e6
	pm(i6,m5)=mr2, sr = sr or lshift mr1(lo);	// 0x119cd9
	sr = sr or lshift mr1(lo), pm(i6,m5)=mr2;	// 0x119cd9
	pm(i7,m4)=mr1, sr = ashift mr2 (hi);		// 0x11a5cc
	sr = ashift mr2 (hi), pm(i7,m4)=mr1;		// 0x11a5cc
	dm(i0,m3)=mr0, sr = sr or ashift sr0 (hi);	// 0x12aeb3
	sr = sr or ashift sr0 (hi), dm(i0,m3)=mr0;	// 0x12aeb3
	dm(i1,m2)=ar, sr = ashift sr1 (lo);		// 0x12b7a6
	sr = ashift sr1 (lo), dm(i1,m2)=ar;		// 0x12b7a6
	dm(i2,m1)=se, sr = sr or ashift si (lo);	// 0x12b899
	sr = sr or ashift si (lo), dm(i2,m1)=se;	// 0x12b899
	dm(i3,m0)=si, sr = norm ar (hi);		// 0x12c28c
	sr = norm ar (hi), dm(i3,m0)=si;		// 0x12c28c
	dm(i4,m7)=my1, sr = sr or norm mr0(hi);		// 0x13cb73
	sr = sr or norm mr0(hi), dm(i4,m7)=my1;		// 0x13cb73
	dm(i5,m6)=my0, sr = norm mr1(lo);		// 0x13d466
	sr = norm mr1(lo), dm(i5,m6)=my0;		// 0x13d466
	dm(i6,m5)=ay1, sr = sr or norm mr2(lo);		// 0x13dd59
	sr = sr or norm mr2(lo), dm(i6,m5)=ay1;		// 0x13dd59
	dm(i7,m4)=ay0, se = exp sr0(hi);		// 0x13e64c
	se = exp sr0(hi), dm(i7,m4)=ay0;		// 0x13e64c
	pm(i4,m7)=mx1, se = exp sr1(hix);		// 0x11ef33
	se = exp sr1(hix), pm(i4,m7)=mx1;		// 0x11ef33
	pm(i5,m6)=mx0, se = exp si(lo);			// 0x11f026
	se = exp si(lo), pm(i5,m6)=mx0;			// 0x11f026
	pm(i6,m5)=ax1, sb = expadj ar;			// 0x11fa19
	sb = expadj ar, pm(i6,m5)=ax1;			// 0x11fa19
	
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
	mr=mx0*mf(rnd), ax0=dm(i1,m2),my1=pm(i5,m5);		// 0xf03056
	mr=mx0*mf(rnd), my1=pm(i5,m5),ax0=dm(i1,m2);		// 0xf03056
	ax0=dm(i1,m2),mr=mx0*mf(rnd), my1=pm(i5,m5);		// 0xf03056
	my1=pm(i5,m5),mr=mx0*mf(rnd), ax0=dm(i1,m2);		// 0xf03056
	ax0=dm(i1,m2),my1=pm(i5,m5),mr=mx0*mf(rnd);		// 0xf03056
	my1=pm(i5,m5), ax0=dm(i1,m2),mr=mx0*mf(rnd);		// 0xf03056
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
	mr=mr0*mf(ss), mx1=dm(i0,m3),ay0=pm(i6,m4);		// 0xcc9383
	mr=mr0*mf(ss),ay0=pm(i6,m4), mx1=dm(i0,m3);		// 0xcc9383
	mx1=dm(i0,m3),mr=mr0*mf(ss), ay0=pm(i6,m4);		// 0xcc9383
	ay0=pm(i6,m4),mr=mr0*mf(ss), mx1=dm(i0,m3);		// 0xcc9383
	mx1=dm(i0,m3),ay0=pm(i6,m4),mr=mr0*mf(ss);		// 0xcc9383
	ay0=pm(i6,m4),mx1=dm(i0,m3),mr=mr0*mf(ss);		// 0xcc9383
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
	mr=sr0*mf(uu), mx1=dm(i3,m0),my0=pm(i7,m7);		// 0xecf6fc
	mr=sr0*mf(uu), my0=pm(i7,m7),mx1=dm(i3,m0);		// 0xecf6fc
	mx1=dm(i3,m0),mr=sr0*mf(uu), my0=pm(i7,m7);		// 0xecf6fc
	my0=pm(i7,m7),mr=sr0*mf(uu), mx1=dm(i3,m0);		// 0xecf6fc
	mx1=dm(i3,m0),my0=pm(i7,m7), mr=sr0*mf(uu);		// 0xecf6fc
	my0=pm(i7,m7), mx1=dm(i3,m0),mr=sr0*mf(uu);		// 0xecf6fc
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
	mr=mr+mx1*mf(us), ax1=dm(i2,m1),my0=pm(i4,m6);		// 0xe55129
	mr=mr+mx1*mf(us),my0=pm(i4,m6), ax1=dm(i2,m1);		// 0xe55129
	ax1=dm(i2,m1),mr=mr+mx1*mf(us), my0=pm(i4,m6);		// 0xe55129
	my0=pm(i4,m6),mr=mr+mx1*mf(us), ax1=dm(i2,m1);		// 0xe55129
	ax1=dm(i2,m1),my0=pm(i4,m6),mr=mr+mx1*mf(us);		// 0xe55129
	my0=pm(i4,m6),ax1=dm(i2,m1),mr=mr+mx1*mf(us);		// 0xe55129
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
	mr=mr-mr1*mf(su), ax0=dm(i1,m2),ay0=pm(i5,m5);		// 0xc1b456
	mr=mr-mr1*mf(su),ay0=pm(i5,m5), ax0=dm(i1,m2);		// 0xc1b456
	ax0=dm(i1,m2),mr=mr-mr1*mf(su), ay0=pm(i5,m5);		// 0xc1b456
	ay0=pm(i5,m5),mr=mr-mr1*mf(su), ax0=dm(i1,m2);		// 0xc1b456
	ax0=dm(i1,m2),ay0=pm(i5,m5), mr=mr-mr1*mf(su);		// 0xc1b456
	ay0=pm(i5,m5),ax0=dm(i1,m2),mr=mr-mr1*mf(su);		// 0xc1b456
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
	rts;					// 0x0a000f

Pscale_down:
	jump not_symbol;			// 0x18000f
	









