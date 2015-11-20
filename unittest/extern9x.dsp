#define TEST_BIG_VALUES    0
    
    .extern buf1, buf2, buf3, buf4;
    .extern target1, target2, target3, target4, target5;
    
    .section/DM data0;
    .var dmalign[3];
    .var reloc1[] =
    {
        0x5555,
        buf1, buf2, // buf3, buf4,
        0x5555,
        length(buf1), length(buf2), length(buf3), length(buf4),
        0x5555,
        address(buf1), address(buf2), address(buf3), address(buf4),
        0x5555,
        page(buf1), page(buf2), page(buf3), page(buf4),
        0x5555,
        length(buf1) + length(buf2) + length(buf3) + length(buf4),
        0x5555,
        length(buf2) + length(buf4),
        length(buf2) - length(buf4),
        length(buf4) - length(buf2),
        length(buf3) * length(buf2),
        length(buf4) / length(buf2),
        length(buf2) / length(buf4),
        length(buf2) % length(buf4),
        length(buf4) % length(buf2),
        length(buf4) << length(buf1),
        length(buf4) >> length(buf1),
        0X5555,
        length(buf4) > length(buf2),
        length(buf2) > length(buf4),
        length(buf4) < length(buf2),
        length(buf2) < length(buf4),
        length(buf4) >= length(buf2),
        length(buf2) >= length(buf4),
        length(buf4) >= length(buf4),
        length(buf4) <= length(buf2),
        length(buf2) <= length(buf4),
        length(buf2) <= length(buf2),
        length(buf4) == length(buf2),
        length(buf2) == length(buf2),
        length(buf4) != length(buf2),
        length(buf4) != length(buf4),
        0X5555,
        length(buf4) > length(buf2) && length(buf2) > length(buf4),
        length(buf4) > length(buf2) && length(buf4) > length(buf2),
        length(buf2) > length(buf2) || length(buf2) > length(buf2),
        length(buf4) > length(buf2) || length(buf2) > length(buf4),
        0X5555,
        length(buf4) & length(buf2),
        length(buf4) | length(buf2),
        length(buf4) ^ length(buf2),
        0x5555,
        0x4fff / (2 * length(buf2)),
        0x4fff % (2 * length(buf2)),
        0x4fff - (2 * length(buf2)),
        0xfff << (2 * length(buf1)),
        0xfff >> (2 * length(buf1)),
        0xfff > (2 * length(buf1)),
        0x1 > (2 * length(buf1)),
        0xfff < (2 * length(buf1)),
        0x1 < (2 * length(buf1)),
        0x3 >= (2 * length(buf1)),
        0x2 >= (2 * length(buf1)),
        0x1 >= (2 * length(buf1)),
        0x3 <= (2 * length(buf1)),
        0x2 <= (2 * length(buf1)),
        0x1 <= (2 * length(buf1)),
        0x5555,
        length(buf1)*-0x8000, length(buf1)*0xffff,
#if TEST_BIG_VALUES    
        length(buf1)*0xfffe7fff, length(buf1)*0x10000,
#endif
        0x5555
    };
    
    .section/PM program0;
    .var pmalign[3];
    .var reloc2[] =
    {
        0xAAAA,
        length(buf1)*-0x8000, length(buf1)*0xffff,
#if TEST_BIG_VALUES    
        length(buf1)*0xffff7fff, length(buf1)*0x10000,
#endif
        0xAAAA
    };
    .var/init24 reloc3[] =
    {
        0xAAAAAA,
        length(buf1)*-0x800000, length(buf1)*0xffffff,
#if TEST_BIG_VALUES    
        length(buf1)*0xfe7fffff, length(buf1)*0x1000000,
#endif
        0xAAAAAA
    };
    dm(i0+=m0) = (target1 & ~target1) -0x8000;
    dm(i0+=m0) = (target1 & ~target1) -1;
    dm(i0+=m0) = (target1 & ~target1) | 0xffff;
#if TEST_BIG_VALUES    
    dm(i0+=m3) = (target1 & ~target1) - 0x8000-1;
    dm(i0+=m3) = (target1 & ~target1) | (0xffff + 1);
#endif
    pm(i0+=m0) = (target1^target1)-0x800000:24;
    pm(i0+=m0) = (target1^target1)-1:24;
    pm(i0+=m0) = (target1^target1)|0xffffff:24;
#if TEST_BIG_VALUES    
    pm(i5+=m7) = (target1^target1)-0x800000-1:24;
    pm(i4+=m6) = (target1^target1)|(0xffffff+1):24;
#endif

do1:
    do (target2 - target2)+do1;
do2:    
    do (target2 - target2) + 0xfff + do2 until ce;
#if TEST_BIG_VALUES
do3:
    do (target2 - target2)-1+do3;
do4:
    do (target2 - target2) + 0xfff + 1+do4 until ce;
#endif

    dmpg2 = (target3 ^ target3) -0x800;
    ijpg = (target3^target3)+0xfff;
    ax0 = (target3^target3)+-1;
    i0 = (target3^target3)+-1;
    i4 = (target3^target3)+-1;
    astat = (target3^target3)+-1;
    irptl = (target3 ^ target3) -0x8000;
    LPstacka = (target3^target3)+0xffff;
#if TEST_BIG_VALUES
    dmpg2 = (target3 ^ target3) -0x800-1;
    ijpg = (target3^target3)+0xfff+1;
    irptl = (target3 ^ target3) -0x8000-1;
    LPstacka = (target3^target3)+0xffff+1;
#endif    

    if eq lcall (target5 &~target5);
    if ne ljump (target5 &~target5) | 0xffffff;
#if TEST_BIG_VALUES
    ljump (target5 &~target5)-1;
    lcall ((target5 &~target5) | 0xffffff) +1;
#endif

jump1:    
    jump ~(target4 | ~target4)+jump1-0x8000;
jump2:    
    jump ~(target4 | ~target4)+jump2-1;
jump3:
    call ~(target4 | ~target4)+jump3 + 0x7fff;
jump4:
    if eq jump ~(target4 | ~target4)+jump4-0x1000;
jump5:
    if eq jump ~(target4 | ~target4)+jump5-0x1;
jump6:
    if ne jump ~(target4 | ~target4)+jump6+0xfff;
#if TEST_BIG_VALUES
jump7:    
    jump ~(target4 | ~target4)+jump7-0x8000-1;
jump8:
    call ~(target4 | ~target4)+jump8 + 0x7fff+1;
jump9:
    if eq jump ~(target4 | ~target4)+jump9-0x1000-1;
jump10:
    if ne jump ~(target4 | ~target4)+jump10+0xfff+1;
#endif

    // + +ve constant
    ar = ax0 + (target1 ^ target1);
    ar = ax0 + (target1 ^ target1) + 1;
    ar = ax0 + (target1 ^ target1) + 2;
    ar = ax0 + (target1 ^ target1) + 4;
    ar = ax0 + (target1 ^ target1) + 8;
    ar = ax0 + (target1 ^ target1) + 16;
    ar = ax0 + (target1 ^ target1) + 32;
    ar = ax0 + (target1 ^ target1) + 64;
    ar = ax0 + (target1 ^ target1) + 128;
    ar = ax0 + (target1 ^ target1) + 256;
    ar = ax0 + (target1 ^ target1) + 512;
    ar = ax0 + (target1 ^ target1) + 1024;
    ar = ax0 + (target1 ^ target1) + 2048;
    ar = ax0 + (target1 ^ target1) + 4096;
    ar = ax0 + (target1 ^ target1) + 8192;
    ar = ax0 + (target1 ^ target1) + 16384;
    ar = ax0 + (target1 ^ target1) + 32767;
    // + -ve constant
    ar = ax0 + (target1 ^ target1) -2;
    ar = ax0 + (target1 ^ target1) -3;
    ar = ax0 + (target1 ^ target1) -5;
    ar = ax0 + (target1 ^ target1) -9;
    ar = ax0 + (target1 ^ target1) -17;
    ar = ax0 + (target1 ^ target1) -33;
    ar = ax0 + (target1 ^ target1) -65;
    ar = ax0 + (target1 ^ target1) -129;
    ar = ax0 + (target1 ^ target1) -257;
    ar = ax0 + (target1 ^ target1) -513;
    ar = ax0 + (target1 ^ target1) -1025;
    ar = ax0 + (target1 ^ target1) -2049;
    ar = ax0 + (target1 ^ target1) -4097;
    ar = ax0 + (target1 ^ target1) -8193;
    ar = ax0 + (target1 ^ target1) -16385;
    ar = ax0 + (target1 ^ target1) -32768;
    // converts + to - +ve and -ve constant
    ar = ax0 + (target1 ^ target1) -16384;
    ar = ax0 + (target1 ^ target1) + 4097;
    
    // + unsigned constants
    ar = ax0 + (target1 ^ target1) + 0x200;
    ar = ax0 + (target1 ^ target1) + 0xffef;
    
    // - constant
    ar = ax0 - (target1 ^ target1) + 2048;
    ar = ax0 - (target1 ^ target1) - 8193;
    // converts - to + constant
    ar = ax0 - (target1 ^ target1) + 9;
    ar = ax0 - (target1 ^ target1) - 256;
    
    // + constant + C
    ar = ax0 + (target1 ^ target1) + 4096 + C;
    ar = ax0 + (target1 ^ target1) + -65 + C;

    // - constant with borrow
    ar = ax0 - (target1 ^ target1) + 4096 + C - 1;
    ar = ax0 - (target1 ^ target1) - 5 + C - 1;
    
    // -xop + constant
    ar = - ax0 + (target1 ^ target1);
    ar = - ax0 + (target1 ^ target1) - 2;
    
    // -xop + constant + C - 1
    ar = - ax0 + (target1 ^ target1) + 8 +C-1;
    ar = - ax0 + (target1 ^ target1)-3+C-1;
    
    // AND OR XOR
    AR=ax0 and (target1 == target1) + 15;
    AR=ax0 and (target1 == target1) -18;
    aR=ax0 or (target1 != target1) | 32767;
    aR=ax0 or (target1 != target1)-32768;
    Ar=ax0 xor (target1 != target1)+16384;
    Ar=ax0 xor (target1 != target1)-1025;
    
    // bit operations
    ar = tstbit length(target1) of ax0;
    ar = setbit length(target1) + 1 of ax0;
    ar = clrbit length(target1)+2 of ax0;
    ar = tglbit length(target1)+3 of ax0;
    ar = tstbit length(target1)+4 of ax0;
    ar = setbit length(target1)+5 of ax0;
    ar = clrbit length(target1)+6 of ax0;
    ar = tglbit length(target1)+7 of ax0;
    ar = tstbit length(target1)+8 of ax0;
    ar = setbit length(target1)+9 of ax0;
    ar = clrbit length(target1)+10 of ax0;
    ar = tglbit length(target1)+11 of ax0;
    ar = tstbit length(target1)+12 of ax0;
    ar = setbit length(target1)+13 of ax0;
    ar = clrbit length(target1)+14 of ax0;
    ar = tglbit length(target1)+15 of ax0;
#if TEST_BIG_VALUES
    ar = clrbit length(target1)-1 of ax1;
    ar = tglbit length(target1)+16 of ax1;
#endif

    // PASS
    ar = pass length(target3) - 1;
    ar = pass length(target3);
    ar = pass length(target3)+1;
    ar = pass length(target3) | 16;
    ar = pass length(target3) - 17;
    ar = pass length(target3) + 17;
    ar = pass length(target3) - 16;
    ar = pass length(target3) + 15;
    ar = pass length(target3) - 18;
        
    // Shift immediate
    sr = AShift ax0 by length(target2) - 128 (lo);
    sr = AShift ax0 by length(target2) - 1 (hi);
    sr = sr or AShift ax0 by length(target2) +127 (hi);
    sr = lShift ax0 by length(target2) - 128 (hi);
    sr = lShift ax0 by length(target2) - 1 (hi);
    sr = sr or lShift ax0 by length(target2) +127 (lo);
    sr = norm ax0 by length(target2) - 128 (hi);
    sr = norm ax0 by length(target2) - 1 (hi);
    sr = sr or norm ax0 by length(target2) +127 (lo);
#if TEST_BIG_VALUES
    sr = AShift sr0 by length(target2) - 129 (hi);
    sr = sr or AShift sr1 by length(target2) +128(lo);
    sr = lShift sr0 by length(target2) - 129 (hi);
    sr = sr or lShift sr1 by length(target2) +128 (lo);
    sr = norm sr0 by length(target2) - 129 (hi);
    sr = sr or norm sr1 by length(target2) +128 (lo);
#endif

    mx0 = dm(target3 >>21);
    ax0 = dm((target1 == target2) | 0xffff);
    i0 = dm((target1 == target2) | 0xffff);
    dm(target4 & ~target4) = si;
    dm(((target1 >> 31) -1) & 0xffff) = ax0;
    dm(((target1 >> 31) -1) & 0xffff) = i0;
#if TEST_BIG_VALUES
    mx0 = dm((target3 >>21) - 1);
    mr0 = dm(((target1 == target2) | 0xffff) + 1);
    dm((target4 & ~target4) - 1) = si;
    dm((((target1 >> 31) -1) & 0xffff) + 1) = i3;
#endif

    ax0 = dm(i0+=(target1-target1)-128);
    ax0 = dm(i0+=(target1-target1)-1);
    ax0 = dm(i0+(target1-target1)-1);
    ax0=dm(i0+=(target1-target1)+127);
    dm(i0+=(target1-target1)-128) =ax0;
    dm(i0+=(target1-target1)-1) =ax0;
    dm(i0+(target1-target1)-1) =ax0;
    dm(i0+=(target1-target1)+127)=ax0;
    modify(i0+=(target1-target1)-128);
    modify(i0+=(target1-target1)-1);
    modify(i0+=127+(target1-target1));
#if TEST_BIG_VALUES
    ax0 = dm(i3+=-128-1+(target1-target1));
    ax1=dm(i2+=127+1+(target1-target1));
    dm(i1+=(target1-target1)-128-1) =my0;
    dm(i0+=(target1-target1)+127+1)=my1;
    modify(i0+=(target1-target1)-128-1);
    modify(i0+=127+1+(target1-target1));
#endif
    
    io(target4 != target4) = ax0;
    io((target4==target4) * 0x3ff) = ax0; 
    ax0 = io(target4 < target3);
    ax0 = io((target4 > target3) | 0x3ff);
#if TEST_BIG_VALUES
    io((target5 <= length(target1))-1) = sr1;
    io((target4>=length(buf1)) * 0x400) = sr0; 
    si = io((target4 < target3)-1);
    mx0 = io((target4 < target3) | 0x400);
#endif
