#include <stdio.h>

#include "reloc.h"

#define sizearray(x)    (sizeof(x)/sizeof((x)[0]))

#define length(x)       (x##_length)
#define page(x)         (x >> 16)
#define address(x)      (x & 0xffff)

#define YOP_ZERO        (3 << 11)
#define YYCC(x)         ((((x) & 0xc) << (11 - 2)) | (((x) & 0x3) << 6) | (1 << 4))
#define BO_MINUS        (1 << 5)
#define const(x) \
    ((x) == 0x0001 ? YYCC(0) : \
    ((x) == 0x0002 ? YYCC(1) : \
    ((x) == 0x0004 ? YYCC(2) : \
    ((x) == 0x0008 ? YYCC(3) : \
    ((x) == 0x0010 ? YYCC(4) : \
    ((x) == 0x0020 ? YYCC(5) : \
    ((x) == 0x0040 ? YYCC(6) : \
    ((x) == 0x0080 ? YYCC(7) : \
    ((x) == 0x0100 ? YYCC(8) : \
    ((x) == 0x0200 ? YYCC(9) : \
    ((x) == 0x0400 ? YYCC(10) : \
    ((x) == 0x0800 ? YYCC(11) : \
    ((x) == 0x1000 ? YYCC(12) : \
    ((x) == 0x2000 ? YYCC(13) : \
    ((x) == 0x4000 ? YYCC(14) : \
    ((x) == 0x8000 ? YYCC(15) : \
    ((x) == ~0x0001 ? YYCC(0) | BO_MINUS : \
    ((x) == ~0x0002 ? YYCC(1) | BO_MINUS : \
    ((x) == ~0x0004 ? YYCC(2) | BO_MINUS : \
    ((x) == ~0x0008 ? YYCC(3) | BO_MINUS : \
    ((x) == ~0x0010 ? YYCC(4) | BO_MINUS : \
    ((x) == ~0x0020 ? YYCC(5) | BO_MINUS : \
    ((x) == ~0x0040 ? YYCC(6) | BO_MINUS : \
    ((x) == ~0x0080 ? YYCC(7) | BO_MINUS : \
    ((x) == ~0x0100 ? YYCC(8) | BO_MINUS : \
    ((x) == ~0x0200 ? YYCC(9) | BO_MINUS : \
    ((x) == ~0x0400 ? YYCC(10) | BO_MINUS : \
    ((x) == ~0x0800 ? YYCC(11) | BO_MINUS : \
    ((x) == ~0x1000 ? YYCC(12) | BO_MINUS : \
    ((x) == ~0x2000 ? YYCC(13) | BO_MINUS : \
    ((x) == ~0x4000 ? YYCC(14) | BO_MINUS : \
    ((x) == ~0x8000 ? YYCC(15) | BO_MINUS : 0) \
    )))))))))))))))))))))))))))))))
    
#define amf_shift        13
#define amf_plus         (0x13 << amf_shift)
#define amf_plusC        (0x12 << amf_shift)
#define amf_negplus      (0x19 << amf_shift)
#define amf_negplusC     (0x1a << amf_shift)
#define amf_minus        (0x17 << amf_shift)
#define amf_minusC       (0x16 << amf_shift)
#define amf_and          (0x1c << amf_shift)
#define amf_or           (0x1d << amf_shift)
#define amf_xor          (0x1e << amf_shift)
#define amf_pass         (0x10 << amf_shift)
#define amf_inc          (0x11 << amf_shift)
#define amf_dec          (0x18 << amf_shift)

#define buf1            0xc
#define buf2            0x2039
#define buf3            0x41328
#define buf4            0x50b19

unsigned long dm8x[] =
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
        0x5555
};

#undef buf1
#undef buf2
#undef buf3
#undef buf4

#define buf1            0x800c
#define buf2            0x8094
#define buf3            0x93cc
#define buf4            0x9eed

unsigned long dm9x[] =
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
        0x5555
};

unsigned long pm8x[] =
{
    0xAAAA << 8,
    (length(buf1)*-0x8000) << 8, (length(buf1)*0xffff) << 8,
    0xAAAA << 8,
    0xAAAAAA,
    length(buf1)*-0x800000, length(buf1)*0xffffff,
    0xAAAAAA,
    0x030003,     /* if flag_in */
    0x03fffc, 
    0x03000c, 
    0x03fff0,
    0x140005,     /* do until */
    0x17fff0, 
    0x480000,     /* reg = <data> */
    0x4ffff0,
    0x3e0006,
    0x37fff0,
    0x3bfff0,
    0x800000,    /* reg = dm(<addr>) */
    0x83fff0,
    0x900000,
    0x93fff0,
    0x018000,    /* io() = dreg */
    0x01fff0,
    0x010000,
    0x017ff0,
    0xa80000,    /*  dm(i,m) = <data> */
    0xaffff0,
    0x180000,    /* if ne jump */
    0x1bfff0,
    0x20000f | amf_plus | YOP_ZERO,
    0x20000f | amf_plus | const(1),
    0x20000f | amf_plus | const(2),
    0x20000f | amf_plus | const(4),
    0x20000f | amf_plus | const(8),
    0x20000f | amf_plus | const(16),
    0x20000f | amf_plus | const(32),
    0x20000f | amf_plus | const(64),
    0x20000f | amf_plus | const(128),
    0x20000f | amf_plus | const(256),
    0x20000f | amf_plus | const(512),
    0x20000f | amf_plus | const(1024),
    0x20000f | amf_plus | const(2048),
    0x20000f | amf_plus | const(4096),
    0x20000f | amf_plus | const(8192),
    0x20000f | amf_plus | const(16384),
    0x20000f | amf_plus | const(~32768),
    0x20000f | amf_plus | const(~1),
    0x20000f | amf_plus | const(~2),
    0x20000f | amf_plus | const(~4),
    0x20000f | amf_plus | const(~8),
    0x20000f | amf_plus | const(~16),
    0x20000f | amf_plus | const(~32),
    0x20000f | amf_plus | const(~64),
    0x20000f | amf_plus | const(~128),
    0x20000f | amf_plus | const(~256),
    0x20000f | amf_plus | const(~512),
    0x20000f | amf_plus | const(~1024),
    0x20000f | amf_plus | const(~2048),
    0x20000f | amf_plus | const(~4096),
    0x20000f | amf_plus | const(~8192),
    0x20000f | amf_plus | const(~16384),
    0x20000f | amf_plus | const(32768),
    /* + to - */
    0x20000f | amf_minus | const(16384),
    0x20000f | amf_minus | const(~4096),
    /* + unsigned */
    0x20000f | amf_plus | const(512),
    0x20000f | amf_plus | const(~16),
    /* - constant */
    0x20000f | amf_minus | const(2048),
    0x20000f | amf_minus | const(~8192),
    /* minus to + */
    0x20000f | amf_plus | const(~8),
    0x20000f | amf_plus | const(256),
    /* + constant + C */
    0x20000f | amf_plusC | const(4096),
    0x20000f | amf_plusC | const(~64),
    /* - constant + C-1 */
    0x20000f | amf_minusC | const(4096),
    0x20000f | amf_minusC | const(~4),
    /* -xop + constant */
    0x20000f | amf_negplus | YOP_ZERO,
    0x20000f | amf_negplus | const(~1),
    /* -xop + constant +C-1 */
    0x20000f | amf_negplusC | const(8),
    0x20000f | amf_negplusC | const(~2),
    /* and or xor */
    0x20000f | amf_and | const(16),
    0x20000f | amf_and | const(~16),
    0x20000f | amf_or | const(~32768),
    0x20000f | amf_or | const(32768),
    0x20000f | amf_xor | const(16384),
    0x20000f | amf_xor | const(~1024),
    /* tst, set, clr, tgl */
    0x20000f | amf_and | const(1),
    0x20000f | amf_or | const(2),
    0x20000f | amf_and | const(~4),
    0x20000f | amf_xor | const(8),
    0x20000f | amf_and | const(16),
    0x20000f | amf_or | const(32),
    0x20000f | amf_and | const(~64),
    0x20000f | amf_xor | const(128),
    0x20000f | amf_and | const(256),
    0x20000f | amf_or | const(512),
    0x20000f | amf_and | const(~1024),
    0x20000f | amf_xor | const(2048),
    0x20000f | amf_and | const(4096),
    0x20000f | amf_or | const(8192),
    0x20000f | amf_and | const(~16384),
    0x20000f | amf_xor | const(32768),
    /* PASS */
    0x20000f | amf_dec | YOP_ZERO,
    0x20000f | amf_pass | YOP_ZERO,
    0x20000f | amf_inc | YOP_ZERO,
    0x20000f | amf_pass | const(16),
    0x20000f | amf_pass | const(~16),
    0x20000f | amf_inc | const(16),
    0x20000f | amf_inc | const(~16),
    0x20000f | amf_dec | const(16),
    0x20000f | amf_dec | const(~16),
    /* shift immediate */
    0x0f3080,
    0x0f20ff,
    0x0f287f,
    0x0f0080,
    0x0f00ff,
    0x0f187f
};

unsigned long pm9x[] =
{
    0xAAAA << 8,
    (length(buf1)*-0x8000) << 8, (length(buf1)*0xffff) << 8,
    0xAAAA << 8,
    0xAAAAAA,
    length(buf1)*-0x800000, length(buf1)*0xffffff,
    0xAAAAAA,
    /* indirect write immediate */
    0x078000, 0x080000,
    0x078ff0, 0x0ff000,
    0x078ff0, 0x0ff000,
    0x07c000, 0x080000,
    0x07cff0, 0x0ff0ff,
    0x07cff0, 0x0ff0ff,
    /* do */
    0x16000f,
    0x16fffe,
    /* load register immediate */
    0x108009,
    0x10fffb,
    0x4ffff0,
    0x5ffff0,
    0x3ffff0,
    0x10fff0,
    0x58000d,
    0x3fffff,
    /* long jump/call */
    0x051000, 0x000000,
    0x050ff1, 0x0ffff0,
    /* jump / call relative */
    0x1c0002,
    0x1ffff3,
    0x1ffff5,
    0x190000,
    0x19fff0,
    0x18fff1,
    /* xop + constant */
    0x20000f | amf_plus | YOP_ZERO,
    0x20000f | amf_plus | const(1),
    0x20000f | amf_plus | const(2),
    0x20000f | amf_plus | const(4),
    0x20000f | amf_plus | const(8),
    0x20000f | amf_plus | const(16),
    0x20000f | amf_plus | const(32),
    0x20000f | amf_plus | const(64),
    0x20000f | amf_plus | const(128),
    0x20000f | amf_plus | const(256),
    0x20000f | amf_plus | const(512),
    0x20000f | amf_plus | const(1024),
    0x20000f | amf_plus | const(2048),
    0x20000f | amf_plus | const(4096),
    0x20000f | amf_plus | const(8192),
    0x20000f | amf_plus | const(16384),
    0x20000f | amf_plus | const(~32768),
    0x20000f | amf_plus | const(~1),
    0x20000f | amf_plus | const(~2),
    0x20000f | amf_plus | const(~4),
    0x20000f | amf_plus | const(~8),
    0x20000f | amf_plus | const(~16),
    0x20000f | amf_plus | const(~32),
    0x20000f | amf_plus | const(~64),
    0x20000f | amf_plus | const(~128),
    0x20000f | amf_plus | const(~256),
    0x20000f | amf_plus | const(~512),
    0x20000f | amf_plus | const(~1024),
    0x20000f | amf_plus | const(~2048),
    0x20000f | amf_plus | const(~4096),
    0x20000f | amf_plus | const(~8192),
    0x20000f | amf_plus | const(~16384),
    0x20000f | amf_plus | const(32768),
    /* + to - */
    0x20000f | amf_minus | const(16384),
    0x20000f | amf_minus | const(~4096),
    /* + unsigned */
    0x20000f | amf_plus | const(512),
    0x20000f | amf_plus | const(~16),
    /* - constant */
    0x20000f | amf_minus | const(2048),
    0x20000f | amf_minus | const(~8192),
    /* minus to + */
    0x20000f | amf_plus | const(~8),
    0x20000f | amf_plus | const(256),
    /* + constant + C */
    0x20000f | amf_plusC | const(4096),
    0x20000f | amf_plusC | const(~64),
    /* - constant + C-1 */
    0x20000f | amf_minusC | const(4096),
    0x20000f | amf_minusC | const(~4),
    /* -xop + constant */
    0x20000f | amf_negplus | YOP_ZERO,
    0x20000f | amf_negplus | const(~1),
    /* -xop + constant +C-1 */
    0x20000f | amf_negplusC | const(8),
    0x20000f | amf_negplusC | const(~2),
    /* and or xor */
    0x20000f | amf_and | const(16),
    0x20000f | amf_and | const(~16),
    0x20000f | amf_or | const(~32768),
    0x20000f | amf_or | const(32768),
    0x20000f | amf_xor | const(16384),
    0x20000f | amf_xor | const(~1024),
    /* tst, set, clr, tgl */
    0x20000f | amf_and | const(1),
    0x20000f | amf_or | const(2),
    0x20000f | amf_and | const(~4),
    0x20000f | amf_xor | const(8),
    0x20000f | amf_and | const(16),
    0x20000f | amf_or | const(32),
    0x20000f | amf_and | const(~64),
    0x20000f | amf_xor | const(128),
    0x20000f | amf_and | const(256),
    0x20000f | amf_or | const(512),
    0x20000f | amf_and | const(~1024),
    0x20000f | amf_xor | const(2048),
    0x20000f | amf_and | const(4096),
    0x20000f | amf_or | const(8192),
    0x20000f | amf_and | const(~16384),
    0x20000f | amf_xor | const(32768),
    /* PASS */
    0x20000f | amf_dec | YOP_ZERO,
    0x20000f | amf_pass | YOP_ZERO,
    0x20000f | amf_inc | YOP_ZERO,
    0x20000f | amf_pass | const(16),
    0x20000f | amf_pass | const(~16),
    0x20000f | amf_inc | const(16),
    0x20000f | amf_inc | const(~16),
    0x20000f | amf_dec | const(16),
    0x20000f | amf_dec | const(~16),
    /* shift immediate */
    0x0f6080,
    0x0f40ff,
    0x0f507f,
    0x0f0080,
    0x0f00ff,
    0x0f307f,
    0x0f8080,
    0x0f80ff,
    0x0fb07f,
    0x800002,
    0x8ffff0,
    0xaffff0,
    0x90000b,
    0x9ffff0,
    0xbffff0,
    0x090800,
    0x090ff0,
    0x080ff0,
    0x0907f0,
    0x091800,
    0x091ff0,
    0x081ff0,
    0x0917f0,
    0x010800,
    0x010ff0,
    0x0107f0,
    0x069000,
    0x06fff0,
    0x068000,
    0x06eff0
};

int main( int argc, char **argv )
{
    int i;
    unsigned long *current;
    unsigned long *end;

    for( current = pm8x, end = pm8x + sizearray(pm8x) ;
        current < end ; )
    {
        for ( i = 0 ; i < 8 && current < end ; ++i )
        { 
            printf( "%06X%s", *current & 0xffffff,
                    current == end - 1 || i == 7 ? "\n" : " " );
            ++current;
        }
    }
    for( current = dm8x, end = dm8x + sizearray(dm8x) ;
         current < end ; )
    {
        for ( i = 0 ; i < 8 && current < end ; ++i )
        { 
            printf( "%04X%s", *current & 0xffff,
                    current == end - 1 || i == 7 ? "\n" : " " );
            ++current;
        }
    }
    for( current = pm9x, end = pm9x + sizearray(pm9x) ;
        current < end ; )
    {
        for ( i = 0 ; i < 8 && current < end ; ++i )
        { 
            printf( "%06X%s", *current & 0xffffff,
                    current == end - 1 || i == 7 ? "\n" : " " );
            ++current;
        }
    }
    for( current = dm9x, end = dm9x + sizearray(dm9x) ;
         current < end ; )
    {
        for ( i = 0 ; i < 8 && current < end ; ++i )
        { 
            printf( "%04X%s", *current & 0xffff,
                    current == end - 1 || i == 7 ? "\n" : " " );
            ++current;
        }
    }
    return 0;
}
