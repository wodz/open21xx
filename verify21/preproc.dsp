/*
 * preproc.dsp 
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
 * This file contains a cross section of preprocessor directives for verifying
 * preprocessor operation.
 */

#define MACRO_NL /*
 */		200*30
#define MACRO_EVAL(x,y,z)	((x)+2*(y)+(z))
#define MACRO_LABEL		    \
	        loop?:              \
	                if eq jump loop?;
#define STRINGIZE(x)	# x
#define STRINGIZE2(x,y)	#x, #y
#define a(n)		a ## n

	.section/PM program0;
	a(x0)=MACRO_NL;				// =0 0x417700
	a(x1)=MACRO_EVAL(((1+3)*3), 35, 89);	// 0x400ab1
	MACRO_LABEL				// 0x180000

	.section/dm data0;
	.var dmstart;				// =0 0x0
	.var stringize[] = STRINGIZE(Hobbs), 0;	// 'H' 'o' 'b' 'b' 's' 0
	.var stringize2[] = STRINGIZE(218x!*$), 0;	// '2' '1' '8' 'x' '!' '*' '$' 0
	.var stringize3[] = STRINGIZE(  	), 0; 	// ' ' 0
	.var stringize4[] = STRINGIZE2(2  !,(,2x));	// '2' ' ' '!' '(' ',' '2' 'x' ')'
	.var stringize5[] = __FILE__, '@', __LINE__;	// 'p' 'r' 'e' 'p' 'r' 'o' 'c' '.' 'd' 's' 'p' '@' 49
#

#if 1
	.var if1 = { 1 };			// 0x1
#endif

#if 0
	.var if0 = { 1 };                       // 0x0
#endif

#if 1
	.var if1else = { 1 };			// 0x1
#else
	.var if1else = { 1 };			// 0x0
#endif

#if 0
	.var if0else = { 1 };			// 0x0
#else
	.var if0else = { 1 };			// 0x1
#endif

#if 0
	.var elif1 = { 1 };			// 0x0
#elif 1
	.var elif1 = { 1 };			// 0x1
#else
	.var elif1 = { 1 };			// 0x0
#endif

#if 0
	.var if1elseif0 = { 1 };		// 0x0
#elif 0
	.var if1elseif0 = { 1 };		// 0x0
#else
	.var if1elseif0 = { 1 };		// 0x1
#endif

#if 1
#if 1
	.var if1if1 = { 1 };			// 0x1
#else
	.var if1if1 = { 1 };			// 0x0
#endif
#endif

#if 1
#if 0
	.var if1if0 = { 1 };			// 0x0
#else
	.var if1if0 = { 1 };			// 0x1
#endif
#endif

#if 1
#if 0
	.var if1elif1 = { 1 };			// 0x0
#elif 1
	.var if1elif1 = { 1 };			// 0x1
#else
	.var if1elif1 = { 1 };			// 0x0
#endif
#endif

#if 1
#if 0
	.var if1if0else = { 1 };		// 0x0
#elif 0
	.var if1if0else = { 1 };		// 0x0
#else
	.var if1if0else = { 1 };		// 0x1
#endif
#endif

#define TEST1_MACRO

#if defined TEST1_MACRO
	.var ifdefined1 = { 1 };		// 0x1
#endif

#if defined ( TEST1_MACRO )
	.var ifdefinedp1 = { 1 };		// 0x1
#endif

#ifdef TEST1_MACRO
	.var ifdef1 = { 1 };			// 0x1
#endif

#if defined TEST2_MACRO
	.var ifdefined2 = { 1 };		// 0x0
#endif

#if defined ( TEST2_MACRO )
	.var ifdefinedp2 = { 1 };		// 0x0
#endif

#ifdef TEST2_MACRO
	.var ifdef1 = { 1 };			// 0x0
#endif

#if !defined TEST1_MACRO
	.var ifndefined1 = { 1 };		// 0x0
#else
	.var ifndefined1 = { 1 };		// 0x1
#endif

#if !defined (TEST1_MACRO)
	.var ifndefinedp1 = { 1 };		// 0x0
#else
	.var ifndefinedp1 = { 1 };		// 0x1
#endif

#ifndef TEST1_MACRO
	.var ifndef1 = { 1 };			// 0x0
#else
	.var ifndef1 = { 1 };			// 0x1
#endif

#undef TEST1_MACRO

#if defined TEST1_MACRO
	.var nifdefined1 = { 1 };		// 0x0
#else
	.var nifdefined1 = { 1 };		// 0x1
#endif

#if ((1+2*20-4)/5)
	.var ifexpr1 = { 1 };			// 0x1
#endif

#if ((1+2*20-4)%5)
	.var ifexpr2 = { 1 };			// 0x1
#endif

#if ((2*20)%8)
	.var ifexpr3 = { 1 };			// 0x0
#else
	.var ifexpr3 = { 1 };			// 0x1
#endif

#if (1+2) == 3
	.var if1plus2 = { 1 };			// 0x1
#else
	.var if1plus2 = { 1 };			// 0x0
#endif

#if (1+2) != 3
	.var if1plus2ne = { 1 };		// 0x0
#else
	.var if1plus2ne = { 1 };		// 0x1
#endif

#if !((1+2) == 3)
	.var ifn1plus2e = { 1 };		// 0x0
#else
	.var ifn1plus2e = { 1 };		// 0x1
#endif

#if (4-12) == -8
	.var if4minus12 = { 1 };		// 0x1
#else
	.var if4minus12 = { 1 };		// 0x0
#endif

#if (98*-23) == -2254
	.var if98timesn23 = { 1 };		// 0x1
#else
	.var if98timesn23 = { 1 };		// 0x0
#endif

#if (98/2) == 49
	.var if98div2 = { 1 };			// 0x1
#else
	.var if98div2 = { 1 };			// 0x0
#endif

#if (98%11) == 10
	.var if98mod11 = { 1 };			// 0x1
#else
	.var if98mod11 = { 1 };			// 0x0
#endif

#if (0x8001 << 2) == 0x20004
	.var if1lshift2 = { 1 };		// 0x1
#else
	.var if1lshift2 = { 1 };		// 0x0
#endif

#if (17 >> 3) == 2
	.var if16rshift3 = { 1 };		// 0x1
#else
	.var if16rshift3 = { 1 };		// 0x0
#endif

#if (0xaa55 & 0x80c0) == 0x8040
	.var ifand = { 1 };			// 0x1
#else
	.var ifand = { 1 };			// 0x0
#endif

#if (0x00aa|0x55ab) == 0x55ab
	.var ifor = { 1 };			// 0x1
#else
	.var ifor = { 1 };			// 0x0
#endif

#if (0xaa55 ^ 0xc3c3) == 0x6996
	.var ifxor = { 1 };			// 0x1
#else
	.var ifxor = { 1 };			// 0x0
#endif

#if (~0xaa55) == 0xffff55aa
	.var ifnot = { 1 };			// 0x1
#else
	.var ifnot = { 1 };			// 0x0
#endif

#if 1234 > 1235
	.var ifgt = { 1 };			// 0x0
#elif 1234 > 1234
	.var ifgt = { 1 };			// 0x0
#elif 1234 > 1233
	.var ifgt = { 1 };			// 0x1
#else
	.var ifgt = { 1 };			// 0x0
#endif

#if 1234 >= 1235
	.var ifge = { 1 };			// 0x0
#elif 1234 >= 1234
	.var ifge = { 1 };			// 0x1
#elif 1234 >= 1233
	.var ifge = { 1 };			// 0x0
#else
	.var ifge = { 1 };			// 0x0
#endif

#if 1234 < 1233
	.var iflt = { 1 };			// 0x0
#elif 1234 < 1234
	.var iflt = { 1 };			// 0x0
#elif 1234 < 1235
	.var iflt = { 1 };			// 0x1
#else
	.var iflt = { 1 };			// 0x0
#endif

#if 1234 <= 1233
	.var ifle = { 1 };			// 0x0
#elif 1234 <= 1234
	.var ifle = { 1 };			// 0x1
#elif 1234 <= 1235
	.var ifle = { 1 };			// 0x0
#else
	.var ifle = { 1 };			// 0x0
#endif

#include "include1.h"

#include "include3.h"

#include <include4.h>

	.var incs[] = { INC1, INC2, INC3, INC4 };	// 0x1111 0x2222 0x3333 0x4444

