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
    if FLAG_IN call (target1 - target1);
    if not FLAG_IN jump (target1 - target1) + 0x3fff;
    if not FLAG_IN jump (target1 - target1) + 0x3000;
    if not FLAG_IN jump (target1 - target1) + 0xfff;
#if TEST_BIG_VALUES    
    if FLAG_IN jump (target1 - target1) + 0x4000;
    if FLAG_IN call (target1 - target1) - 1;
#endif
    do (target2 - target2) until lt;
    do (target2 - target2) + 0x3fff until ne;
#if TEST_BIG_VALUES    
    do (target2 - target2) + 0x4000 until lt;
    do (target2 - target2) - 1 until lt;
#endif
    // Can be either signed or unsigned
    ax0 = (target3 * 0) - 32768;
    ax0 = (target3 - target2) * 0 + 0xffff;
    sb = (target4 >> 17) - 0x2000;
    i0 = (target2 | ~target2);
    i4 = (target2 | ~target2);
#if TEST_BIG_VALUES    
    ay0 = (target3 >> 19) - 32769;
    ay1 = (target3 >> 25) + 65536;
    imask = (target3 ^ target3) - 16384;
    l0 = ((target4 & 0) | 0x3fff) + 1;
#endif
    ax0 = dm(target3 >>21);
    ax0 = dm((target1 == target2) | 0x3fff);
    dm(target4 & ~target4) = ax0;
    dm(((target1 >> 31) -1) & 0x3fff) = ax0;
#if TEST_BIG_VALUES
    mx0 = dm((target3 >>21) - 1);
    owrcntr = dm(((target1 == target2) | 0x3fff) + 1);
    dm((target4 & ~target4) - 1) = cntr;
    dm((((target1 >> 31) -1) & 0x3fff) + 1) = astat;
#endif
    io(target4 != target4) = ax0;
    io((target4==target4) * 0x7ff) = ax0; 
    ax0 = io(target4 < target3);
    ax0 = io((target4 > target3) | 0x7ff);
#if TEST_BIG_VALUES
    io((target5 <= length(target1))-1) = sr1;
    io((target4>=length(buf1)) * 0x800) = sr0; 
    si = io((target4 < target3)-1);
    se = io((target4 < target3) | 0x800);
#endif
    dm(i0,m0) = (target1 >= target4) -0x8000;
    dm(i0,m0) = length(target1) ^ 0xffff;
#if TEST_BIG_VALUES
    dm(i0,m3) = (target1 >= target4) -0x8001;
    dm(i2,m1) = length(target1) ^ 0x10000;
#endif    
    if eq jump (target2 & ~target2);
    if eq jump (target1 - target1) + 0x3fff;
#if TEST_BIG_VALUES
    jump (target2 & ~target2) - 1;
    call (target1 - target1) + 0x3fff + 1;
#endif
    // + +ve constant
    ar = ax0 + (target1 ^ target1);
    ar = ax0+ (target1 ^ target1) + 1;
    ar = ax0 + (target1 ^ target1) + 2;
    ar = ax0 + (target1 ^ target1) + 4;
    ar = ax0 +(target1 ^ target1) + 8;
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
    ar = ax0+ (target1 ^ target1) + 0xffef;
    
    // - constant
    ar = ax0- (target1 ^ target1) + 2048;
    ar = ax0- (target1 ^ target1) - 8193;

    // converts - to + constant
    ar = ax0 - (target1 ^ target1) + 9;
    ar = ax0- (target1 ^ target1) - 256;
    
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
    ar = -ax0 + (target1 ^ target1)-3+C-1;
    
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
    sr = AShift si by length(target2) - 128 (lo);
    sr = AShift si by length(target2)-1 (hi);
    sr = sr or AShift si by length(target2) +127 (hi);
    sr = lShift si by length(target2) - 128 (hi);
    sr = lShift si by length(target2) - 1 (hi);
    sr = sr or lShift si by length(target2) +127 (lo);
#if TEST_BIG_VALUES
    sr = AShift sr0 by length(target2) - 129 (hi);
    sr = sr or AShift sr1 by length(target2) +128(lo);
    sr = lShift sr0 by length(target2) - 129 (hi);
    sr = sr or lShift sr1 by length(target2) +128 (lo);
#endif    