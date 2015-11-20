/*
 * as21-grammar.y
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
%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <assert.h>
#include <limits.h>
#include "../defs.h"
#include "../adielf.h"
#include "symbol.h"
#include "as21-lex.h"
#include "listing.h"
#include "outfile.h"
#include "grammar.h"
#include "cpp.h"
#include "expression.h"
#include "util.h"

char version[] = "Open218x Assembler Version " VERSION_NUMBER;

#define INDIRECT_DAG(x)       ((x) >> 8)
#define I_M(x)                ((x) & 0xf)
#define DREG_I_M(x)           ((x) & 0xff)
#define DREG(x)               (((x) >> 4) & 0xf)

enum
{
    SF_OFFSET = 11,
    JUMP_CALL_I_OFFSET = 6,
    FLAG_IN_OFFSET = 1,
    FLAG_OUT_OFFSET = 4,
    FL0_OFFSET = 6,
    FL1_OFFSET = 8,
    FL2_OFFSET = 10,
    COND_TRUE = 0xf << COND_OFFSET,
    MAC_SQUARE = 0x10,
    SF_OR = 1 << SF_OFFSET,
    SF_HI = 0,
    SF_LO = 1 << (SF_OFFSET + 1),
    SF_HIX = 1 << SF_OFFSET,
    Z_MASK = 1 << Z_OFFSET,
    ALU_MAC_MASK = 1 << (AMF_OFFSET + 4),
    SF_NORM_LO_OR = 0xb,
    SF_EXP_HI = 0xc,
    SF_EXP_LO = 0xe
};

enum
{
    REG_SE = 0x9,
    REG_AR = 0xa,
    REG_MR0 = 0xb,
    REG_MR1 = 0xc,
    REG_MR2 = 0xd,
    REG_SR0 = 0xe,
    REG_SR1 = 0xf,
    REG_SSTAT_RO = 0x32,
    REG_SB = 0x36,
    REG_IFC_WO = 0x3c,
    REG_OWRCNTR_WO = 0x3d
};

enum
{
    MUL_RND = 0x01 << AMF_OFFSET,
    MAC_RND = 0x02 << AMF_OFFSET,
    MSUB_RND = 0x03 << AMF_OFFSET,
    MUL_SS = 0x04 << AMF_OFFSET,
    MUL_SU = 0x05 << AMF_OFFSET,
    MUL_US = 0x06 << AMF_OFFSET,
    MUL_UU = 0x07 << AMF_OFFSET,
    MAC_SS = 0x08 << AMF_OFFSET,
    MAC_SU = 0x09 << AMF_OFFSET,
    MAC_US = 0x0a << AMF_OFFSET,
    MAC_UU = 0x0b << AMF_OFFSET,
    MSUB_SS = 0x0c << AMF_OFFSET,
    MSUB_SU = 0x0d << AMF_OFFSET,
    MSUB_US = 0x0e << AMF_OFFSET,
    MSUB_UU = 0x0f << AMF_OFFSET
};

enum
{
    DISABLE_MODE = 2,
    ENABLE_MODE = 3
};

static void alu_mac_clash( unsigned long code );

static unsigned long emit_var_file( const string_t *string, int init_24 );

static int check_address( int number, int upper );

/* prototypes for multifunction operations */
static unsigned long alu_mac_with_dm_read( unsigned long op,
                                           unsigned long dm );
static unsigned long shift_with_dm_read( unsigned long op,
                                         unsigned long dm );
static unsigned long alu_mac_with_pm_read( unsigned long op,
                                           unsigned long pm );
static unsigned long shift_op_with_pm_read( unsigned long op,
                                            unsigned long pm );
static unsigned long alu_mac_with_reg_move( unsigned long op,
                                            unsigned long reg );
static unsigned long shift_with_reg_move( unsigned long op,
                                          unsigned long reg );
static unsigned long dm_write_with_alu_mac( unsigned long dm,
                                     unsigned long op );
static unsigned long dm_write_with_shift( unsigned long dm,
                                          unsigned long op );
static unsigned long pm_write_with_alu_mac( unsigned long pm,
                                            unsigned long op );
static unsigned long pm_write_with_shift( unsigned long pm,
                                          unsigned long op );
static unsigned long dm_and_pm_read( unsigned long dm,
                                     unsigned long pm );
static unsigned long alu_mac_with_dm_and_pm_read( unsigned long op,
                                                  unsigned long dm,
                                                  unsigned long pm );

static void restrict_instruction( unsigned long processors );


int max_error_count = 15;
extern int ppdebug;

static int init_24;
static int circular;
static unsigned long initial_var_offset;
static symbol_scope_t scope;
static alignment_t alignment;
static memory_space_t previous_space, current_space;

/* used for parsing .var directives */
static symbol_hdl var_symbol;
static int var_length;

int processor_flags;
struct processor_list processor_list[] =
{
    { NULL,  EF_ADSP218X },     /* the default */
    { "101", EF_ADSP218X | EF_ADSP217X |EF_ADSP2100 },
    { "103", EF_ADSP218X | EF_ADSP217X |EF_ADSP2100 },
    { "104", EF_ADSP218X | EF_ADSP217X |EF_ADSP2100 },
    { "105", EF_ADSP218X | EF_ADSP217X |EF_ADSP2100 },
    { "115", EF_ADSP218X | EF_ADSP217X |EF_ADSP2100 },
    { "161", EF_ADSP218X | EF_ADSP217X |EF_ADSP2100 },
    { "162", EF_ADSP218X | EF_ADSP217X |EF_ADSP2100 },
    { "163", EF_ADSP218X | EF_ADSP217X |EF_ADSP2100 },
    { "164", EF_ADSP218X | EF_ADSP217X |EF_ADSP2100 },
    { "165", EF_ADSP218X | EF_ADSP217X |EF_ADSP2100 },
    { "166", EF_ADSP218X | EF_ADSP217X |EF_ADSP2100 },
    { "171", EF_ADSP218X | EF_ADSP217X },
    { "173", EF_ADSP218X | EF_ADSP217X },
    { "181", EF_ADSP218X },
    { "183", EF_ADSP218X },
    { "184", EF_ADSP218X },
    { "185", EF_ADSP218X },
    { "186", EF_ADSP218X },
    { "187", EF_ADSP218X },
    { "188", EF_ADSP218X },
    { "189", EF_ADSP218X },
    { "1msp58", EF_ADSP218X | EF_ADSP217X },
    { "1msp59", EF_ADSP218X | EF_ADSP217X },
};

const int processor_list_size = sizearray(processor_list);

%}
/******************************************************************************
 * Synchronize union members and tokens with the preprocessor. Any tokens
 * appearing in both parsers need to appear first and be in the same order.
 *****************************************************************************/ 
%union {
    int integer;
    string_t string;
    unsigned long code;
    int offset;
    memory_space_t memory_space;
    symbol_hdl symbol;
    expression_t expression;
    unsigned long section_type;
}

/* Any tokens shared with any other grammars must be below this comment
 * and above the END SHARED TOKENS comment and must appear in the same
 * order in all grammars (assemblers and preprocessor). A grammar only
 * has to duplicate up to any shared tokens that it uses so tokens
 * used by alot of grammars should appear earlier in the list. */
%token <integer> NUMBER
%token <string>   NAME
%token <string> DQ_STRING
%token LOGICAL_OR LOGICAL_AND COMPARE_EQUAL COMPARE_NOT_EQUAL
%token GREATER_THAN_EQUAL LESS_THAN_EQUAL SHIFT_LEFT SHIFT_RIGHT
%token <integer> SQ_CHAR
%token <string> SQ_STRING
%token DIRECTIVE_DOT PLUS_EQUAL

/* END SHARED TOKENS */

%token ALIGN EXTERN
%token FILE_OBJ
%token LIST NOLIST LIST_DATA NOLIST_DATA LIST_DATFILE NOLIST_DATFILE
%token LIST_DEFTAB LIST_LOCTAB
%token GLOBAL LEFTMARGIN NEWPAGE
%token PAGELENGTH PAGEWIDTH PREVIOUS SECTION VAR NOBITS PROGBITS

%token CODE DATA LENGTH CIRC INIT24 ADDRESS PAGE

%token CARRY AND OR NOT XOR PASS NONE ABS RTS RTI OF TSTBIT SETBIT
%token CLRBIT TGLBIT DIVS DIVQ IF JUMP CALL DO UNTIL
%token SET RESET TOGGLE IDLE MODIFY NOP ENA DIS
%token PUSH POP STS CNTR PC LOOP PM DM IO

%token EQ NE GT GE LT LE AV AC MV CE FOREVER
%token BIT_REV AV_LATCH AR_SAT SEC_REG G_MODE M_MODE TIMER

%token AX0 AX1 AY0 AY1 AR AF
%token MX0 MX1 MY0 MY1 MR MR0 MR1 MR2 MF SS SU US UU RND SAT
%token SB SE SI SR SR0 SR1 ASHIFT LSHIFT HI LO NORM HIX EXP EXPADJ
%token BY

%token I0 I1 I2 I3 I4 I5 I6 I7 M0 M1 M2 M3 M4 M5 M6 M7
%token L0 L1 L2 L3 L4 L5 L6 L7 ASTAT MSTAT SSTAT IMASK ICNTL
%token PX RX0 TX0 RX1 TX1 IFC OWRCNTR PMOVLAY DMOVLAY

%token FLAG_IN INTS FLAG_OUT FL0 FL1 FL2 TOPPCSTACK NEG POS

%type <code> operation condition flag_in term xop conditionable_op
%type <code> alu_mac_op shift_op
%type <code> alu_xop alu_yop alu_operation bilogic bit_op
%type <code> mac_z mac_xop mac_yop mac_operation mul_type
%type <code> mac_type msub_type
%type <code> shift_hi_lo shift_hix_lo shift_xop shift_immediate
%type <code> jump_call set_reset_toggle set_reset_toggle_list
%type <code> stack stack_list ena_dis ena_dis_list ena_dis_mode
%type <code> reg dreg i_reg m_reg
%type <code> indirect_address
%type <symbol> symbol_name
%type <code> dm_read dm_write pm_read pm_write reg_move
%type <integer> var_array
%type <offset> flag_out
%type <offset> mode
%type <memory_space> memory_space
%type <section_type> section_type
%type <code> multifunction

%type <expression> expression logical_or_expression logical_and_expression
%type <expression> or_expression xor_expression and_expression
%type <expression> equality_expression relational_expression
%type <expression> shift_expression additive_expression
%type <expression> multiplicative_expression unary_expression
%type <expression> primary_expression
%type <expression> number
%type <expression> carry_expression borrow_expression
%type <integer> constant_expression

%%

program:
      program statement
        {
            if (error_count > max_error_count)
                YYABORT;
        }
    | statement
    ;

statement:
      NAME ':'
        {
            symbol_define( $1.string, 0 );
        }
    | operation ';'
        {
            emit( $1, TRUE, LIST_ITEM_CODE );
        }
    | DIRECTIVE_DOT directive ';'
        {
        }
    | error error_resync
        {
            yyclearin;
        }
    ;

error_resync:
      ';'   /* an operation */
    | ':'   /* a label */
    ;

directive:
      ALIGN constant_expression
        {
            if (outfile_align( NULL, $2 ) != $2)
            {
                yyerror( "Alignment value must be a power of 2" );
            }
        }
    | EXTERN { scope = SYMBOL_EXTERN; } global_name_list
    | FILE_OBJ { }
    | GLOBAL { scope = SYMBOL_GLOBAL; } global_name_list
    | LEFTMARGIN constant_expression
        {
            listing_left_margin( $2 );
        } 
    | LIST 
        {
            listing_control_set(LISTING_FLAG_LIST);
        }
    | LIST_DATA 
        {
            listing_control_set(LISTING_FLAG_LISTDATA);
        }
    | LIST_DATFILE
        {
            listing_control_set(LISTING_FLAG_LISTDATFILE);
        }
    | LIST_DEFTAB constant_expression
        {
            listing_set_deftab( $2 );
        }
    | LIST_LOCTAB constant_expression
        {
            listing_set_tab( $2 );
        }
    | NEWPAGE
        {
            listing_new_page();
        } 
    | NOLIST 
        {
            listing_control_reset(LISTING_FLAG_LIST);
        }
    | NOLIST_DATA 
        {
            listing_control_reset(LISTING_FLAG_LISTDATA);
        }
    | NOLIST_DATFILE
        {
            listing_control_reset(LISTING_FLAG_LISTDATFILE);
        }
    | PAGELENGTH constant_expression
        {
            listing_page_length( $2 ); 
        } 
    | PAGEWIDTH constant_expression
        {
            listing_page_width( $2 ); 
        } 
    | PREVIOUS
        {
            memory_space_t temp;

            if ( !outfile_previous_section() )
            {
                yyerror("No previous section defined");
            }
            temp = current_space;
            current_space = previous_space;
            previous_space = temp;
        }
    | SECTION '/' memory_space NAME section_type
        {
            outfile_select_section( $4.string, $5, $3 );
            previous_space = current_space;
            current_space = $3;
        }
    | VAR var_qualifiers
        {
            var_symbol = NULL;
            var_length = 0;
            initial_var_offset = outfile_offset();
        }
      variables
        {
            init_24 = FALSE;
            if (circular)
            {
                outfile_align( &alignment, outfile_offset() -
                               initial_var_offset );
            }
            circular = FALSE;
        }
    ;

global_name_list:
      global_name_list ',' global_name
    | global_name
    ;

global_name:
      NAME
        {
            symbol_hdl symbol;
            
            symbol = symbol_reference( $1.string, FALSE, scope );
            if (symbol == NULL)
            {
                yyerror("Internal error creating symbol");
            }
        }
    ;

memory_space:
      DATA
        {
            $$ = SECTION_DATA;
        }
    | DM
        {
            $$ = SECTION_DATA;
        }
    | CODE
        {
            $$ = SECTION_PROGRAM;
        }
    | PM
        {
            $$ = SECTION_PROGRAM;
        }
    ;

section_type:
      NOBITS
        {
            $$ = SHT_NOBITS;
        }
    | PROGBITS
        {
            $$ = SHT_PROGBITS;
        }
    | /* empty */
        {
            $$ = SHT_PROGBITS;
        }
    ;

var_qualifiers:
      var_qualifier_list
    | /* empty */
    ;

var_qualifier_list:
      var_qualifier_list '/' var_one_qualifier
    | '/' var_one_qualifier
    ;

var_one_qualifier:
      INIT24
        {
            if ( current_space == SECTION_PROGRAM )
            {
                init_24 = TRUE;
            }
            else
            {
                yyerror( "24 bit values won't fit in data memory" );
            }
        }
    | CIRC
        {
            circular = TRUE;
            alignment = NULL;
            outfile_align( &alignment, 0 );
       }
    ;

variables:
      var_first_assign
    | var_first_assign ',' var_list
    | var_list
    | var_legacy_assign
    | var_name var_legacy_assign
    ;

/* only valid as the first and only initialization in a .var */
var_legacy_assign:
      '=' { var_length = 0; } var_legacy_init
    ;

var_legacy_init:
      var_expr_list
        {
            if (var_symbol)
            {
                symbol_set_size( var_symbol, var_length );
            }
        }
    | DQ_STRING
        {
            var_length += emit_var_file( &$1, init_24 );
            if ( var_symbol )
            {
                symbol_set_size( var_symbol, var_length );
            }
        }
    ;

var_list:
      var_list ',' var_declare
    | var_list ',' '=' {
          var_length = 0;
          yywarn("Initialization without a variable name");
          var_symbol = NULL;
      } var_init
    | var_declare
    ;

var_declare:
      var_name var_assign
    ;

var_name:
      NAME var_array
        {
            var_symbol = symbol_define( $1.string, $2 );
        }
    ;

var_array:
      '[' ']'
        {
            $$ = 0;
        }
    | '[' constant_expression ']'
        {
            if ($2 <= 0)
            {
                yywarn("Invalid array length... Dynamically sizing");
                /* set up for dynamically sized array */
                $$ = 0;
            }
            else
                $$ = $2;
        }
    | /* empty */
        {
            $$ = 1;
        }
    ;

var_assign:
      var_first_assign
    | /* empty */
      {
          if (var_symbol)
          {
              symbol_set_size( var_symbol, 0 );
          }
      }
    ;

var_first_assign:
      '=' { var_length = 0; } var_init
    ;

var_init:
      '{' var_expr_list '}'
        {
            if (var_symbol)
            {
                symbol_set_size( var_symbol, var_length );
            }
        }
    | '{' DQ_STRING
        {
            var_length += emit_var_file( &$2, init_24 );
        }
      '}'
        {
            if ( var_symbol )
            {
                symbol_set_size( var_symbol, var_length );
            }
        }
    ;

var_expr_list:
      var_expr_list ',' expression
        {
            int rel_type;

            if ( IS_CONSTANT( $3 ) )
            {
                emit( $3.addend, init_24, LIST_ITEM_DATA );
            }
            else            
            {
                if ( current_space == SECTION_DATA )
                {
                    rel_type = R_ADSP218X_DATADM;
                }
                else
                {
                    if ( init_24 )
                    {
                        rel_type = R_ADSP218X_DATA24;
                    }
                    else
                    {
                        rel_type = R_ADSP218X_DATAPM;
                    }
                }
                symbol_add_relocation( $3.symbol, $3.addend,
                                       ($3.type & SYMBOL_MASK) | rel_type );
                emit( 0, init_24, LIST_ITEM_DATA );
            }
            ++var_length;
        }
    | expression
        {
            int rel_type;

            if ( IS_CONSTANT( $1 ) )
            {
                emit( $1.addend, init_24, LIST_ITEM_DATA );
            }
            else
            {
                if ( current_space == SECTION_DATA )
                {
                    rel_type = R_ADSP218X_DATADM;
                }
                else
                {
                    if ( init_24 )
                    {
                        rel_type = R_ADSP218X_DATA24;
                    }
                    else
                    {
                        rel_type = R_ADSP218X_DATAPM;
                    }
                }
                symbol_add_relocation( $1.symbol, $1.addend,
                                       ($1.type & SYMBOL_MASK) | rel_type );
                emit( 0, init_24, LIST_ITEM_DATA );
            }
            ++var_length;
        }
    | var_expr_list ',' SQ_STRING
        {
            var_length += emit_var_string( &$3, init_24 );
        }
    | SQ_STRING
        {
            var_length += emit_var_string( &$1, init_24 );
        }
    ;

operation:
      IF condition conditionable_op
        {
            $$ = $2 | $3;
        }
    | conditionable_op
        {
            $$ = $1 | COND_TRUE;
        }
    | NONE '=' alu_operation
        {
            if ( ($3 & CCBO_MASK) )
            {
                yyerror( "Invalid constant in this context" );
                $3 &= ~YYCCBO_MASK;
            }
            $$ = $3 | 0x2800aa;
        }
    | IF MV SAT MR
        {
            $$ = 0x050000;
        }
    | IF flag_in jump_call expression
        {
            int address;

            $$ = 0x030000 | ($2 << FLAG_IN_OFFSET) | $3;
            if ( IS_CONSTANT( $4 ) )
            {
                address = check_address( $4.addend, 0x3fff );
                $$ |= ((address & 0x3000) >> 10) | ((address & 0xfff) << 4);
            }
            else
            {
                symbol_add_relocation( $4.symbol, $4.addend,
                                       ($4.type & SYMBOL_MASK) | R_ADSP218X_FLAGIN );
            }
        }
    | DO expression UNTIL term
        {
            $$ = 0x140000 | $4;
            if ( IS_CONSTANT( $2 ) )
            {
                $$ |= check_address( $2.addend, 0x3fff ) << 4;
            }
            else
            {
                symbol_add_relocation( $2.symbol, $2.addend,
                                       ($2.type & SYMBOL_MASK) | R_ADSP218X_PM14 );
            }
        } 
    | DIVS alu_yop ',' alu_xop
        {
            $$ = 0x060000 | $2 | $4;
        }
    | DIVQ alu_xop
        {
            $$ = 0x071000 | $2;
        }
    | SR '=' SR OR ASHIFT shift_xop shift_immediate shift_hi_lo
        {
            $$ = 0x0f0000 | (0x4 << SF_OFFSET) | SF_OR | $6 | $7 | $8;
        }
    | SR '=' ASHIFT shift_xop shift_immediate shift_hi_lo
        {
            $$ = 0x0f0000 | (0x4 << SF_OFFSET) | $4 | $5 | $6;
        }
    | SR '=' SR OR LSHIFT shift_xop shift_immediate shift_hi_lo
        {
            $$ = 0x0f0000 | (0x0 << SF_OFFSET) | SF_OR | $6 | $7 | $8;
        }
    | SR '=' LSHIFT shift_xop shift_immediate shift_hi_lo
        {
            $$ = 0x0f0000 | (0x0 << SF_OFFSET) | $4 | $5 | $6;
        }
    | reg_move
        {
            $$ = 0x0d0000 | $1;
        }
    | reg '=' expression
        {
            if ($1 == REG_SSTAT_RO)
                yyerror("Writing a read only register");
            if (REGISTER_GROUP($1) == 0)
            {
                $$ = 0x400000 | $1;
                if ( IS_CONSTANT( $3 ) )
                {
                    if ( $3.addend < -0x8000 || $3.addend > 0xffff )
                        yyerror("Constant is out of range");
                    else
                        $$ |= (($3.addend & 0xffff) << 4);
                }
                else
                {
                    symbol_add_relocation( $3.symbol, $3.addend,
                                           ($3.type & SYMBOL_MASK) | R_ADSP218X_IMM16 );
                }
            }
            else
            {
                $$ = 0x300000 | REGISTER($1) | (REGISTER_GROUP($1) << 18);
                if ( IS_CONSTANT( $3 ) )
                {
                    if ( $3.addend < -0x2000 || $3.addend > 0x3fff )
                        yyerror("Constant is out of range" );
                    else
                        $$ |= ($3.addend & 0x3fff) << 4;
                }
                else
                {
                    symbol_add_relocation( $3.symbol, $3.addend,
                                           ($3.type & SYMBOL_MASK) | R_ADSP218X_IMM14 );
                }
            }
        }
    | reg '=' DM '(' expression ')'
        {
            $$ = 0x800000;
            if ($1 == REG_SSTAT_RO)
                yyerror("Writing a read only register");
            else
                $$ |=  REGISTER($1) | (REGISTER_GROUP($1) << 18);
            if ( IS_CONSTANT( $5 ) )
            {
                $$ |= check_address( $5.addend, 0x3fff ) << 4;
            }
            else
            {
                symbol_add_relocation( $5.symbol, $5.addend, 
                                       ($5.type & SYMBOL_MASK) | R_ADSP218X_DM14 );
            }
        }
    | DM '(' expression ')' '=' reg
        {
            $$ = 0x900000;
            if ($6 == REG_OWRCNTR_WO || $6 == REG_IFC_WO)
                yyerror("Reading a write only register");
            else
                $$ |= REGISTER($6) | (REGISTER_GROUP($6) << 18);
            if ( IS_CONSTANT( $3 ) )
            {
                $$ |= check_address( $3.addend, 0x3fff ) << 4;
            }
            else
            {
                symbol_add_relocation( $3.symbol, $3.addend,
                                       ($3.type & SYMBOL_MASK) | R_ADSP218X_DM14 );
            }
        }
    | IO '(' expression ')' '=' reg
        {
            $$ = 0x018000;
            restrict_instruction( EF_ADSP218X );
            if (REGISTER_GROUP($6) != 0)
                yyerror("Illegal register specified");
            else
            {
                $$ |= $6;
                if ( IS_CONSTANT( $3 ) )
                {
                    $$ |= check_address( $3.addend, 2047 ) << 4;
                }
                else
                {
                    symbol_add_relocation( $3.symbol, $3.addend,
                                        ($3.type & SYMBOL_MASK) | R_ADSP218X_IOADDR );
                }
            }
        }
    | reg '=' IO '(' expression ')'
        {
            $$ = 0x010000;
            restrict_instruction( EF_ADSP218X );
            if (REGISTER_GROUP($1) != 0)
                yyerror("Illegal register specified");
            else
            {
                $$ |= $1;
                if ( IS_CONSTANT( $5 ) )
                {
                    $$ |= check_address( $5.addend, 2047 ) << 4;
                }
                else
                {
                    symbol_add_relocation( $5.symbol, $5.addend,
                                        ($5.type & SYMBOL_MASK) | R_ADSP218X_IOADDR );
                }
            }
        }
    | IDLE
        {
            $$ = 0x028000;
        }
    | IDLE '(' constant_expression ')'
        {
            $$ = 0x028000;
            if ($3 == 16 || $3 == 32 || $3 == 64 || $3 == 128)
                $$ |= $3 >> 4;
            else
                yyerror("Illegal divisor");
        }
    | MODIFY indirect_address
        {
            $$ = 0x090000 | I_M($2) | (INDIRECT_DAG($2) << 4);
        }
    | NOP            { $$ = 0x000000; }
    | ena_dis INTS
        {
            restrict_instruction( EF_ADSP218X | EF_ADSP217X );
            $$ = 0x040000 | ($1 << 5);
        }
    | ena_dis_list
        {
            $$ = 0x0c0000 | $1;
        }
    | stack_list     { $$ = 0x040000 | $1; }
    | TOPPCSTACK '=' reg
        {
            $$ = 0x0d0000;
            if (REGISTER_GROUP($3) != 0x3)
                $$ |= (REGISTER_GROUP($3) << 8) | REGISTER($3) |
                      (REGISTER_GROUP(0x3f) << 10) |
                      (REGISTER(0x3f) << 4);
            else
                yyerror("Illegal register specified");
        }
    | reg '=' TOPPCSTACK
        {
            $$ = 0x0d0000;
            if (REGISTER_GROUP($1) != 0x3)
                $$ |= (REGISTER_GROUP($1) << 10) |
                      (REGISTER($1) << 4) |
                      (REGISTER_GROUP(0x3f) << 8) |
                      REGISTER(0x3f);
            else
                yyerror("Illegal register specified");
        }
    | dm_read
        {
            $$ = 0x600000 | (INDIRECT_DAG($1) << 20) | DREG_I_M($1);
        }
    | dm_write
        {
            $$ = 0x680000 | (INDIRECT_DAG($1) << 20) | DREG_I_M($1);
        }
    | DM indirect_address '=' expression
        {
            $$ = 0xa00000 | (INDIRECT_DAG($2) << 20) | DREG_I_M($2);
            if ( IS_CONSTANT( $4 ) )
            {
                if ( $4.addend < -0x8000 || $4.addend > 0xffff )
                    yyerror("Constant is out of range");
                else
                    $$ |= (($4.addend & 0xffff) << 4);
            }
            else
            {
                symbol_add_relocation( $4.symbol, $4.addend,
                                       ($4.type & SYMBOL_MASK) | R_ADSP218X_IMM16 );
            }
        }
    | pm_read
        {
            $$ = 0x500000 | DREG_I_M($1);
        }
    | pm_write
        {
            $$ = 0x580000 | DREG_I_M($1);
        }
    | multifunction
        {
            $$ = $1;
        }
    ;

multifunction:
      alu_mac_op ',' dm_read
        {
            $$ = alu_mac_with_dm_read( $1, $3 );
        }
    | dm_read ',' alu_mac_op
        {
            $$ = alu_mac_with_dm_read( $3, $1 );
        }
    | shift_op ',' dm_read
        {
            $$ = shift_with_dm_read( $1, $3 );
        }
    | dm_read ',' shift_op
        {
            $$ = shift_with_dm_read( $3, $1 );
        }
    | alu_mac_op ',' pm_read
        {
            $$ = alu_mac_with_pm_read( $1, $3 );
        }
    | pm_read ',' alu_mac_op
        {
            $$ = alu_mac_with_pm_read( $3, $1 );
        }
    | shift_op ',' pm_read
        {
            $$ = shift_op_with_pm_read( $1, $3 );
        }
    | pm_read ',' shift_op
        {
            $$ = shift_op_with_pm_read( $3, $1 );
        }
    | alu_mac_op ',' reg_move
        {
            $$ = alu_mac_with_reg_move( $1, $3 );
        }
    | reg_move ',' alu_mac_op
        {
            $$ = alu_mac_with_reg_move( $3, $1 );
        }
    | shift_op ',' reg_move
        {
            $$ = shift_with_reg_move( $1, $3 );
        }
    | reg_move ',' shift_op
        {
            $$ = shift_with_reg_move( $3, $1 );
        }
    | dm_write ',' alu_mac_op
        {
            $$ = dm_write_with_alu_mac( $1, $3 );
        }
    | alu_mac_op ',' dm_write
        {
            $$ = dm_write_with_alu_mac( $3, $1 );
        }
    | dm_write ',' shift_op
        {
            $$ = dm_write_with_shift( $1, $3 );
        }
    | shift_op ',' dm_write
        {
            $$ = dm_write_with_shift( $3, $1 );
        }
    | pm_write ',' alu_mac_op
        {
            $$ = pm_write_with_alu_mac( $1, $3 );
        }
    | alu_mac_op ',' pm_write
        {
            $$ = pm_write_with_alu_mac( $3, $1 );
        }
    | pm_write ',' shift_op
        {
            $$ = pm_write_with_shift( $1, $3 );
        }
    | shift_op ',' pm_write
        {
            $$ = pm_write_with_shift( $3, $1 );
        }
    | dm_read ',' pm_read
        {
            $$ = dm_and_pm_read( $1, $3 );
        }
    | pm_read ',' dm_read
        {
            $$ = dm_and_pm_read( $3, $1 );
        }
    | alu_mac_op ',' dm_read ',' pm_read
        {
            $$ = alu_mac_with_dm_and_pm_read( $1, $3, $5 );
        }
    | alu_mac_op ',' pm_read ',' dm_read
        {
            $$ = alu_mac_with_dm_and_pm_read( $1, $5, $3 );
        }
    | dm_read ',' alu_mac_op ',' pm_read
        {
            $$ = alu_mac_with_dm_and_pm_read( $3, $1, $5 );
        }
    | pm_read ',' alu_mac_op ',' dm_read
        {
            $$ = alu_mac_with_dm_and_pm_read( $3, $5, $1 );
        }
    | dm_read ',' pm_read ',' alu_mac_op
        {
            $$ = alu_mac_with_dm_and_pm_read( $5, $1, $3 );
        }
    | pm_read ',' dm_read ',' alu_mac_op
        {
            $$ = alu_mac_with_dm_and_pm_read( $5, $3, $1 );
        }
    ;

reg_move: reg '=' reg
        {
            $$ = 0;
            if ($1 == REG_SSTAT_RO)
                yyerror("Attempting to write a read only register");
            else if ($3 == REG_IFC_WO || $3 == REG_OWRCNTR_WO)
                yyerror("Attempting to read a write only register");
            else
                $$ = REGISTER($3) | (REGISTER($1) << 4) |
                     (REGISTER_GROUP($3) << 8) | (REGISTER_GROUP($1) << 10);
        }
    ;

dm_read: reg '=' DM indirect_address
        {
            $$ = $4;
            if (REGISTER_GROUP($1) != 0)
                yyerror("Write to illegal register");
            else
                $$ |= ($1 << 4);
        }
    ;

dm_write:  DM indirect_address '=' dreg
        {
            $$ = ($4 << 4) | $2;
        }
    ;

pm_read: reg '=' PM indirect_address
        {
            $$ = $1 << 4;
            if (INDIRECT_DAG($4) != 1)
                yyerror("Illegal DAG specified");
            else if (REGISTER_GROUP($1) != 0)
                yyerror("Write to illegal register");
            else
                $$ |= I_M($4);
        }
    ;

pm_write:  PM indirect_address '=' dreg
        {
            $$ = $4 << 4;
            if (INDIRECT_DAG($2) != 1)
                yyerror("Illegal DAG specified");
            else
                $$ |= I_M($2);
        }
    ;

conditionable_op: RTS   { $$ = 0x0a0000; }
    | RTI   { $$ = 0x0a0010; }
    | jump_call '(' i_reg ')'
        {
            $$ = 0x0b0000 | ($1 << 4);
            if (I_DAG($3) != 1)
                yyerror("Illegal DAG for operation");
            else
                $$ |= I_REGISTER($3) << JUMP_CALL_I_OFFSET;
        }
    | jump_call expression
        {
            $$ = 0x180000 | ($1 << 18);
            if ( IS_CONSTANT( $2 ) )
            {
                $$ |= check_address( $2.addend, 0x3fff ) << 4;
            }
            else
            {
                symbol_add_relocation( $2.symbol, $2.addend,
                                       ($2.type & SYMBOL_MASK) | R_ADSP218X_PM14 );
            }
        }
    | alu_mac_op
        {
            $$ = $1 | 0x200000;
        }
    | shift_op
        {
            $$ = $1 | 0x0e0000;
        }
    | set_reset_toggle_list
        {
            $$ = $1 | 0x020000;
        }
    ;

jump_call: JUMP  { $$ = 0; }
    |      CALL  { $$ = 1; }
    ;

flag_in:   FLAG_IN     { $$ = 1; }
    |      NOT FLAG_IN { $$ = 0; }
    ;

set_reset_toggle_list:
      set_reset_toggle flag_out ',' set_reset_toggle_list
        {
            if (($4 & (0x3 << $2)) == 0)
                $$ = $4 | ($1 << $2);
            else
            {
                yyerror("Flag already specified");
                $$ = $4;
            }
        }
    | set_reset_toggle flag_out    { $$ = $1 << $2; }
    ;

ena_dis_list:
        ena_dis_list ',' ena_dis_mode
        {
            if (($1 & $3) != 0)
            {
                yyerror("Mode multiply specified");
            }
            $$ = $1 | $3;
        }
    |   ena_dis_mode
        {
            $$ = $1;
        }
    ;

ena_dis_mode:
        ena_dis mode
        {
            $$ = $1 << $2;
        }
    ;
    
ena_dis:
      ENA         { $$ = ENABLE_MODE; }
    | DIS         { $$ = DISABLE_MODE; }
    ;

mode:
      BIT_REV     { $$ = 0x6; }
    | AV_LATCH    { $$ = 0x8; }
    | AR_SAT      { $$ = 0xa; }
    | SEC_REG     { $$ = 0x4; }
    | G_MODE      { $$ = 0x2; }
    | M_MODE      { $$ = 0xc; }
    | TIMER       { $$ = 0xe; }
    ;

set_reset_toggle:
      SET         { $$ = 0x3; }
    | RESET       { $$ = 0x2; }
    | TOGGLE      { $$ = 0x1; }
    ;

flag_out:
      FLAG_OUT    { $$ = FLAG_OUT_OFFSET; }
    | FL0         { $$ = FL0_OFFSET; }
    | FL1         { $$ = FL1_OFFSET; }
    | FL2         { $$ = FL2_OFFSET; }
    ;

stack_list:
      stack       { $$ = $1; }
    | stack ',' stack_list
        {
            if (($1 <= 0x3 && ($3 & 0x3) != 0) ||
                ($1 & $3) != 0)
            {
                yyerror("Register multiply specified");
                $$ = $3;
            }
            else
                $$ = $1 | $3;
        }
    ;

stack:
      PUSH STS    { $$ = 0x2; }
    | POP STS     { $$ = 0x3; }
    | POP CNTR    { $$ = 0x1 << 2; }
    | POP PC      { $$ = 0x1 << 4; }
    | POP LOOP    { $$ = 0x1 << 3; }
    ;
    
alu_mac_op:  reg '=' alu_operation
        {
            $$ = $3;
            if ($1 != REG_AR)
                yyerror("Assigning to an invalid register");
        }
    | AF '=' alu_operation
        {
            $$ = $3 | (1 << Z_OFFSET);
        }
    | mac_z '=' mac_operation
        {
            $$ = $1 | $3;
        }
    ;

shift_op:
      SR '=' SR OR ASHIFT shift_xop shift_hi_lo
        {
            $$ = 0x4 << SF_OFFSET | SF_OR | $6 | $7;
        }
    | SR '=' ASHIFT shift_xop shift_hi_lo
        {
            $$ = 0x4 << SF_OFFSET | $4 | $5;
        }
    | SR '=' SR OR LSHIFT shift_xop shift_hi_lo
        {
            $$ = 0x0 << SF_OFFSET | SF_OR | $6 | $7;
        }
    | SR '=' LSHIFT shift_xop shift_hi_lo
        {
            $$ = 0x0 << SF_OFFSET | $4 | $5;
        }
    | SR '=' SR OR NORM shift_xop shift_hi_lo
        {
            $$ = 0x8 << SF_OFFSET | SF_OR | $6 | $7;
        }
    | SR '=' NORM shift_xop shift_hi_lo
        {
            $$ = 0x8 << SF_OFFSET | $4 | $5;
        }
    | reg '=' EXP shift_xop shift_hix_lo
        {
            if ($1 != REG_SE)
                yyerror("Invalid assign to register");
            $$ = 0xc << SF_OFFSET | $4 | $5;
        }
    | reg '=' EXPADJ shift_xop
        {
            if ($1 != REG_SB)
                yyerror( "Invalid assign to register");
            $$ = 0xf << SF_OFFSET | $4;
        }
    ;

/* alu rules */
alu_operation:
      alu_xop '+' alu_yop
        {
            $$ = 0x13 << AMF_OFFSET | $1 | $3;
        }
    | alu_xop '+' alu_yop '+' CARRY
        {
            $$ = 0x12 << AMF_OFFSET | $1 | $3;
        }
    | alu_xop '+' CARRY
        {
            $$ = 0x12 << AMF_OFFSET | $1 | YOP_ZERO;
        }
    | alu_xop '+' expression
        {
            restrict_instruction( EF_ADSP218X | EF_ADSP217X );
            if ( IS_CONSTANT( $3 ) )
            {
                unsigned long yyccbo = check_yyccbo($3.addend);
                
                if ( yyccbo )
                {
                    $$ = 0x13 << AMF_OFFSET | $1 | yyccbo;
                }
                else
                {
                    yyccbo = check_yyccbo( -$3.addend );
                    if ( yyccbo )
                    {
                        $$ = 0x17 << AMF_OFFSET | $1 | yyccbo;
                    }
                    else
                    {
                        yyerror("Invalid constant specified");
                    }
                }
            }
            else
            {
                $$ = 0x13 << AMF_OFFSET | $1;
                symbol_add_relocation( $3.symbol, $3.addend,
                                       ($3.type & SYMBOL_MASK) | R_ADSP218X_YYCCBO );
            }
        }
    | alu_xop '+' carry_expression
        {
            restrict_instruction( EF_ADSP218X | EF_ADSP217X );
            $$ = 0x12 << AMF_OFFSET | $1;
            if ( IS_CONSTANT( $3 ) )
            {
                unsigned long yyccbo = check_yyccbo($3.addend);
    
                if ( yyccbo )
                {
                    $$ |= yyccbo;
                }
                else
                {
                    yyerror("Invalid constant specified");
                }
            }
            else
            {
                symbol_add_relocation( $3.symbol, $3.addend,
                                        ($3.type & SYMBOL_MASK) | R_ADSP218X_YYCCBO );
            }
        }
    | alu_xop '-' alu_yop
        {
            $$ = 0x17 << AMF_OFFSET | $1 | $3;
        }
    | alu_xop '-' alu_yop '+' borrow
        {
            $$ = 0x16 << AMF_OFFSET | $1 | $3;
        }
    | alu_xop '+' borrow
        {
            $$ = 0x16 << AMF_OFFSET | $1 | YOP_ZERO;
        }
    | alu_xop '-' expression
        {
            restrict_instruction( EF_ADSP218X | EF_ADSP217X );
            if ( IS_CONSTANT( $3 ) )
            {
                unsigned long yyccbo = check_yyccbo($3.addend);
    
                if ( yyccbo )
                {
                    $$ = 0x17 << AMF_OFFSET | $1 | yyccbo;
                }
                else
                {
                    yyccbo = check_yyccbo( -$3.addend );
                    if ( yyccbo )
                    {
                        $$ = 0x13 << AMF_OFFSET | $1 | yyccbo;
                    }
                    else
                    {
                        yyerror("Invalid constant specified");
                    }
                }
            }
            else
            {
                $$ = 0x17 << AMF_OFFSET | $1;
                symbol_add_relocation( $3.symbol, $3.addend,
                                        ($3.type & SYMBOL_MASK) | R_ADSP218X_YYCCBO );
            }
        }
    | alu_xop '-' borrow_expression
        {
            restrict_instruction( EF_ADSP218X | EF_ADSP217X );
            $$ = 0x16 << AMF_OFFSET | $1;
            if ( IS_CONSTANT( $3 ) )
            {
                unsigned long yyccbo = check_yyccbo($3.addend);
    
                if (yyccbo == 0)
                {
                    yyerror("Invalid constant specified");
                }
                else
                {
                    $$ |= yyccbo;
                }
            }
            else
            {
                symbol_add_relocation( $3.symbol, $3.addend,
                                        ($3.type & SYMBOL_MASK) | R_ADSP218X_YYCCBO );
            }
        }
    | alu_yop '-' alu_xop
        {
            $$ = 0x19 << AMF_OFFSET | $1 | $3;
        }
    | alu_yop '-' alu_xop '+' borrow
        {
            $$ = 0x1a << AMF_OFFSET | $1 | $3;
        }
    | '-' alu_xop '+' borrow
        {
            $$ = 0x1a << AMF_OFFSET | $2 | YOP_ZERO;
        }
    | '-' alu_xop '+' expression
        {
            restrict_instruction( EF_ADSP218X | EF_ADSP217X );
            $$ = 0x19 << AMF_OFFSET | $2;
            if ( IS_CONSTANT( $4 ) )
            {
                unsigned long yyccbo = check_yyccbo($4.addend);
    
                if (yyccbo == 0)
                {
                    yyerror("Invalid constant specified");
                }
                else
                {
                    $$ |= yyccbo;
                }
            }
            else
            {
                symbol_add_relocation( $4.symbol, $4.addend,
                                        ($4.type & SYMBOL_MASK) | R_ADSP218X_YYCCBO );
            }
        }
    | '-' alu_xop '+' borrow_expression
        {
            restrict_instruction( EF_ADSP218X | EF_ADSP217X );
            $$ = 0x1a << AMF_OFFSET | $2;
            if ( IS_CONSTANT( $4 ) )
            {
                unsigned long yyccbo = check_yyccbo($4.addend);
    
                if (yyccbo == 0)
                {
                    yyerror("Invalid constant specified");
                }
                else
                {
                    $$ |= yyccbo;
                }
            }
            else
            {
                symbol_add_relocation( $4.symbol, $4.addend,
                                        ($4.type & SYMBOL_MASK) | R_ADSP218X_YYCCBO );
            }
        }
    | alu_xop bilogic alu_yop
        {
            $$ = $1 | $2 | $3;
        }
    | alu_xop bilogic expression
        {
            restrict_instruction( EF_ADSP218X | EF_ADSP217X );
            $$ = $1 | $2;
            if ( IS_CONSTANT( $3 ) )
            {
                unsigned long yyccbo = check_yyccbo($3.addend);
    
                if (yyccbo == 0)
                {
                    yyerror("Invalid constant specified");
                }
                else
                {
                    $$ |= yyccbo;
                }
            }
            else
            {
                symbol_add_relocation( $3.symbol, $3.addend,
                                       ($3.type & SYMBOL_MASK) | R_ADSP218X_YYCCBO );
            }
        }
    | bit_op expression OF alu_xop
        {
            restrict_instruction( EF_ADSP218X | EF_ADSP217X );
            $$ = $1 | $4 ;
            if ( IS_CONSTANT( $2 ) )
            {
                if ( $2.addend < 0 || $2.addend > 15 )
                {
                    yyerror("Expecting a constant from 0 to 15");
                    $$ |= BITNO_TO_YYCC(0);
                }
                else
                {
                    $$ |= BITNO_TO_YYCC($2.addend);
                }
            }
            else
            {
                symbol_add_relocation( $2.symbol, $2.addend,
                                       ($2.type & SYMBOL_MASK) | R_ADSP218X_YYCCBO_BITNO );
            }
        }
    | PASS alu_xop
        {
            $$ = 0x13 << AMF_OFFSET | $2 | YOP_ZERO;
        }
    | PASS alu_yop
        {
            $$ = 0x10 << AMF_OFFSET | $2;
        }
    | PASS expression
        {
            if ( IS_CONSTANT( $2 ) )
            {
                if ( $2.addend == -1 )
                {
                    $$ = 0x18 << AMF_OFFSET | YOP_ZERO;
                }
                else if ( $2.addend == 1 )
                {
                    $$ = 0x11 << AMF_OFFSET | YOP_ZERO;
                }
                else
                {
                    unsigned long yyccbo;
    
                    restrict_instruction( EF_ADSP218X | EF_ADSP217X );
                    if ((yyccbo = check_yyccbo($2.addend)) != 0)
                    {
                        $$ = 0x10 << AMF_OFFSET | yyccbo;
                    }
                    else if ((yyccbo = check_yyccbo($2.addend + 1)) != 0)
                    {
                        $$ = 0x18 << AMF_OFFSET | yyccbo;
                    }
                    else if ((yyccbo = check_yyccbo($2.addend - 1)) != 0)
                    {
                        $$ = 0x11 << AMF_OFFSET | yyccbo;
                    }
                    else
                    {
                        yyerror("Invalid constant specified");
                    }
                }
            }
            else
            {
                /* Clearly tag as a PASS for the linker */
                $$ = 0x10 << AMF_OFFSET;
                symbol_add_relocation( $2.symbol, $2.addend,
                                       ($2.type & SYMBOL_MASK) | R_ADSP218X_YYCCBO );
            }
        }
    | '-' alu_xop
        {
            $$ = 0x19 << AMF_OFFSET | $2 | YOP_ZERO;
        }
    | '-' alu_yop
        {
            $$ = 0x15 << AMF_OFFSET | $2;
        }
    | NOT alu_xop
        {
            $$ = 0x1b << AMF_OFFSET | $2;
        }
    | NOT alu_yop
        {
            $$ = 0x14 << AMF_OFFSET | $2;
        }
    | NOT constant_expression
        {
            if ($2 != 0)
                yyerror("Expecting \"0\"");
            else
                $$ = 0x14 << AMF_OFFSET | YOP_ZERO;
        }
    | ABS alu_xop
        {
            $$ = 0x1f << AMF_OFFSET | $2;
        }
    | alu_yop '+' constant_expression
        {
            if ($3 != 1)
                yyerror("Expecting \"1\"");
            else
                $$ = 0x11 << AMF_OFFSET | $1;
        }
    | alu_yop '-' constant_expression
        {
            if ($3 != 1)
                yyerror("Expecting \"1\"");
            else
                $$ = 0x18 << AMF_OFFSET | $1;
        }
    ;

alu_xop: AX0          	{ $$ = 0x0 << XOP_OFFSET; }
      |  AX1            { $$ = 0x1 << XOP_OFFSET; }
      |  xop
    ;

alu_yop: AY0            { $$ = 0 << YOP_OFFSET; }
    |    AY1            { $$ = 1 << YOP_OFFSET; }
    |    AF             { $$ = 2 << YOP_OFFSET; }
    ;

bilogic: AND            { $$ = 0x1c << AMF_OFFSET; }
    |    OR             { $$ = 0x1d << AMF_OFFSET; }
    |    XOR            { $$ = 0x1e << AMF_OFFSET; }
    ;

bit_op:  TSTBIT { $$ = 0x1c << AMF_OFFSET | BO_BIT; }
    |    SETBIT { $$ = 0x1d << AMF_OFFSET | BO_BIT; }
    |    CLRBIT { $$ = 0x1c << AMF_OFFSET | BO_NOT_BIT; }
    |    TGLBIT { $$ = 0x1e << AMF_OFFSET | BO_BIT; }
    ;

borrow_expression:
      carry_expression '-' number
        {
            if ( !IS_CONSTANT($3) || $3.addend != 1 )
                yyerror("Expecting \"C - 1\"");
            $$ = $1;
        }
    ;

carry_expression:
      additive_expression '+' CARRY
        {
            $$ = $1;
        }
    ;

borrow:
      CARRY '-' number
        {
            if ( !IS_CONSTANT($3) || $3.addend != 1 )
                yyerror("Expecting \"C - 1\"");
        }
    ;

/* mac rules */
mac_operation:
        mac_xop '*' mac_yop mul_type
            {
                $$ = $1 | $3 | $4;
            }
    |   mac_xop '*' mac_xop mul_type
            {
                restrict_instruction( EF_ADSP218X | EF_ADSP217X );
                if ($1 != $3)
                    yyerror("Squaring - xops must be the same register");
                else
                {
                    if ($4 == MUL_SU || $4 == MUL_US)
                        yyerror("Squaring - use SS, UU, or RND");
                    $$ = $1 | $4 | MAC_SQUARE;
                }
            }
    |   MR '+' mac_xop '*' mac_yop mac_type
            {
                $$ = $3 | $5 | $6;
            }
    |   MR '+' mac_xop '*' mac_xop mac_type
            {
                restrict_instruction( EF_ADSP218X | EF_ADSP217X );
                if ($3 != $5)
                    yyerror("Squaring - xops must be the same register");
                else
                {
                    if ($6 == MAC_SU || $6 == MAC_US)
                        yyerror("Squaring - use SS, UU, or RND");
                    $$ = $3 | $6 | MAC_SQUARE;
                }
            }
    |   MR '-' mac_xop '*' mac_yop msub_type
            {
                $$ = $3 | $5 | $6;
            }
    |   MR '-' mac_xop '*' mac_xop msub_type
            {
                restrict_instruction( EF_ADSP218X | EF_ADSP217X );
                if ($3 != $5)
                    yyerror("Squaring - xops must be the same register");
                else
                {
                    if ($6 == MSUB_SU || $6 == MSUB_US)
                        yyerror("Squaring - use SS, UU, or RND");
                    $$ = $3 | $6 | MAC_SQUARE;
                }
            }
    | constant_expression
        {
            if ( $1 != 0)
                yyerror( "Expression must evaluate to zero" );
            $$ = MUL_SS | YOP_ZERO;
        }
    | MR
        {
            $$ = MAC_SS | YOP_ZERO;
        }
    | MR '(' RND ')'
        {
            $$ = MAC_RND | YOP_ZERO;
        }
    ;

mul_type: '(' SU ')' { $$ = MUL_SU; }
    |    '(' US ')'  { $$ = MUL_US; }
    |    '(' SS ')'  { $$ = MUL_SS; }
    |    '(' UU ')'  { $$ = MUL_UU; }
    |    '(' RND ')' { $$ = MUL_RND; }
    ;

mac_type: '(' SU ')' { $$ = MAC_SU; }
    |    '(' US ')'  { $$ = MAC_US; }
    |    '(' SS ')'  { $$ = MAC_SS; }
    |    '(' UU ')'  { $$ = MAC_UU; }
    |    '(' RND ')' { $$ = MAC_RND; }
    ;

msub_type: '(' SU ')' { $$ = MSUB_SU; }
    |    '(' US ')'   { $$ = MSUB_US; }
    |    '(' SS ')'   { $$ = MSUB_SS; }
    |    '(' UU ')'   { $$ = MSUB_UU; }
    |    '(' RND ')'  { $$ = MSUB_RND; }
    ;

mac_z:   MR             { $$ = 0x0 << Z_OFFSET; }
    |    MF             { $$ = 0x1 << Z_OFFSET; }
    ;

mac_xop: MX0          	{ $$ = 0x0 << XOP_OFFSET; }
      |  MX1            { $$ = 0x1 << XOP_OFFSET; }
      |  xop
    ;

mac_yop: MY0            { $$ = 0 << YOP_OFFSET; }
    |    MY1            { $$ = 1 << YOP_OFFSET; }
    |    MF             { $$ = 2 << YOP_OFFSET; }
    ;

/* shifter specific rules */
shift_hix_lo: '(' HIX ')' { $$ = SF_HIX; }
    |    shift_hi_lo
    ;

shift_hi_lo: '(' HI ')' { $$ = SF_HI; }
    |        '(' LO ')' { $$ = SF_LO; }
    ;

shift_xop: SI           { $$ = 0x0 << XOP_OFFSET; }
    |   xop
    ;

shift_immediate: BY expression
        {
            if ( IS_CONSTANT( $2 ) )
            {
                if ($2.addend >= -128 && $2.addend <= 127)
                {
                    $$ = $2.addend & 0xff;
                }
                else
                {
                    $$ = 0;
                    yyerror("Illegal shift value");
                }
            }
            else
            {
                $$ = 0;
                symbol_add_relocation( $2.symbol, $2.addend,
                                       ($2.type & SYMBOL_MASK) | R_ADSP218X_SHIFT_IMMEDIATE );
            }
        }
    ;

/* data move rules */
dreg:      reg
        {
            if (REGISTER_GROUP($1) == 0)
            {
                $$ = REGISTER($1);
            }
            else
            {
                $$ = 0;
                yyerror("Register is not a data register");
            }
        }
    ;

reg:       AX0          { $$ = 0x00; }
    |      AX1          { $$ = 0x01; }
    |      MX0          { $$ = 0x02; }
    |      MX1          { $$ = 0x03; }
    |      AY0          { $$ = 0x04; }
    |      AY1          { $$ = 0x05; }
    |      MY0          { $$ = 0x06; }
    |      MY1          { $$ = 0x07; }
    |      SI           { $$ = 0x08; }
    |      SE           { $$ = REG_SE; }
    |      AR           { $$ = REG_AR; }
    |      MR0          { $$ = 0x0b; }
    |      MR1          { $$ = 0x0c; }
    |      MR2          { $$ = 0x0d; }
    |      SR0          { $$ = 0x0e; }
    |      SR1          { $$ = 0x0f; }
    |      I0           { $$ = 0x10; }
    |      I1           { $$ = 0x11; }
    |      I2           { $$ = 0x12; }
    |      I3           { $$ = 0x13; }
    |      M0           { $$ = 0x14; }
    |      M1           { $$ = 0x15; }
    |      M2           { $$ = 0x16; }
    |      M3           { $$ = 0x17; }
    |      L0           { $$ = 0x18; }
    |      L1           { $$ = 0x19; }
    |      L2           { $$ = 0x1a; }
    |      L3           { $$ = 0x1b; }
    |      PMOVLAY      { $$ = 0x1e; }
    |      DMOVLAY      { $$ = 0x1f; }
    |      I4           { $$ = 0x20; }
    |      I5           { $$ = 0x21; }
    |      I6           { $$ = 0x22; }
    |      I7           { $$ = 0x23; }
    |      M4           { $$ = 0x24; }
    |      M5           { $$ = 0x25; }
    |      M6           { $$ = 0x26; }
    |      M7           { $$ = 0x27; }
    |      L4           { $$ = 0x28; }
    |      L5           { $$ = 0x29; }
    |      L6           { $$ = 0x2a; }
    |      L7           { $$ = 0x2b; }
    |      ASTAT        { $$ = 0x30; }
    |      MSTAT        { $$ = 0x31; }
    |      SSTAT        { $$ = REG_SSTAT_RO; }
    |      IMASK        { $$ = 0x33; }
    |      ICNTL        { $$ = 0x34; }
    |      CNTR         { $$ = 0x35; }
    |      SB           { $$ = REG_SB; }
    |      PX           { $$ = 0x37; }
    |      RX0          { $$ = 0x38; }
    |      TX0          { $$ = 0x39; }
    |      RX1          { $$ = 0x3a; }
    |      TX1          { $$ = 0x3b; }
    |      IFC          { $$ = REG_IFC_WO; }
    |      OWRCNTR      { $$ = REG_OWRCNTR_WO; }
    ;

/* generic rules */
xop:     AR		{ $$ = 0x2 << XOP_OFFSET; }
    |    MR0		{ $$ = 0x3 << XOP_OFFSET; }
    |    MR1		{ $$ = 0x4 << XOP_OFFSET; }
    |    MR2		{ $$ = 0x5 << XOP_OFFSET; }
    |    SR0		{ $$ = 0x6 << XOP_OFFSET; }
    |    SR1		{ $$ = 0x7 << XOP_OFFSET; }
    ;

condition: EQ 		{ $$ = 0x0 << COND_OFFSET; }
    |      NE 		{ $$ = 0x1 << COND_OFFSET; }
    |      GT 		{ $$ = 0x2 << COND_OFFSET; }
    |      LE 		{ $$ = 0x3 << COND_OFFSET; }
    |      LT 		{ $$ = 0x4 << COND_OFFSET; }
    |      GE 		{ $$ = 0x5 << COND_OFFSET; }
    |      AV 		{ $$ = 0x6 << COND_OFFSET; }
    |      NOT AV 	{ $$ = 0x7 << COND_OFFSET; }
    |      AC 		{ $$ = 0x8 << COND_OFFSET; }
    |      NOT AC 	{ $$ = 0x9 << COND_OFFSET; }
    |      NEG 		{ $$ = 0xa << COND_OFFSET; }
    |      POS 		{ $$ = 0xb << COND_OFFSET; }
    |      MV 		{ $$ = 0xc << COND_OFFSET; }
    |      NOT MV 	{ $$ = 0xd << COND_OFFSET; }
    |      NOT CE 	{ $$ = 0xe << COND_OFFSET; }
    ;

term:      NE           { $$ = 0x0 << TERM_OFFSET; }
    |      EQ           { $$ = 0x1 << TERM_OFFSET; }
    |      LE           { $$ = 0x2 << TERM_OFFSET; }
    |      GT           { $$ = 0x3 << TERM_OFFSET; }
    |      GE           { $$ = 0x4 << TERM_OFFSET; }
    |      LT           { $$ = 0x5 << TERM_OFFSET; }
    |      NOT AV       { $$ = 0x6 << TERM_OFFSET; }
    |      AV           { $$ = 0x7 << TERM_OFFSET; }
    |      NOT AC       { $$ = 0x8 << TERM_OFFSET; }
    |      AC           { $$ = 0x9 << TERM_OFFSET; }
    |      POS          { $$ = 0xa << TERM_OFFSET; }
    |      NEG          { $$ = 0xb << TERM_OFFSET; }
    |      NOT MV       { $$ = 0xc << TERM_OFFSET; }
    |      MV           { $$ = 0xd << TERM_OFFSET; }
    |      CE           { $$ = 0xe << TERM_OFFSET; }
    |      FOREVER      { $$ = 0xf << TERM_OFFSET; }
    ;

indirect_address: '(' i_reg ',' m_reg ')'
        {
            /* put DAG at bit 8 so it won't interfer with dreg on */
            /* assignment */
            if (I_DAG($2) == I_DAG($4))
                $$ = (I_DAG($2) << 8) | (I_REGISTER($2) << 2) |
                     M_REGISTER($4);
            else
            {
                yyerror("Mismatched DAGs");
                $$ = 0;
            }
        }
    ;

i_reg:     I0           { $$ = 0x0; }
    |      I1           { $$ = 0x1; }
    |      I2           { $$ = 0x2; }
    |      I3           { $$ = 0x3; }
    |      I4           { $$ = 0x4; }
    |      I5           { $$ = 0x5; }
    |      I6           { $$ = 0x6; }
    |      I7           { $$ = 0x7; }
    ;

m_reg:     M0           { $$ = 0x0; }
    |      M1           { $$ = 0x1; }
    |      M2           { $$ = 0x2; }
    |      M3           { $$ = 0x3; }
    |      M4           { $$ = 0x4; }
    |      M5           { $$ = 0x5; }
    |      M6           { $$ = 0x6; }
    |      M7           { $$ = 0x7; }
    ;

constant_expression:
      expression
        {
            if ( IS_CONSTANT($1) )
            {
                $$ = $1.addend;
            }
            else
            {
                yyerror( "Constant expression required" );
                $$ = 0;
            }
        }
    ;

expression:
      logical_or_expression
        {
            $$ = $1;
        }
    ;

logical_or_expression:
      logical_and_expression
        {
            $$ = $1;
        }
    | logical_or_expression LOGICAL_OR logical_and_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend || $3.addend, EXPRESSION_LOGICAL_OR );
        }
    ;

logical_and_expression:
      or_expression
        {
            $$ = $1;
        }
    | logical_and_expression LOGICAL_AND or_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend && $3.addend, EXPRESSION_LOGICAL_AND );
        }
    ;

or_expression:
      xor_expression
        {
            $$ = $1;
        }
    | or_expression '|' xor_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend | $3.addend, EXPRESSION_BITWISE_OR );
        }
    ;

xor_expression:
      and_expression
        {
            $$ = $1;
        }
    | xor_expression '^' and_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend ^ $3.addend, EXPRESSION_BITWISE_XOR );
        }
    ;

and_expression:
      equality_expression
        {
            $$ = $1;
        }
    | and_expression '&' equality_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend & $3.addend, EXPRESSION_BITWISE_AND );
        }
    ;

equality_expression:
      relational_expression
        {
            $$ = $1;
        }
    | equality_expression COMPARE_EQUAL relational_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend == $3.addend, EXPRESSION_EQUAL );
        }
    | equality_expression COMPARE_NOT_EQUAL relational_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend != $3.addend, EXPRESSION_NOT_EQUAL );
        }
    ;

relational_expression:
      shift_expression
        {
            $$ = $1;
        }
    | relational_expression '>' shift_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend > $3.addend, EXPRESSION_GREATER );
        }
    | relational_expression '<' shift_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend < $3.addend, EXPRESSION_LESS );
        }
    | relational_expression LESS_THAN_EQUAL shift_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend <= $3.addend, EXPRESSION_LESS_EQUAL );
        }
    | relational_expression GREATER_THAN_EQUAL shift_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend >= $3.addend, EXPRESSION_GREATER_EQUAL );
        }
    ;

shift_expression:
      additive_expression
        {
            $$ = $1;
        }
    | shift_expression SHIFT_LEFT additive_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend << $3.addend, EXPRESSION_SHIFT_UP );
        }
    | shift_expression SHIFT_RIGHT additive_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend >> $3.addend, EXPRESSION_SHIFT_DOWN );
        }
    ;

additive_expression:
      multiplicative_expression
        {
            $$ = $1;
        }
    | additive_expression '+' multiplicative_expression
        {
            if ( ($1.type & EXPRESSION_MASK) == EXPRESSION_PUSH &&
                 ($3.type & EXPRESSION_MASK) == EXPRESSION_PUSH &&
                 (($1.symbol == STN_UNDEF && $3.symbol != STN_UNDEF) ||
                  ($1.symbol != STN_UNDEF && $3.symbol == STN_UNDEF)) )
            {
                if ( $1.symbol == STN_UNDEF )
                {
                    $$ = $3;
                    $$.addend += $1.addend;
                }
                else /* $3.symbol == STN_UNDEF */
                {
                    $$ = $1;
                    $$.addend += $3.addend;
                }
            }
            else
            {
                $$ = binary_op( &$1, &$3, $1.addend + $3.addend, EXPRESSION_ADD );
            }
        }
    | additive_expression '-' multiplicative_expression
        {
            if ( ($1.type & EXPRESSION_MASK) == EXPRESSION_PUSH &&
                 ($3.type & EXPRESSION_MASK) == EXPRESSION_PUSH &&
                 $1.symbol != STN_UNDEF && $3.symbol == STN_UNDEF )
            {
                $$ = $1;
                $$.addend -= $3.addend;
            }
            else
            {
                $$ = binary_op( &$1, &$3, $1.addend - $3.addend, EXPRESSION_SUBTRACT );
            }
        }
    ;

multiplicative_expression:
      unary_expression
        {
            $$ = $1;
        }
    | multiplicative_expression '*' unary_expression
        {
            $$ = binary_op( &$1, &$3, $1.addend * $3.addend, EXPRESSION_MULTIPLY );
        }
    | multiplicative_expression '/' unary_expression
        {
            $$ = binary_op( &$1, &$3, int_divide( $1.addend, $3.addend ),
                            EXPRESSION_DIVIDE );
        }
    | multiplicative_expression '%' unary_expression
        {
            $$ = binary_op( &$1, &$3, int_mod( $1.addend, $3.addend ),
                            EXPRESSION_MOD );
        }
    ;

unary_expression:
      primary_expression
        {
            $$ = $1;
        }
    | '-' unary_expression
        {
            $$ = unary_op( &$2, -$2.addend, EXPRESSION_NEGATE );
        }
    | '+' unary_expression
        {
            $$ = $2;
        }
    | '~' unary_expression
        {
            $$ = unary_op( &$2, ~$2.addend, EXPRESSION_BITWISE_NOT );
        }
    | '!' unary_expression
        {
            $$ = unary_op( &$2, !$2.addend, EXPRESSION_LOGICAL_NOT );
        }
    ;
    
primary_expression:
      number
        {
            $$ = $1;
        }
    | '(' expression ')'
        {
            $$ = $2;
        }
    | SQ_CHAR
        {
            $$.symbol = STN_UNDEF;
            $$.addend = $1;
            $$.type = EXPRESSION_PUSH;
        }
    | LENGTH '(' symbol_name ')'
        {
            $$.symbol = $3;
            $$.addend = 0;
            $$.type = SYMBOL_LENGTH_OF;
        }
    | symbol_name
        {
            $$.symbol = $1;
            $$.addend = 0;
            $$.type = SYMBOL_SYMBOL;
        }
    | ADDRESS '(' symbol_name ')'
        {
            $$.symbol = $3;
            $$.addend = 0;
            $$.type = SYMBOL_ADDRESS_OF;
        }
    | PAGE '(' symbol_name ')'
        {
            $$.symbol = $3;
            $$.addend = 0;
            $$.type = SYMBOL_PAGE_OF;
        }
    ;

symbol_name:
      NAME
        {
            $$ = symbol_reference( $1.string, FALSE, SYMBOL_UNKNOWN );
            if ($$ == NULL)
            {
                yyerror("Referencing an undefined symbol");
            }
        }
    ;

number:
      NUMBER
        {
            $$.addend = $1;
            $$.symbol = NULL;
            $$.type = EXPRESSION_PUSH;
        }
    ;

%%

static void restrict_instruction( unsigned long processors )
{
    if ( processor_flags & ~processors )
    {
        yyerror( "The selected processor does not support this instruction" );
    }
}

void grammar_init( const char *object_name )
{
    current_space = previous_space = SECTION_NONE;
    init_24 = FALSE;
    circular = FALSE;
    outfile_init( object_name, EM_ADSP218X, FALSE,
                  3, 2 );
}

void grammar_term( void )
{
    outfile_term( processor_flags );
}

void alu_mac_clash( unsigned long code )
{
    if ((code & Z_MASK) == 0)  /* writing to AR or MR */
    {
        if ((code & ALU_MAC_MASK) == 0)  /* mac function */
        {
            if (DREG(code) >= REG_MR0 && DREG(code) <= REG_MR2)
                yyerror("Multiple clauses writing to the same register");
        }
        else    /* alu function */
        {
            if (DREG(code) == REG_AR)
                yyerror("Multiple clauses writing to the same register");
        }
    }
}

void shifter_clash( unsigned long code )
{
    if (DREG(code) == REG_SE && SHIFT_FUNCTION(code) >= SF_EXP_HI &&
            SHIFT_FUNCTION(code) <= SF_EXP_LO)
        yyerror("Multiple clauses writing to the same register");
    else if (DREG(code) >= REG_SR0 && SHIFT_FUNCTION(code) <= SF_NORM_LO_OR)
        yyerror("Multiple clauses writing to the same register");
}

int check_address( int number, int upper )
{
    if ( number < 0 ||
         number > upper )
    {
        yyerror( "Address is out of range" );
        number = 0;
    }
    return number;
}

unsigned long emit_var_file( const string_t *string, int init_24 )
{
    char *charp = string->string + 1;
    unsigned long length = string->length - 1;
    unsigned long emit_length = 0;
    int token;

    if (charp[length-1] == '\"')
    {
        charp[length-1] = '\0';
    }
    if (cpp_push_file( charp, TRUE))
    {
        /* string may be invalid after calling yylex */
        while ( (token = yylex()) )
        {
            if (token == NUMBER)
            {
                emit( yylval.integer, init_24,
                                LIST_ITEM_DATFILE );
                ++emit_length;
            }
            else if ( token != ',' )
            {
                yyerror( "Syntax error reading data file" );
                break;
            }
        }
    }
    else
    {
        yyerror( "Failed to open input file" );
    }
    return emit_length;
}

/* multifunction operations */
unsigned long alu_mac_with_dm_read( unsigned long op, unsigned long dm )
{
    unsigned long code;

    code = 0x600000 | op | (INDIRECT_DAG(dm) << 20) | DREG_I_M(dm);
    alu_mac_clash( code );
    return code;
}

unsigned long shift_with_dm_read( unsigned long op, unsigned long dm )
{
    unsigned long code;

    code = 0x120000 | op | (INDIRECT_DAG(dm) << 16) | DREG_I_M(dm);
    shifter_clash( code );
    return code;
}

unsigned long alu_mac_with_pm_read( unsigned long op, unsigned long pm )
{
    unsigned long code;

    code = 0x500000 | op | DREG_I_M(pm);
    alu_mac_clash( code );
    return code;
}

unsigned long shift_op_with_pm_read( unsigned long op, unsigned long pm )
{
    unsigned long code;

    code = 0x110000 | op | DREG_I_M(pm);
    shifter_clash( code );
    return code;
}

unsigned long alu_mac_with_reg_move( unsigned long op, unsigned long reg )
{
    unsigned long code;

    code = 0x280000 | op;
    if (REG_MOVE_GROUPS(reg) != 0)
        yyerror("Illegal registers specified for move");
    else 
    {
        code |= reg;
        alu_mac_clash( code );
    }
    return code;
}

unsigned long shift_with_reg_move( unsigned long op, unsigned long reg )
{
    unsigned long code;

    code = 0x100000 | op;
    if (REG_MOVE_GROUPS(reg) != 0)
        yyerror("Illegal registers specified for move");
    else 
    {
        code |= reg;
        shifter_clash( code );
    }
    return code;
}

unsigned long dm_write_with_alu_mac( unsigned long dm, unsigned long op )
{
    return 0x680000 | op | (INDIRECT_DAG(dm) << 20) | DREG_I_M(dm);
}

unsigned long dm_write_with_shift( unsigned long dm, unsigned long op )
{
    return 0x128000 | op | (INDIRECT_DAG(dm) << 16) | DREG_I_M(dm);
}

unsigned long pm_write_with_alu_mac( unsigned long pm, unsigned long op )
{
    return 0x580000 | op | DREG_I_M(pm);
}

unsigned long pm_write_with_shift( unsigned long pm, unsigned long op )
{
    return 0x118000 | op | DREG_I_M(pm);
}

unsigned long dm_and_pm_read( unsigned long dm, unsigned long pm )
{
    unsigned long code;

    code = 0xc00000 | (I_M(pm) << 4);
    if (INDIRECT_DAG(dm) != 0)
        yyerror("Invalid DAG used");
    else if ((DREG(dm) & 0xc) != 0)
        yyerror("Data memory read to invalid register");
    else if ((DREG(pm) & 0xc) != 4)
        yyerror("Program memory read to invalid register");
    else
        code |= (DREG(dm) << 18) | ((DREG(pm) & 0x3) << 20) |
            I_M(dm);
    return code;
}


unsigned long alu_mac_with_dm_and_pm_read(
    unsigned long op,
    unsigned long dm,
    unsigned long pm
)
{
    unsigned long code;

    if ( op & Z_MASK )
    {
        yyerror( "Feedback register is not an allowed destination" );
        op &= ~Z_MASK;
    }
    code = 0xc00000 | op | (I_M(pm) << 4);
    if (INDIRECT_DAG(dm) != 0)
        yyerror("Invalid DAG used");
    else if ((DREG(dm) & 0xc) != 0)
        yyerror("Data memory read to invalid register");
    else if ((DREG(pm) & 0xc) != 4)
        yyerror("Program memory read to invalid register");
    else
        code |= (DREG(dm) << 18) | ((DREG(pm) & 0x3) << 20) |
            I_M(dm);
    return code;
}
