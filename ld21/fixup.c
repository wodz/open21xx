/*
 * fixup.c 
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
 * Handle relocations for the different machine types supported by the linker
 */

#include <stdio.h>
#include <assert.h>
#include "../defs.h"
#include "../adielf.h"
#include "util.h"
#include "fixup.h"

#define GET_21XX_PROGWORD(name,offset) \
    ((unsigned long)(name)[(offset)] << 16 | \
     (unsigned long)(name)[(offset)+1] << 8 | \
     (unsigned long)(name)[(offset)+2])

#define GET_21XX_DATAWORD(name,offset) \
    ((unsigned long)(name)[(offset)] << 8 | \
     (unsigned long)(name)[(offset)+1])

#define PUT_21XX_PROGWORD(code,name,offset) \
    (name)[(offset)] = (unsigned char)((code) >> 16); \
    (name)[(offset)+1] = (unsigned char)((code) >> 8); \
    (name)[(offset)+2] = (unsigned char)(code);

#define PUT_21XX_DATAWORD(code,name,offset) \
    (name)[(offset)] = (unsigned char)((code) >> 8); \
    (name)[(offset)+1] = (unsigned char)(code);

/*
 * x is number to sign extend, n is number of bits in the number
 */
#define SIGN_EXTEND(x,n) \
    ((((x) & (1 << ((n)-1))) != 0) ? (x) | (-1 << (n)) : (x))
    
static int check_signed( int number, int bits )
{
    int field;

    field = -1 << (bits - 1);
    return number >= field && number <= ~field;
}

static int check_unsigned( int number, int bits )
{
    return number >= 0 && number < (1 << bits);
}

static int check_both( int number, int bits )
{
    return number >= (-1 << (bits - 1)) && number < (1 << bits);
}

const char *fixup_8x_code(
    int reltype, 
    Elf32_Sword fixup,
    Elf32_Addr offset,
    Elf32_Shdr *shdr,
    void *section_data
)
{
    const char *retval;
    unsigned long code;
    unsigned char *progbits;
    unsigned long yyccbo;
    unsigned long amf;

    retval = NULL;
    progbits = section_data;
    progbits += offset;
    switch ( reltype )
    {
        case R_ADSP218X_IMM14:
            if ( !check_both( fixup, 14 ) )
            {
                retval = "Register load exceeds 14 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= (fixup & 0x3fff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP218X_IMM16:
            if ( !check_both( fixup, 16 ) )
            {
                retval = "Load immediate exceeds 16 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= (fixup & 0xffff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP218X_DATADM:
            if ( !check_both( fixup, 16 ) )
            {
                retval = "Data memory data exceeds 16 bits";
            }
            else
            {
                PUT_21XX_DATAWORD(fixup & 0xffff,progbits,0);
            }
            break;
        case R_ADSP218X_DATAPM:
            if ( !check_both( fixup, 16 ) )
            {
                /* 16 bits because code is shifted up by 8 */
                retval = "Program memory data exceeds 16 bits";
            }
            else
            {
                code = (fixup & 0xffff) << 8;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP218X_DATA24:
            if ( !check_both( fixup, 24 ) )
            {
                retval = "Program memory data exceeds 24 bits";
            }
            else
            {
                PUT_21XX_PROGWORD(fixup & 0xffffff,progbits,0);
            }
            break;
        case R_ADSP218X_FLAGIN:
            if ( !check_unsigned( fixup, 14 ) )
            {
                retval = "Flagin address exceeds 14 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= (fixup & 0xfff) << 4 |
                    (fixup & 0x3000) >> 10;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP218X_PM14:
            if ( !check_unsigned( fixup, 14 ) )
            {
                retval = "Program memory address exceeds 14 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= (fixup & 0x3fff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP218X_DM14:
            if ( !check_unsigned( fixup, 14 ) )
            {
                retval = "Data memory address exceeds 14 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= (fixup & 0x3fff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
            }            
            break;
        case R_ADSP218X_IOADDR:
            if ( !check_unsigned( fixup, 11 ) )
            {
                retval = "IO address exceeds 11 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= (fixup & 0x7ff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP218X_YYCCBO:
            code = GET_21XX_PROGWORD(progbits,0);
            yyccbo = check_yyccbo( fixup );
            amf = code & AMF_MASK;
            switch ( amf )
            {
                case 0x10 << AMF_OFFSET:    /* pass constant */
                    code &= ~AMF_MASK;
                    if ( fixup == -1 )
                    {
                        code |= (0x18 << AMF_OFFSET) | YOP_ZERO;
                    }
                    else if ( fixup == 1 )
                    {
                        code |= 0x11 << AMF_OFFSET | YOP_ZERO;
                    }
                    else
                    {
                        unsigned long yyccbo;
        
                        yyccbo = check_yyccbo(fixup);
                        if (yyccbo != 0)
                        {
                            code |= (0x10 << AMF_OFFSET) | yyccbo;
                        }
                        else
                        {
                            yyccbo = check_yyccbo(fixup + 1);
                            if ( yyccbo != 0 )
                            {
                                code |= (0x18 << AMF_OFFSET) | yyccbo;
                            }
                            else
                            {
                                yyccbo = check_yyccbo(fixup - 1);
                                if ( yyccbo != 0 )
                                {
                                    code |= (0x11 << AMF_OFFSET) | yyccbo;
                                }
                                else
                                {
                                    retval = "Invalid PASS constant";
                                }
                            }
                        }
                    }
                    if ( retval == NULL )
                    {
                        PUT_21XX_PROGWORD(code,progbits,0);
                    }
                break;
                                
                case 0x13 << AMF_OFFSET:    /* xop + constant */
                    if ( yyccbo )
                    {
                        code |= yyccbo;
                    }
                    else
                    {
                        yyccbo = check_yyccbo( -fixup );
                        if ( yyccbo )
                        {
                            /* change to xop - constant */
                            code &= ~AMF_MASK;
                            code |= 0x17 << AMF_OFFSET | yyccbo;
                        }
                        else
                        {
                            retval = "Invalid XOP + constant";
                        }
                    }
                    if ( retval == NULL )
                    {
                        PUT_21XX_PROGWORD(code,progbits,0);
                    }
                break;
                                
                case 0x17 << AMF_OFFSET:    /* xop - constant */
                    if ( yyccbo )
                    {
                        code |= yyccbo;
                    }
                    else
                    {
                        yyccbo = check_yyccbo( -fixup );
                        if ( yyccbo )
                        {
                            /* change to xop + constant */
                            code &= ~AMF_MASK;
                            code |= 0x13 << AMF_OFFSET | yyccbo;
                        }
                        else
                        {
                            retval = "Invalid XOP - constant";
                        }
                    }
                    if ( retval == NULL )
                    {
                        PUT_21XX_PROGWORD(code,progbits,0);
                    }
                break;
                                
                case 0x12 << AMF_OFFSET:    /* xop + constant + C */
                case 0x16 << AMF_OFFSET:    /* xop - constant + C - 1 */
                case 0x19 << AMF_OFFSET:    /* -xop + constant */
                case 0x1a << AMF_OFFSET:    /* -xop + constant + C - 1 */
                case 0x1c << AMF_OFFSET:    /* xop & constant */
                case 0x1d << AMF_OFFSET:    /* xop | constant */
                case 0x1e << AMF_OFFSET:    /* xop ^ constant */
                    if ( yyccbo == 0 )
                    {
                        retval = "Invalid YOP constant";
                    }
                    else
                    {
                        code |= yyccbo;
                        PUT_21XX_PROGWORD(code,progbits,0);
                    }
                break;
                
                default:
                    assert( "Unrecognized ALU MAC Function for YYCCBO" == NULL );
                break;
            }
            break;
        case R_ADSP218X_YYCCBO_BITNO:
            if ( fixup < 0 || fixup > 15 )
            {
                retval = "Bit offset must be from 0 to 15";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= BITNO_TO_YYCC(fixup);
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP218X_SHIFT_IMMEDIATE:
            if ( fixup < -128 || fixup > 127 )
            {
                retval = "Shift immediate value exceeds 8 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= fixup & 0xff;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        default:
            retval = "unknown relocation type";
            break;
    }
    return retval;
}

const char *fixup_9x_code(
    int reltype, 
    Elf32_Sword fixup,
    Elf32_Addr offset,
    Elf32_Shdr *shdr,
    void *section_data
)
{
    const char *retval;
    unsigned long code, code2, pc;
    unsigned char *progbits;
    unsigned long yyccbo;
    unsigned long amf;

    retval = NULL;
    pc = shdr->sh_addr + offset/3;
    progbits = section_data;
    progbits += offset;
    switch ( reltype )
    {
        case R_ADSP219X_IMM12:
            if ( !check_both( fixup, 12 ) )
            {
                retval = "Load immediate exceeds 12 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= (fixup & 0xfff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP219X_IMM16:
            if ( !check_both( fixup, 16 ) )
            {
                retval = "Load immediate exceeds 16 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= (fixup & 0xffff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP219X_DATADM:
            if ( !check_both( fixup, 16 ) )
            {
                retval = "Data memory data exceeds 16 bits";
            }
            else
            {
                PUT_21XX_DATAWORD( fixup & 0xffff, progbits, 0 );
            }
            break;
        case R_ADSP219X_DATAPM:
            if ( !check_both( fixup, 16 ) )
            {
                /* 16 bits because code is shifted up by 8 */
                retval = "Program memory data exceeds 16 bits";
            }
            else
            {
                PUT_21XX_PROGWORD((fixup & 0xffff) << 8,progbits,0);
            }
            break;
        case R_ADSP219X_DATA24:
            if ( !check_both( fixup, 24 ) )
            {
                retval = "Program memory data exceeds 24 bits";
            }
            else
            {
                PUT_21XX_PROGWORD(fixup & 0xffffff,progbits,0);
            }
            break;
        case R_ADSP219X_DMLOAD:
            if ( !check_both( fixup, 16 ) )
            {
                retval = "Indirect data memory load exceeds 16 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code2 = GET_21XX_PROGWORD(progbits,3);
                code = code | ((fixup & 0xff) << 4);
                code2 = code2 | (fixup & 0xff00) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
                PUT_21XX_PROGWORD(code2,progbits,3);
            }
            break;
        case R_ADSP219X_PMLOAD:
            if ( !check_both( fixup, 24 ) )
            {
                retval = "Indirect program memory load exceeds 24 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code2 = GET_21XX_PROGWORD(progbits,3);
                code = code | ((fixup & 0xff00) >> 4);
                code2 = code2 |
                    ((fixup & 0xff0000) >> 4) |
                    (fixup & 0xff);
                PUT_21XX_PROGWORD(code,progbits,0);
                PUT_21XX_PROGWORD(code2,progbits,3);
            }
            break;
        case R_ADSP219X_DO:
            code = GET_21XX_PROGWORD(progbits,0);
            fixup = (int)(fixup - pc);
            if ( !check_unsigned( fixup, 12 ) )
            {
                retval = "DO offset exceeds 12 bits";
            }
            else
            {
                code |= (fixup & 0xfff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP219X_REL:
            code = GET_21XX_PROGWORD(progbits,0);
            if ( (code & 0xfc0000) == 0x180000 )
            {
                /* 13 bit offset */
                fixup = (int)(fixup - pc);
                if ( !check_signed( fixup, 13 ) )
                {
                    retval = "Conditional JUMP offset exceeds 13 bits";
                }
                else
                {
                    code |= (fixup & 0x1fff) << 4;
                    PUT_21XX_PROGWORD(code,progbits,0);
                }
            }
            else
            {
                /* 16 bit offset */
                assert( (code & 0xfc0000) == 0x1c0000 );
                fixup = (int)(fixup - pc);
                if ( !check_signed( fixup, 16 ) )
                {
                    retval = "JUMP/CALL offset exceeds 16 bits";
                }
                else
                {
                    code |= (fixup & 0x3fff) << 4 |
                        (fixup & 0xc000) >> 14;
                    PUT_21XX_PROGWORD(code,progbits,0);
                }
            }
            break;
        case R_ADSP219X_LONG:
            if ( !check_unsigned( fixup, 24 ) )
            {
                retval = "LJUMP/LCALL address exceeds 24 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code2 = GET_21XX_PROGWORD(progbits,3);
                code |= (fixup & 0xff0000) >> 12;
                code2 |= (fixup & 0xffff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
                PUT_21XX_PROGWORD(code2,progbits,3);
            }
            break;
        case R_ADSP219X_DM16:
            if ( !check_unsigned( fixup, 16 ) )
            {
                retval = "Data memory address exceeds 16 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= (fixup & 0xffff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP219X_IOADDR:
            if ( !check_unsigned( fixup, 10 ) )
            {
                retval = "IO address exceeds 10 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= (fixup & 0x300) << 5 |
                        (fixup & 0xff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP219X_YYCCBO:
            code = GET_21XX_PROGWORD(progbits,0);
            yyccbo = check_yyccbo( fixup );
            amf = code & AMF_MASK;
            switch ( amf )
            {
                case 0x10 << AMF_OFFSET:    /* pass constant */
                    code &= ~AMF_MASK;
                    if ( fixup == -1 )
                    {
                        code |= (0x18 << AMF_OFFSET) | YOP_ZERO;
                    }
                    else if ( fixup == 1 )
                    {
                        code |= (0x11 << AMF_OFFSET) | YOP_ZERO;
                    }
                    else
                    {
                        unsigned long yyccbo;
        
                        yyccbo = check_yyccbo(fixup);
                        if (yyccbo != 0)
                        {
                            code |= (0x10 << AMF_OFFSET) | yyccbo;
                        }
                        else
                        {
                            yyccbo = check_yyccbo(fixup + 1);
                            if ( yyccbo != 0 )
                            {
                                code |= (0x18 << AMF_OFFSET) | yyccbo;
                            }
                            else
                            {
                                yyccbo = check_yyccbo(fixup - 1);
                                if ( yyccbo != 0 )
                                {
                                    code |= (0x11 << AMF_OFFSET) | yyccbo;
                                }
                                else
                                {
                                    retval = "Invalid PASS constant";
                                }
                            }
                        }
                    }
                    if ( retval == NULL )
                    {
                        PUT_21XX_PROGWORD(code,progbits,0);
                    }
                break;
                                
                case 0x13 << AMF_OFFSET:    /* xop + constant */
                    if ( yyccbo )
                    {
                        code |= yyccbo;
                    }
                    else
                    {
                        yyccbo = check_yyccbo( -fixup );
                        if ( yyccbo )
                        {
                            /* change to xop - constant */
                            code &= ~AMF_MASK;
                            code |= 0x17 << AMF_OFFSET | yyccbo;
                        }
                        else
                        {
                            retval = "Invalid XOP + constant";
                        }
                    }
                    if ( retval == NULL )
                    {
                        PUT_21XX_PROGWORD(code,progbits,0);
                    }
                break;
                                
                case 0x17 << AMF_OFFSET:    /* xop - constant */
                    if ( yyccbo )
                    {
                        code |= yyccbo;
                    }
                    else
                    {
                        yyccbo = check_yyccbo( -fixup );
                        if ( yyccbo )
                        {
                            /* change to xop + constant */
                            code &= ~AMF_MASK;
                            code |= 0x13 << AMF_OFFSET | yyccbo;
                        }
                        else
                        {
                            retval = "Invalid XOP - constant";
                        }
                    }
                    if ( retval == NULL )
                    {
                        PUT_21XX_PROGWORD(code,progbits,0);
                    }
                break;
                                
                case 0x12 << AMF_OFFSET:    /* xop + constant + C */
                case 0x16 << AMF_OFFSET:    /* xop - constant + C - 1 */
                case 0x19 << AMF_OFFSET:    /* -xop + constant */
                case 0x1a << AMF_OFFSET:    /* -xop + constant + C - 1 */
                case 0x1c << AMF_OFFSET:    /* xop & constant */
                case 0x1d << AMF_OFFSET:    /* xop | constant */
                case 0x1e << AMF_OFFSET:    /* xop ^ constant */
                    if ( yyccbo == 0 )
                    {
                        retval = "Invalid YOP constant";
                    }
                    else
                    {
                        code |= yyccbo;
                        PUT_21XX_PROGWORD(code,progbits,0);
                    }
                break;
                
                default:
                    assert( "Unrecognized ALU MAC Function for YYCCBO" == NULL );
                break;
            }
            break;
        case R_ADSP219X_YYCCBO_BITNO:
            if ( fixup < 0 || fixup > 15 )
            {
                retval = "Expecting a bit number from 0 to 15";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= BITNO_TO_YYCC(fixup);
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP219X_SHIFT_IMMEDIATE:
            if ( fixup < -128 || fixup > 127 )
            {
                retval = "SHIFT immediate value exceeds 8 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= fixup & 0xff;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        case R_ADSP219X_MODIFY_IMMEDIATE:
            if ( fixup < -128 || fixup > 127 )
            {
                retval = "MODIFY immediate value exceeds 8 bits";
            }
            else
            {
                code = GET_21XX_PROGWORD(progbits,0);
                code |= (fixup & 0xff) << 4;
                PUT_21XX_PROGWORD(code,progbits,0);
            }
            break;
        default:
            retval = "unknown relocation type";
            break;
    }
    return retval;
}

int fixup_code_map( Elf32_Half machine,
                    fixup_code_fn *fixup_code )
{
    static fixup_code_fn fixup_map_code[] =
    {
        fixup_8x_code,
        fixup_9x_code
    };

    if ( machine >= EM_ADSP218X &&
         machine <= EM_ADSP219X )
    {
        if ( fixup_code )
            *fixup_code = fixup_map_code[machine - EM_ADSP218X];
        return TRUE;
    }
    return FALSE;
}
