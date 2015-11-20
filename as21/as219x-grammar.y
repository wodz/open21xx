/*
 * as219x-grammar.y
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

char version[] = "Open219x Assembler Version " VERSION_NUMBER;

#define INDIRECT_DAG(x)       (((x) >> DAG_GROUP_OFFSET) & 1)
#define INDIRECT_IREG(x)      (((x) >> IREG_OFFSET) & 3)
#define I_M(x)                ((x) & 0xf)
#define DREG(x)               (((x) >> 4) & 0xf)

enum
{
    SF_OFFSET = 12,
    XREG_OFFSET = 8,
    YREG_OFFSET = 0,
    MS_OFFSET = 15,
    DAG_GROUP_OFFSET = 13,
    INDIRECT_RGP_OFFSET = 8,
    INDIRECT_REG_OFFSET = 4,
    DIRECTION_OFFSET = 12,
    IREG_OFFSET = 2,
    MREG_OFFSET = 0,
    MAC_SQUARE = 0x10,
    SF_OR = 1 << SF_OFFSET,
    SF_HI = 0 << (SF_OFFSET + 1),
    SF_LO = 1 << (SF_OFFSET + 1),
    SF_HIX = 1 << SF_OFFSET,
    Z_MASK = 1 << Z_OFFSET,
    ALU_MAC_MASK = 1 << (AMF_OFFSET + 4),
    SF_NORM_LO_OR = 0xb,
    SF_EXP_HI = 0xc,
    SF_EXP_LO = 0xe,
    UNCONDITIONAL_AMF = 0x20,
    RESTRICTED_AMF = 0x0,
    RESTRICTED_MASK = 0x7ff00,
    IF_TRUE = 0xf,
    Y0 = 1 << 12,
    INDIRECT_RGP_MASK = 3 << INDIRECT_RGP_OFFSET,
    INDIRECT_D_MASK = 1 << 12,
    INDIRECT_G_MASK = 1 << 13,
    INDIRECT_U_MASK = 1 << 14,
    INDIRECT_MS_MASK = 1 << 15
};

enum
{
    REG_AX0 = 0x0,
    REG_AX1 = 0x1,
    REG_MX0 = 0x2,
    REG_MX1 = 0x3,
    REG_AY0 = 0x4,
    REG_AY1 = 0x5,
    REG_MY0 = 0x6,
    REG_MY1 = 0x7,
    REG_MR2 = 0x8,
    REG_SR2 = 0x9,
    REG_AR = 0xa,
    REG_SI = 0xb,
    REG_MR1 = 0xc,
    REG_SR1 = 0xd,
    REG_MR0 = 0xe,
    REG_SR0 = 0xf,
    REG_SSTAT_RO = 0x32,
    REG_SE = 0x35,
    REG_SB = 0x36,
    REG_AF = 0x40,
    REG_YOP_ZERO =0x41
};

enum
{
    MUL_RND = 0x01,
    MAC_RND = 0x02,
    MSUB_RND = 0x03,
    MUL_SS = 0x04,
    MUL_SU = 0x05,
    MUL_US = 0x06,
    MUL_UU = 0x07,
    MAC_SS = 0x08,
    MAC_SU = 0x09,
    MAC_US = 0x0a,
    MAC_UU = 0x0b,
    MSUB_SS = 0x0c,
    MSUB_SU = 0x0d,
    MSUB_US = 0x0e,
    MSUB_UU = 0x0f
};

int max_error_count = 15;
extern int ppdebug;

static int init_24;
static unsigned long initial_var_offset;
static symbol_scope_t scope;
static memory_space_t previous_space, current_space;

/* used for parsing .var directives */
static symbol_hdl var_symbol;
static int var_length;

static const char page_wrong_context[] =
    "The PAGE() operator is illegal in this context";

enum
{
    ADSP_2191         = 0x00000001,
    ADSP_219X_DEFAULT = 0x00000001
};
int processor_flags;
struct processor_list processor_list[] =
{
    { NULL,  ADSP_219X_DEFAULT },
    { "191", ADSP_219X_DEFAULT },
    { "192", ADSP_219X_DEFAULT },
    { "195", ADSP_219X_DEFAULT },
    { "196", ADSP_219X_DEFAULT }
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
    struct code2
    {
        unsigned long first;
        unsigned long second;
    } code2;
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
%token <integer> LOGICAL_OR LOGICAL_AND COMPARE_EQUAL COMPARE_NOT_EQUAL
%token <integer> GREATER_THAN_EQUAL LESS_THAN_EQUAL SHIFT_LEFT SHIFT_RIGHT
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

/* END SHARED TOKENS */

%token REG DB LJUMP LCALL FLUSH CACHE SETINT CLRINT INT SEC_DAG
%token SWCOND SR2 IRPTL
%token B0 B1 B2 B3 B4 B5 B6 B7 SYSCTL CACTL
%token IRPTL LPSTACKA LPSTACKP STACKA STACKP
%token DMPG1 DMPG2 IJPG IOPG CCODE

%type <code2> operation2 conditionable_op2
%type <code> operation condition if_cond term conditionable_op
%type <code> alu_mac_op shift_op status_only
%type <code> alu_xop alu_yop alu_operation bit_op bilogic
%type <code> ms_result ms_update mul_type mac_op
%type <code> mac_type msub_type
%type <code> shift_hi_lo shift_hix_lo shift_immediate
%type <code> jump_call delayed_branch ljump_lcall
%type <code> stack stack_list ena_dis ena_dis_list push_pop
%type <code> alu_reg_file reg dreg i_reg m_reg
%type <code> indirect indirect_immod
%type <symbol> symbol_name
%type <code> reg_move indirect_rw indirect_immod_rw
%type <integer> var_array
%type <offset> mode
%type <memory_space> memory_space
%type <section_type> section_type
%type <code> multifunction rti_option rti_list
%type <integer> sysreg

%type <expression> expression logical_or_expression logical_and_expression
%type <expression> or_expression xor_expression and_expression
%type <expression> equality_expression relational_expression
%type <expression> shift_expression additive_expression
%type <expression> multiplicative_expression unary_expression
%type <expression> primary_expression
%type <expression> number
%type <expression> carry_expression borrow_expression
%type <integer> constant_expression

%{

static unsigned long condition( unsigned long op, unsigned long condition );
static unsigned long dm_direct( unsigned long opreg, expression_t *expression,
                         int dmwrite );
static unsigned long io_rw( int write, expression_t *expression,
                            unsigned long opreg );
static unsigned long system_reg( int write, int sys_reg, unsigned long opreg );
static unsigned long indirect_rw( int write, unsigned long mem_type,
                                  unsigned long opreg, unsigned long indirect );
static unsigned long indirect_immod( unsigned long ireg, expression_t *immediate,
                                     int post_modify );
static unsigned long indirect_immod_rw( int write, unsigned long opreg,
                                        unsigned long indirect );
static unsigned long indirect( unsigned long ireg, unsigned long mreg,
                               int post_modify );
static unsigned long mac_op_xy( int amf, int dreg1, int dreg2 );
static unsigned long alu_op_x( int amf, int dreg );
static int is_alu_xop( int dreg );
static int is_alu_yop( int dreg );
static unsigned long alu_sub_xy( int amf, int dreg1, int dreg2 );
static void alu_mac_clash( unsigned long code );
static unsigned long emit_var_file( const string_t *string, int init_24 );
static int check_offset( int number, int bits );

/* prototypes for multifunction operations */
static unsigned long alu_mac_with_indirect_rw( unsigned long op,
                                               unsigned long dm );
static unsigned long shift_with_indirect_rw( unsigned long op,
                                             unsigned long dm );
static unsigned long alu_mac_with_reg_move( unsigned long op,
                                            unsigned long reg );
static unsigned long shift_with_reg_move( unsigned long op,
                                          unsigned long reg );
static unsigned long memory_2reads( unsigned long dm,
                                    unsigned long pm );
static unsigned long alu_mac_with_memory_2reads( unsigned long op,
                                                 unsigned long dm,
                                                 unsigned long pm );

static unsigned long alu_op_xy( int amf, int dreg1, int dreg2 );

%}
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
    | operation2 ';' /* the two word operations */
        {
            emit( $1.first, TRUE, LIST_ITEM_CODE );
            emit( $1.second, TRUE, LIST_ITEM_CODE );
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
    | CIRC /* ignore */
        {
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
                    rel_type = R_ADSP219X_DATADM;
                }
                else
                {
                    if ( init_24 )
                    {
                        rel_type = R_ADSP219X_DATA24;
                    }
                    else
                    {
                        rel_type = R_ADSP219X_DATAPM;
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
                    rel_type = R_ADSP219X_DATADM;
                }
                else
                {
                    if ( init_24 )
                    {
                        rel_type = R_ADSP219X_DATA24;
                    }
                    else
                    {
                        rel_type = R_ADSP219X_DATAPM;
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

operation2:
      DM indirect '=' expression
        {
            if ( ($2 & (1 << 14)) == 0 )
            {
                yyerror( "Only post-modify with update is allowed" );
            }
            $2 &= ~(1 << 14);
            $$.first = 0x078000 | $2;
            $$.second =  0;
            if ( IS_CONSTANT($4) )
            {
                if ( $4.addend < -0x8000 || $4.addend > 0xffff )
                {
                    yyerror( "Immediate data is out of range" );
                }
                else
                {
                    $$.first |= ($4.addend & 0xff) << 4;
                    $$.second |= ($4.addend & 0xff00) << 4;
                }
            }
            else
            {
                symbol_add_relocation( $4.symbol, $4.addend,
                                       ($4.type & SYMBOL_MASK) | R_ADSP219X_DMLOAD );
            }
        }
    | PM indirect '=' expression ':' number
        {
            if ( $6.addend != 24 )
            {
                yywarn( "Assuming a 24 bit wide write" );
            }
            $$.first = 0x07c000 | $2;
            $$.second = 0x0;
            if ( IS_CONSTANT($4) )
            {
                if ( $4.addend < -0x800000 || $4.addend > 0xffffff )
                {
                    yyerror( "Immediate data is out of range" );
                }
                else
                {
                    $$.first |= ($4.addend & 0xff00) >> 4;
                    $$.second |= ($4.addend & 0xff) | (($4.addend & 0xff0000) >> 4);
                }
            }
            else
            {
                symbol_add_relocation( $4.symbol, $4.addend,
                                       ($4.type & SYMBOL_MASK) | R_ADSP219X_PMLOAD );
            }
        }
    | if_cond conditionable_op2
        {
            $$.first = $2.first | $1;
            $$.second = $2.second;
        }
    | conditionable_op2
        {
            $$.first = $1.first | IF_TRUE;
            $$.second = $1.second;
        }
    ;

operation:
      if_cond conditionable_op
        {
            $$ = condition( $2, $1 );
        }
    | conditionable_op
        {
            $$ = condition( $1, IF_TRUE );
        }
    | status_only
        {
            if ( ($1 & BO_MASK) != RESTRICTED_AMF )
            {
                yyerror( "Invalid register or constant in this operation" );
                $1 &= RESTRICTED_MASK;
            }
            $$ = $1 | 0x2800aa;
        }
    | SAT ms_result
        {
            $$ = 0x030000 | $2 >> 4;
        }
    | DO expression term
        {
            $$ = 0x160000 | $3;
            if ( IS_CONSTANT($2) )
            {
                $$ |= check_offset($2.addend, 12) << 4;
            }
            else
            {
                symbol_add_relocation( $2.symbol, $2.addend,
                                       ($2.type & SYMBOL_MASK) | R_ADSP219X_DO );
            }
        } 
    | DIVS alu_yop ',' alu_xop
        {
            $$ = 0x038000 | $2 | $4;
        }
    | DIVQ alu_xop
        {
            $$ = 0x03d000 | $2;
        }
    | shift_update OR ASHIFT dreg shift_immediate shift_hi_lo
        {
            $$ = 0x0f0000 | (0x4 << SF_OFFSET) | SF_OR |
                $4 << XREG_OFFSET | $5 | $6;
        }
    | shift_assign ASHIFT dreg shift_immediate shift_hi_lo
        {
            $$ = 0x0f0000 | (0x4 << SF_OFFSET) |
                $3 << XREG_OFFSET | $4 | $5;
        }
    | shift_update OR LSHIFT dreg shift_immediate shift_hi_lo
        {
            $$ = 0x0f0000 | (0x0 << SF_OFFSET) | SF_OR |
                $4 << XREG_OFFSET | $5 | $6;
        }
    | shift_assign LSHIFT dreg shift_immediate shift_hi_lo
        {
            $$ = 0x0f0000 | (0x0 << SF_OFFSET) |
                $3 << XREG_OFFSET | $4 | $5;
        }
    | shift_update OR NORM dreg shift_immediate shift_hi_lo
        {
            $$ = 0x0f0000 | (0x8 << SF_OFFSET) | SF_OR |
                $4 << XREG_OFFSET | $5 | $6;
        }
    | shift_assign NORM dreg shift_immediate shift_hi_lo
        {
            $$ = 0x0f0000 | (0x8 << SF_OFFSET) |
                $3 << XREG_OFFSET | $4 | $5;
        }
    | reg_move
        {
            $$ = 0x0d0000 | $1;
        }
    | reg '=' DM '(' expression ')'
        {
            $$ = dm_direct( $1, &$5, FALSE );
        }
    | DM '(' expression ')' '=' reg
        {
            $$ = dm_direct( $6, &$3, TRUE );
        }
    | reg '=' expression
        {
            unsigned long group;
            unsigned long reg;

            group = REGISTER_GROUP($1);
            reg = REGISTER($1);
            if ( group > 3 )
            {
                yyerror( "Impossible to load this register");
                group = 0;
                reg = 0;
            }
            else if ($1 == REG_SSTAT_RO)
                yyerror("Writing a read only register");
            switch( group )
            {
                case 0:
                    $$ = 0x400000;
                    break;
                case 1:
                    $$ = 0x500000;
                    break;
                case 2:
                    $$ = 0x300000;
                    break;
                case 3:
                    $$ = 0x100000;
                    break;
            }    
            $$ |= reg;
            if ( IS_CONSTANT($3) )
            {
                if ( group == 3 )
                {
                    if ($3.addend < -0x800 || $3.addend > 0xfff)
                        yyerror("Immediate value is out of range");
                    else
                        $$ |= (($3.addend & 0xfff) << 4);
                }
                else
                {
                    if ($3.addend < -0x8000 || $3.addend > 0xffff)
                        yyerror("Immediate value is out of range");
                    else
                        $$ |= (($3.addend & 0xffff) << 4);
                }
            }
            else
            {
                symbol_add_relocation( $3.symbol, $3.addend,
                                       ($3.type & SYMBOL_MASK) | 
                                            (group == 3 ? R_ADSP219X_IMM12 :
                                                          R_ADSP219X_IMM16) );
            }
        }
    | IO '(' expression ')' '=' reg
        {
            $$ = io_rw( TRUE, &$3, $6 );
        }  
    | reg '=' IO '(' expression ')'
        {
            $$ = io_rw( FALSE, &$5, $1 );
        }
    | IDLE
        {
            $$ = 0x020000;
        }
    | IDLE '(' constant_expression ')'
        {
            $$ = 0x020000;
            if ($3 >= 0 && $3 <= 15)
                $$ |= $3;
            else
                yyerror("Illegal divisor");
        }
    | MODIFY indirect
        {
            if ( ($2 & 1 << 14) == 0 )
            {
                yyerror( "Only post-modify with update allowed for MODIFY" );
            }
            $2 &= ~(1 << 14);
            $$ = 0x018000 | $2;
        }
    | MODIFY indirect_immod
        {
            if ( ($2 & 1 << 16) == 0 )
            {
                yyerror( "Only post-modify with update allowed for MODIFY" );
            }
            $2 &= ~(1 << 16);
            $$ = 0x010000 | $2;
        }
    | NOP
        {
            $$ = 0x000000;
        }
    | ena_dis_list
        {
            $$ = 0x0c0000 | $1;
        }
    | stack_list     { $$ = 0x040000 | $1; }
    | indirect_rw
        {
            $$ = $1 | 0x150000;
        }
    | indirect_rw ',' reg_move
        {
            unsigned long move_src_reg, move_dst_reg, write_src_reg;
            unsigned long move_src_group, move_dst_group, write_src_group;

            if ( ($1 & INDIRECT_MS_MASK) != 0 )
                yyerror( "Reference must be to data memory" );
            if ( ($1 & INDIRECT_D_MASK) == 0 )
                yyerror( "Operation must be a memory write" );
            move_src_group = ($3 & 0x300) >> 8;
            move_dst_group = ($3 & 0xc00) >> 10;
            move_src_reg = ($3 & 0xf);
            move_dst_reg = ($3 & 0xf0) >> 4;
            write_src_reg = ($1 & 0xf0) >> 4;
            write_src_group = ($1 & 0x300) >> 8;
            if ( move_src_group != move_dst_group ||
                 move_src_group != write_src_group ||
                 (move_src_group - 1) != INDIRECT_DAG($1) )
                yyerror( "All registers must be from the same DAG" );
            else if ( INDIRECT_IREG($1) != move_src_reg )
                yyerror( "Move source and memory index must be the same register" );
            else if ( write_src_reg != move_dst_reg )
                yyerror( "Write source and move destination must be the same register" );
            else if ( write_src_reg >= 12 )
                yyerror( "Write source register must be part of the DAG" );
            else if ( move_src_reg == move_dst_reg )
                yyerror( "Move source and destination cannot be the same register" );
            $$ = 0x151800 | $1;
        }
    | indirect_immod_rw
        {
            $$ = $1 | 0x080000;
        }
    | reg '=' REG '(' constant_expression ')'
        {
            $$ = system_reg( FALSE, $5, $1 );
        }
    | REG '(' constant_expression ')' '=' reg
        {
            $$ = system_reg( TRUE, $3, $6 );
        }
    | reg '=' REG '(' sysreg ')'
        {
            $$ = system_reg( FALSE, $5, $1 );
        }
    | REG '(' sysreg ')' '=' reg
        {
            $$ = system_reg( TRUE, $3, $6 );
        }
    | multifunction
        {
            $$ = $1;
        }
    | FLUSH CACHE
        {
            $$ = 0x040080;
        }
    | SETINT constant_expression
        {
            if ( $2 < 0 || $2 > 15 )
            {
                $2 = 0;
                yyerror( "Invalid interrupt number" );
            }
            $$ = 0x070000 | $2;
        }
    | CLRINT constant_expression
        {
            if ( $2 < 0 || $2 > 15 )
            {
                $2 = 0;
                yyerror( "Invalid interrupt number" );
            }
            $$ = 0x070020 | $2;
        }
    ;

status_only:
      NONE '=' alu_operation
        {
            $$ = $3;
        }
    | mac_op
        {
            $$ = $1;
        }
    ;

multifunction:
      alu_mac_op ',' indirect_rw
        {
            $$ = alu_mac_with_indirect_rw( $1, $3 );
        }
    | indirect_rw ',' alu_mac_op
        {
            $$ = alu_mac_with_indirect_rw( $3, $1 );
        }
    | shift_op ',' indirect_rw
        {
            $$ = shift_with_indirect_rw( $1, $3 );
        }
    | indirect_rw ',' shift_op
        {
            $$ = shift_with_indirect_rw( $3, $1 );
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
    | indirect_rw ',' indirect_rw
        {
            $$ = memory_2reads( $1, $3 );
        }
    | alu_mac_op ',' indirect_rw ',' indirect_rw
        {
            $$ = alu_mac_with_memory_2reads( $1, $3, $5 );
        }
    | indirect_rw ',' alu_mac_op ',' indirect_rw
        {
            $$ = alu_mac_with_memory_2reads( $3, $1, $5 );
        }
    | indirect_rw ',' indirect_rw ',' alu_mac_op
        {
            $$ = alu_mac_with_memory_2reads( $5, $1, $3 );
        }
    ;

reg_move: reg '=' reg
        {
            $$ = 0;
            if ($1 == REG_SSTAT_RO)
                yyerror("Attempting to write a read only register");
            else
                $$ = REGISTER($3) | (REGISTER($1) << 4) |
                     (REGISTER_GROUP($3) << 8) | (REGISTER_GROUP($1) << 10);
        }
    ;

indirect_rw:
      reg '=' DM indirect
        {
            $$ = indirect_rw( FALSE, 0 << MS_OFFSET, $1, $4);
        }
    | reg '=' PM indirect
        {
            $$ = indirect_rw( FALSE, 1 << MS_OFFSET, $1, $4);
        }
    | DM indirect '=' reg
        {
            $$ = indirect_rw( TRUE, 0 << MS_OFFSET, $4, $2);
        }
    | PM indirect '=' reg
        {
            $$ = indirect_rw( TRUE, 1 << MS_OFFSET, $4, $2);
        }
    ;

indirect_immod_rw:
      reg '=' DM indirect_immod
        {
            $$ = indirect_immod_rw( FALSE, $1, $4);
        }
    | DM indirect_immod '=' reg
        {
            $$ = indirect_immod_rw( TRUE, $4, $2);
        }
    ;

conditionable_op2:
      ljump_lcall expression delayed_branch
        {
            int offset;

            $$.first = 0x050000 | $1 << 12;
            $$.second = 0x0;
            if ( IS_CONSTANT($2) )
            {
                offset = check_offset( $2.addend, 24 );
                if ( $3 )
                {
                    yyerror( "Delayed branch is not allowed for long jump/call" );
                }
                $$.first |= (offset & 0xff0000) >> 12;
                $$.second |= (offset & 0xffff) << 4;
            }
            else
            {
                symbol_add_relocation( $2.symbol, $2.addend,
                                       ($2.type & SYMBOL_MASK) | R_ADSP219X_LONG );
            }
        }
    ;

conditionable_op:
      RTS rti_option
        {
            if ( ($2 & (1 << 13)) )
            {
                yyerror( "SS is not permitted with the RTS instruction" );
                $2 &= ~(1<<13);
            }
            $$ = 0x0a0000 | $2;
        }
    | RTI rti_option
        {
            $$ = 0x0a0000 | $2 | 1 << 14;
        }
    | jump_call '(' i_reg ')' delayed_branch
        {
            $$ = 0x0b0000 | ($1 << 14) | I_DAG($3) << 13 |
                $5 << 15 | I_REGISTER($3) << 2;
        }
    | jump_call expression delayed_branch
        {
            int offset;

            /* generate the unconditional form and covert if its
             * conditional */
            $$ = 0x1c0000 | ($1 << 2) | $3 << 3;
            if ( IS_CONSTANT($2) )
            {
                offset = check_offset( $2.addend, 16 );
                $$ |= (offset & 0x3fff) << 4 | (offset & 0xc000) >> 14;
            }
            else
            {
                symbol_add_relocation( $2.symbol, $2.addend,
                                       ($2.type & SYMBOL_MASK) | R_ADSP219X_REL );
            }
        }
    | alu_mac_op
        {
            $$ = $1 | 0x200000 ;
        }
    | shift_op
        {
            $$ = $1 | 0x0e0000;
        }
    ;

jump_call:
      JUMP  { $$ = 0; }
    | CALL  { $$ = 1; }
    ;

ljump_lcall:
      LJUMP { $$ = 0; }
    | LCALL { $$ = 1; }
    ;

delayed_branch:
      '(' DB ')'
      {
          $$ = 1;
      }
    | /* empty */
      {
          $$ = 0;
      }
    ;

rti_option:
      rti_list
      {
          $$ = $1;
      }
    | /* empty */
      {
          $$ = 0;
      }
    ;  

rti_list:
      rti_list '(' DB ')'
        {
            if ( ($1 & (1 << 15)) )
            {
                yywarn( "Ignoring second instance of DB option" );
            }
            $$ = $1 | 1 << 15;
        }
    | rti_list '(' SS ')'
        {
            if ( ($1 & (1 << 13)) )
            {
                yywarn( "Ignoring second instance of SS option" );
            }
            $$ = $1 | 1 << 13;
        }
    | '(' DB ')'
        {
            $$ = 1 << 15;
        }
    | '(' SS ')'
        {
            $$ = 1 << 13;
        }
    ;

ena_dis_list:
        ena_dis_list ',' ena_dis mode
        {
            if ( ((3 << $4) & $1) != 0)
            {
                yyerror("Ignoring multiple references to same mode");
            }
            else
            {
                $$ = $1 | ($3 << $4);
            }
        }
    | ena_dis mode
        {
            $$ = $1 << $2;
        }
    ;

ena_dis:
      ENA
        {
            $$ = 3;
        }
    | DIS
        {  
            $$ = 2;
        }
    ;

mode:
      INT
        {
            $$ = 0;
        }
    | SEC_DAG
        {
            $$ = 2;
        }
    | SEC_REG
        {
            $$ = 4;
        }
    | BIT_REV
        {
            $$ = 6;
        }
    | AV_LATCH
        {
            $$ = 8;
        }
    | AR_SAT
        {
            $$ = 10;
        }
    | M_MODE  
        {
            $$ = 12;  
        }
    | TIMER
        {  
            $$ = 14;
        }
    ;

stack_list:
      push_pop stack
       {
           $$ = $1 << $2;
       }
    | push_pop stack ',' stack_list
        {
            if ( ((3 << $2) & $4) != 0 )
            {
                yyerror( "Ignoring multiple references to the same stack");
                $$ = $4;
            }
            else
                $$ = ($1 << $2) | $4;
        }
    ;

stack:
      STS
       {
           $$ = 0x0;
       }
    | PC
       {
           $$ = 5;
       }
    | LOOP
       {
           $$ = 3;
       }
    ;

push_pop:
      PUSH
       {
           $$ = 2;
       }
    | POP
       {
           $$ = 3;
       }
    ;
    
alu_mac_op:
      reg '=' alu_operation
        {
            $$ = $3;
            if ($1 == REG_AR)
                $$ |= 0x0 << Z_OFFSET;
            else if ( $1 == REG_AF )
                $$ |= 0x1 << Z_OFFSET;
            else
                yyerror("Assigning to an invalid register");
        }
    | ms_result '=' mac_op
        {
            if ( (($3 & (0x1e << AMF_OFFSET)) == 2 << AMF_OFFSET ||
                  ($3 & (0x18 << AMF_OFFSET)) == 8 << AMF_OFFSET) &&
                 ($3 & Z_MASK) != $1 )
            {
                yyerror( "Accumulator and result register must be the same" );
            }
                 
            $$ = $1 | $3;
        }
    ;

mac_op:
      dreg '*' dreg mul_type
        {
            $$ = mac_op_xy( $4, $1, $3 );
        }
    | ms_result mac_type
        {
            if ( $2 != MAC_RND )
            {
                yyerror( "Only (RND) is permitted." );
            }
            $$ = $2 << AMF_OFFSET | YOP_ZERO |
                $1;
        }
    | ms_result '+' dreg '*' dreg mac_type
        {
            $$ = mac_op_xy( $6, $3, $5 ) | $1;
        }
    | ms_result '-' dreg '*' dreg msub_type
        {
            $$ = mac_op_xy( $6, $3, $5 ) | $1;
        }
    | constant_expression
        {
            if ( $1 != 0 )
            {
                yyerror( "Expression must evaluate to zero" );
            }
            $$ = MUL_SS << AMF_OFFSET | YOP_ZERO;
        }
    ;

shift_op:
      shift_update OR ASHIFT dreg shift_hi_lo
        {
            $$ = 0x4 << SF_OFFSET | SF_OR | $4 << XREG_OFFSET | $5;
        }
    | shift_assign ASHIFT dreg shift_hi_lo
        {
            $$ = 0x4 << SF_OFFSET | $3 << XREG_OFFSET | $4;
        }
    | shift_update OR LSHIFT dreg shift_hi_lo
        {
            $$ = 0x0 << SF_OFFSET | SF_OR | $4 << XREG_OFFSET | $5;
        }
    | shift_assign LSHIFT dreg shift_hi_lo
        {
            $$ = 0x0 << SF_OFFSET | $3 << XREG_OFFSET | $4;
        }
    | shift_update OR NORM dreg shift_hi_lo
        {
            $$ = 0x8 << SF_OFFSET | SF_OR | $4 << XREG_OFFSET | $5;
        }
    | shift_assign NORM dreg shift_hi_lo
        {
            $$ = 0x8 << SF_OFFSET | $3 << XREG_OFFSET | $4;
        }
    | reg '=' EXP dreg shift_hix_lo
        {
            if ($1 != REG_SE)
                yyerror("Invalid assign to register");
            $$ = 0xc << SF_OFFSET | $4 << XREG_OFFSET | $5;
        }
    | reg '=' EXPADJ dreg
        {
            if ($1 != REG_SB)
                yyerror( "Invalid assign to register");
            $$ = 0xf << SF_OFFSET | $4 << XREG_OFFSET;
        }
    ;

shift_assign:
      ms_result '='
        {
            if ( $1 == 0 )
            {
                yyerror( "The result can only be assigned to the SR register" );
            }
        }
    ;

shift_update:
      ms_update
        {
            if ( $1 == 0 )
            {
                yyerror( "The result can only be assigned to the SR register" );
            }
        }
    ;

/* alu rules */
alu_operation:
      alu_reg_file '+' alu_reg_file
        {
            $$ = alu_op_xy( 0x13, $1, $3 ); 
        }
    | alu_reg_file '+' alu_reg_file '+' CARRY
        {
            $$ = alu_op_xy( 0x12, $1, $3 );
        }
    | alu_reg_file '+' CARRY
        {
            $$ = alu_op_x( 0x12, $1 );
        }
    | alu_reg_file '+' expression
        {
            int op;

            op = is_alu_yop( $1 );
            if ( op >= 0 && IS_CONSTANT($3) && $3.addend == 1 )
            {
                $$ = 0x11 << AMF_OFFSET | op << YOP_OFFSET;
            }
            else 
            {
                op = is_alu_xop( $1 );
                if ( op >= 0 )
                {
                    op <<= XOP_OFFSET;
                    if ( IS_CONSTANT($3) )
                    {
                        unsigned long yyccbo = check_yyccbo($3.addend);
                        
                        if ( yyccbo )
                        {
                            $$ = 0x13 << AMF_OFFSET | op | yyccbo;
                        }
                        else
                        {
                            yyccbo = check_yyccbo( -$3.addend );
                            if ( yyccbo )
                            {
                                $$ = 0x17 << AMF_OFFSET | op | yyccbo;
                            }
                            else
                            {
                                yyerror("Invalid constant specified");
                                $$ = 0x17 << AMF_OFFSET | op | DEFAULT_YYCCBO;
                            }
                        }
                    }
                    else
                    {
                        $$ = 0x13 << AMF_OFFSET | op;
                        symbol_add_relocation( $3.symbol, $3.addend,
                                              ($3.type & SYMBOL_MASK) | R_ADSP219X_YYCCBO );
                        
                    }
                }
                else 
                {
                    if ( !IS_CONSTANT($3) || $3.addend != 1 )
                    {
                        yyerror("Expression must evaluate to 1");
                    }
                    $$ = 0x11 << AMF_OFFSET | $1 << YREG_OFFSET |
                        UNCONDITIONAL_AMF;
                }
            }
        }
    | alu_reg_file '+' carry_expression
        {
            unsigned long xop;

            xop = is_alu_xop( $1 );
            if ( xop < 0 )
            {
                xop = 0;
                yyerror( "The register is restricted to being an XOP" );
            }
            xop <<= XOP_OFFSET;
            $$ = 0x12 << AMF_OFFSET | xop;
            if ( IS_CONSTANT($3) )
            {
                unsigned long yyccbo = check_yyccbo($3.addend);
            
                if ( yyccbo )
                {
                    $$ |= yyccbo;
                }
                else
                {
                    yyerror("Invalid constant specified");
                    $$ |= DEFAULT_YYCCBO;
                }
            }
            else
            {
                symbol_add_relocation( $3.symbol, $3.addend,
                                       ($3.type & SYMBOL_MASK) | R_ADSP219X_YYCCBO );
            }
        }
    | alu_reg_file '-' alu_reg_file
        {
            $$ = alu_sub_xy( 0x17, $1, $3 ); 
        }
    | alu_reg_file '-' alu_reg_file '+' borrow
        {
            $$ = alu_sub_xy( 0x16, $1, $3 ); 
        }
    | alu_reg_file '+' borrow
        {
            $$ = alu_op_x( 0x16, $1 ); 
        }
    | alu_reg_file '-' expression
        {
            unsigned long yyccbo;
            int op;

            op = is_alu_yop( $1 );
            if ( op >= 0 && IS_CONSTANT($3) && $3.addend == 1 )
            {
                $$ = 0x18 << AMF_OFFSET | op << YOP_OFFSET;
            }
            else
            {
                op = is_alu_xop( $1 );
                if ( op >= 0 )
                {
                    op <<= XOP_OFFSET;
                    if ( IS_CONSTANT($3) )
                    {
                        yyccbo = check_yyccbo($3.addend);
                        if ( yyccbo )
                        {
                            $$ = 0x17 << AMF_OFFSET | op | yyccbo;
                        }
                        else
                        {
                            yyccbo = check_yyccbo( -$3.addend );
                            if ( yyccbo )
                            {
                                $$ = 0x13 << AMF_OFFSET | op | yyccbo;
                            }
                            else
                            {
                                yyerror("Invalid constant specified");
                                $$ = 0x13 << AMF_OFFSET | op | DEFAULT_YYCCBO;
                            }
                        }
                    }
                    else
                    {
                        $$ = 0x17 << AMF_OFFSET | op;
                        symbol_add_relocation( $3.symbol, $3.addend,
                                               ($3.type & SYMBOL_MASK) | R_ADSP219X_YYCCBO );
                    }
                }
                else
                {
                    if ( !IS_CONSTANT($3) || $3.addend != 1 )
                    {
                        yyerror("Expression must evaluate to 1");
                    }
                    $$ = 0x18 << AMF_OFFSET | $1 << YREG_OFFSET |
                        UNCONDITIONAL_AMF;
                }
            }
        }
    | alu_reg_file '-' borrow_expression
        {
            unsigned long xop;

            xop = is_alu_xop( $1 );
            if ( xop < 0 )
            {
                xop = 0;
                yyerror( "The register is restricted to being an XOP" );
            }
            $$ = 0x16 << AMF_OFFSET | xop << XOP_OFFSET;
            if ( IS_CONSTANT($3) )
            {
                unsigned long yyccbo = check_yyccbo($3.addend);

                if ( yyccbo )
                {
                    $$ |= yyccbo;
                }
                else
                {
                    yyerror("Invalid constant specified");
                    $$ |= DEFAULT_YYCCBO;
                }
            }
            else
            {
                symbol_add_relocation( $3.symbol, $3.addend,
                                       ($3.type & SYMBOL_MASK) | R_ADSP219X_YYCCBO );
            }
        }
    | '-' alu_reg_file '+' borrow
        {
            $$ = alu_op_x( 0x1a, $2 ); 
        }
    | '-' alu_reg_file '+' expression
        {
            unsigned long xop;

            xop = is_alu_xop( $2 );
            if ( xop < 0 )
            {
                xop = 0;
                yyerror( "The register is restricted to being an XOP" );
            }
            $$ = 0x19 << AMF_OFFSET | xop << XOP_OFFSET;
            if ( IS_CONSTANT($4) )
            {
                unsigned long yyccbo = check_yyccbo($4.addend);
                
                if ( yyccbo )
                {
                    $$ |= yyccbo;
                }
                else
                {
                    yyerror("Invalid constant specified");
                    $$ |= DEFAULT_YYCCBO;
                }
            }
            else
            {
                symbol_add_relocation( $4.symbol, $4.addend,
                                       ($4.type & SYMBOL_MASK) | R_ADSP219X_YYCCBO );
            }
        }
    | '-' alu_reg_file '+' borrow_expression
        {
            unsigned long xop;

            xop = is_alu_xop( $2 );
            if ( xop < 0 )
            {
                xop = 0;
                yyerror( "The register is restricted to being an XOP" );
            }
            $$ = 0x1a << AMF_OFFSET | xop << XOP_OFFSET;
            if ( IS_CONSTANT($4) )
            {
                unsigned long yyccbo = check_yyccbo($4.addend);
            
                if ( yyccbo )
                {
                    $$ |= yyccbo;
                }
                else
                {
                    yyerror("Invalid constant specified");
                    $$ |= DEFAULT_YYCCBO;
                }
            }
            else
            {
                symbol_add_relocation( $4.symbol, $4.addend,
                                       ($4.type & SYMBOL_MASK) | R_ADSP219X_YYCCBO );
            }
        }
    | alu_reg_file bilogic alu_reg_file
        {
            $$ = alu_op_xy( $2, $1, $3 ); 
        }
    | alu_reg_file bilogic expression
        {
            unsigned long xop;

            xop = is_alu_xop( $1 );
            if ( xop < 0 )
            {
                xop = 0;
                yyerror( "The register is restricted to being an XOP" );
            }
            $$ = xop << XOP_OFFSET | $2 << AMF_OFFSET;
            if ( IS_CONSTANT($3) )
            {
                unsigned long yyccbo = check_yyccbo($3.addend);
            
                if ( yyccbo )
                {
                    $$ |= yyccbo;
                }
                else
                {
                    yyerror("Invalid constant specified");
                    $$ |= DEFAULT_YYCCBO;
                }
            }
            else
            {
                symbol_add_relocation( $3.symbol, $3.addend,
                                       ($3.type & SYMBOL_MASK) | R_ADSP219X_YYCCBO );
            }
        }
    | bit_op expression OF alu_reg_file
        {
            $$ = $1 | $4;
            if ( IS_CONSTANT($2) )
            {
                if ( $2.addend < 0 || $2.addend > 15)
                {
                    yyerror("Expecting a constant between 0 and 15");
                    $$ = DEFAULT_YYCCBO;
                }
                else
                {
                    $$ |= BITNO_TO_YYCC($2.addend);
                }
            }
            else
            {
                symbol_add_relocation( $2.symbol, $2.addend,
                                       ($2.type & SYMBOL_MASK) | R_ADSP219X_YYCCBO_BITNO );
            }
        }
    | PASS alu_reg_file
        {
            int op;

            op = is_alu_xop( $2 );
            if ( op >= 0 )
            {
                $$ = 0x13 << AMF_OFFSET | op << XOP_OFFSET | YOP_ZERO;
            }
            else
            {
                op = is_alu_yop( $2 );
                if ( op >= 0 )
                {
                    $$ = 0x10 << AMF_OFFSET | op << YOP_OFFSET;
                }
                else
                {
                    $$ = 0x10 << AMF_OFFSET | $2 << YREG_OFFSET |
                        UNCONDITIONAL_AMF;
                }
            }
        }
    | PASS expression
        {
            if ( IS_CONSTANT($2) )
            {
                if ($2.addend == 1)
                {
                    $$ = 0x11 << AMF_OFFSET | YOP_ZERO;
                }
                else if ($2.addend == -1)
                {
                    $$ = 0x18 << AMF_OFFSET | YOP_ZERO;
                }
                else
                {
                    unsigned long yyccbo;
                    
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
                                       ($2.type & SYMBOL_MASK) | R_ADSP219X_YYCCBO );
            }
        }
    | '-' alu_reg_file
        {
            int xop;
            int yop;

            xop = is_alu_xop( $2 );
            yop = is_alu_yop( $2 );
            if ( xop >= 0 )
            {
                $$ = 0x19 << AMF_OFFSET | xop << XOP_OFFSET | YOP_ZERO;
            }
            else if ( yop >= 0 )
            {
                $$ = 0x15 << AMF_OFFSET | yop << YOP_OFFSET;
            }
            else
            {
                $$ = 0x15 << AMF_OFFSET | $2 << YREG_OFFSET |
                    UNCONDITIONAL_AMF;
            }
        }
    | NOT alu_reg_file
        {
            int op;

            op = is_alu_xop( $2 );
            if ( op >= 0 )
            {
                $$ = 0x1b << AMF_OFFSET | op << XOP_OFFSET;
            }
            else
            {
                op = is_alu_yop( $2 );
                if ( op >= 0 )
                {
                    $$ =  0x14 << AMF_OFFSET | op << YOP_OFFSET;
                }
                else
                {
                    $$ = 0x1b << AMF_OFFSET | $2 << XREG_OFFSET |
                        UNCONDITIONAL_AMF;
                }
            }
        }
    | NOT constant_expression
        {
            $$ = 0x14 << AMF_OFFSET | YOP_ZERO;
            if ( $2 != 0 )
                yyerror("Expecting \"0\"");
        }
    | ABS alu_reg_file
        {
            int xop;
            
            xop = is_alu_xop( $2 );
            if ( xop >= 0 )
            {
                $$ = 0x1f << AMF_OFFSET | xop << XOP_OFFSET;
            }
            else
            {
                $$ = 0x1f << AMF_OFFSET | $2 << XREG_OFFSET |
                    UNCONDITIONAL_AMF;
            }
        }
    ;

alu_xop: 
       AX0    { $$ = 0x0 << XOP_OFFSET; }
    |  AX1    { $$ = 0x1 << XOP_OFFSET; }
    |  AR		  { $$ = 0x2 << XOP_OFFSET; }
    |  MR0		{ $$ = 0x3 << XOP_OFFSET; }
    |  MR1		{ $$ = 0x4 << XOP_OFFSET; }
    |  MR2		{ $$ = 0x5 << XOP_OFFSET; }
    |  SR0		{ $$ = 0x6 << XOP_OFFSET; }
    |  SR1		{ $$ = 0x7 << XOP_OFFSET; }
    ;

alu_yop: 
         AY0            { $$ = 0 << YOP_OFFSET; }
    |    AY1            { $$ = 1 << YOP_OFFSET; }
    |    AF             { $$ = 2 << YOP_OFFSET; }
    ;

bilogic:
      AND
        {
            $$ = 0x1c;
        }
    | OR
        {
            $$ = 0x1d;
        }
    | XOR
        {
            $$ = 0x1e;
        }
    ;

bit_op:  
      TSTBIT { $$ = 0x1c << AMF_OFFSET | BO_BIT; }
    | SETBIT { $$ = 0x1d << AMF_OFFSET | BO_BIT; }
    | CLRBIT { $$ = 0x1c << AMF_OFFSET | BO_NOT_BIT; }
    | TGLBIT { $$ = 0x1e << AMF_OFFSET | BO_BIT; }
    ;

carry_expression:
      additive_expression '+' CARRY
        {
            $$ = $1;
        }
    ;

borrow_expression:
      additive_expression '+' borrow
        {
            $$ = $1;
        }
    ;

borrow:
      CARRY '-' constant_expression
        {
            if ( $3 != 1 )
                yyerror("Expecting \"C - 1\"");
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

ms_update:
      ms_result '=' ms_result
        {
            if ( $1 != $3 )
            {
                yyerror( "Source and destination register must be the same." );
            }
            $$ = $1;
        }
    ;

ms_result:
      MR
        { $$ = 0x0 << Z_OFFSET; }
    | SR 
        { $$ = 0x1 << Z_OFFSET; }
    ;

/* shifter specific rules */
shift_hix_lo: '(' HIX ')' { $$ = SF_HIX; }
    |    shift_hi_lo
    ;

shift_hi_lo: '(' HI ')' { $$ = SF_HI; }
    |        '(' LO ')' { $$ = SF_LO; }
    ;

shift_immediate: BY expression
        {
            if ( IS_CONSTANT($2) )
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
                                       ($2.type & SYMBOL_MASK) | R_ADSP219X_SHIFT_IMMEDIATE );
            }
        }
    ;

/* data move rules */
alu_reg_file:
      reg
        {
            $$ = $1;
            if ( REGISTER_GROUP( $1 ) != 0 && $1 != REG_AF )
            {
                yyerror( "Invalid data register in this context" );
                $$ = 0;
            }
        }
    ;

dreg:  /* register file for alu/mac operations */
      reg
        {
            $$ = $1;
            if ( REGISTER_GROUP( $1 ) != 0 )
            {
                yyerror( "Invalid data register in this context" );
                $$ = 0;
            }
        }
    ;

reg:
      AX0          { $$ = REG_AX0; }
    | AX1          { $$ = REG_AX1; }
    | MX0          { $$ = REG_MX0; }
    | MX1          { $$ = REG_MX1; }
    | AY0          { $$ = REG_AY0; }
    | AY1          { $$ = REG_AY1; }
    | MY0          { $$ = REG_MY0; }
    | MY1          { $$ = REG_MY1; }
    | MR2          { $$ = REG_MR2; }
    | SR2          { $$ = REG_SR2; }
    | AR           { $$ = REG_AR; }
    | SI           { $$ = REG_SI; }
    | MR1          { $$ = REG_MR1; }
    | SR1          { $$ = REG_SR1; }
    | MR0          { $$ = REG_MR0; }
    | SR0          { $$ = REG_SR0; }
    | I0           { $$ = 0x10; }
    | I1           { $$ = 0x11; }
    | I2           { $$ = 0x12; }
    | I3           { $$ = 0x13; }
    | M0           { $$ = 0x14; }
    | M1           { $$ = 0x15; }
    | M2           { $$ = 0x16; }
    | M3           { $$ = 0x17; }
    | L0           { $$ = 0x18; }
    | L1           { $$ = 0x19; }
    | L2           { $$ = 0x1a; }
    | L3           { $$ = 0x1b; }
    | IMASK        { $$ = 0x1c; }
    | IRPTL        { $$ = 0x1d; }
    | ICNTL        { $$ = 0x1e; }
    | STACKA       { $$ = 0x1f; }
    | I4           { $$ = 0x20; }
    | I5           { $$ = 0x21; }
    | I6           { $$ = 0x22; }
    | I7           { $$ = 0x23; }
    | M4           { $$ = 0x24; }
    | M5           { $$ = 0x25; }
    | M6           { $$ = 0x26; }
    | M7           { $$ = 0x27; }
    | L4           { $$ = 0x28; }
    | L5           { $$ = 0x29; }
    | L6           { $$ = 0x2a; }
    | L7           { $$ = 0x2b; }
    | CNTR         { $$ = 0x2e; }
    | LPSTACKA     { $$ = 0x2f; }
    | ASTAT        { $$ = 0x30; }
    | MSTAT        { $$ = 0x31; }
    | SSTAT        { $$ = REG_SSTAT_RO; }
    | LPSTACKP     { $$ = 0x33; }
    | CCODE        { $$ = 0x34; }
    | SE           { $$ = REG_SE; }
    | SB           { $$ = REG_SB; }
    | PX           { $$ = 0x37; }
    | DMPG1        { $$ = 0x38; }
    | DMPG2        { $$ = 0x39; }
    | IOPG         { $$ = 0x3a; }
    | IJPG         { $$ = 0x3b; }
    | STACKP       { $$ = 0x3f; }
    | AF           { $$ = REG_AF; }
    ;

if_cond:
      IF condition
        {
            $$ = $2;
        }
    ;

condition:
        EQ 		{ $$ = 0x0; }
    |   NE 		{ $$ = 0x1; }
    |   GT 		{ $$ = 0x2; }
    |   LE 		{ $$ = 0x3; }
    |   LT 		{ $$ = 0x4; }
    |   GE 		{ $$ = 0x5; }
    |   AV 		{ $$ = 0x6; }
    |   NOT AV 	{ $$ = 0x7; }
    |   AC 		{ $$ = 0x8; }
    |   NOT AC 	{ $$ = 0x9; }
    |   SWCOND	{ $$ = 0xa; }
    |   NOT SWCOND	{ $$ = 0xb; }
    |   MV 		{ $$ = 0xc; }
    |   NOT MV 	{ $$ = 0xd; }
    |   NOT CE 	{ $$ = 0xe; }
    ;

term:
      UNTIL CE      { $$ = 0xe; }
    | UNTIL FOREVER { $$ = 0xf; }
    | /* empty */   { $$ = 0xf; }
    ;

indirect:
      /* post-modify */
      '(' i_reg ',' m_reg ')'
        {
            $$ = indirect( $2, $4, TRUE );
        }
    | '(' i_reg PLUS_EQUAL m_reg ')'
        {
            $$ = indirect( $2, $4, TRUE );
        }
      /* pre-modify */
    | '(' m_reg ',' i_reg ')'
        {
            $$ = indirect( $4, $2, FALSE );
        }
    | '(' i_reg '+' m_reg ')'
        {
            $$ = indirect( $2, $4, FALSE );
        }
    ;

indirect_immod:
      /* post-modify */
      '(' i_reg ',' expression ')'
        {
            $$ = indirect_immod( $2, &$4, TRUE );
        }
    | '(' i_reg PLUS_EQUAL expression ')'
        {
            $$ = indirect_immod( $2, &$4, TRUE );
        }
      /* pre-modify */
    | '(' expression ',' i_reg ')'
        {
            $$ = indirect_immod( $4, &$2, FALSE );
        }
    | '(' i_reg '+' expression ')'
        {
            $$ = indirect_immod( $2, &$4, FALSE );
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

sysreg:
      B0 { $$ = 0; }
    | B1 { $$ = 1; }
    | B2 { $$ = 2; }
    | B3 { $$ = 3; }
    | B4 { $$ = 4; }
    | B5 { $$ = 5; }
    | B6 { $$ = 6; }
    | B7 { $$ = 7; }
    | SYSCTL { $$ = 8; }
    | CACTL { $$ = 0xf; }
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

void grammar_init( const char *object_name )
{
    init_24 = FALSE;
    outfile_init( object_name, EM_ADSP219X, FALSE,
                  3, 2 );
}

void grammar_term( void )
{
    outfile_term( 0 );
}

static void alu_mac_clash( unsigned long code )
{
    unsigned long reg;

    reg = DREG(code);
    if ((code & Z_MASK) == 0)  /* writing to AR or MR */
    {
        if (((code & ALU_MAC_MASK) == 0 &&  /* mac function */
             (reg == REG_MR0 || reg == REG_MR1 || reg == REG_MR2)) ||
            ((code & ALU_MAC_MASK) != 0 &&  /* alu function */
             reg == REG_AR) )
            yyerror("Multiple clauses writing to the same register");
    }
}

static void shifter_clash( unsigned long code )
{
    unsigned long reg;

    reg = DREG(code);
    if ((reg == REG_SR0 || reg == REG_SR1 || reg == REG_SR2) &&
        SHIFT_FUNCTION(code) <= SF_NORM_LO_OR)
        yyerror("Multiple clauses writing to the same register");
}

static int check_offset( int number, int bits )
{
    int field;

    field = -1 << (bits - 1);
    if ( number < field || number > ~field )
    {
        yyerror( "Offset is out of range" );
        number = 0;
    }
    return number & ~(-1 << bits);
}

static unsigned long emit_var_file( const string_t *string, int init_24 )
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

static int is_xop( int dreg )
{
    switch ( dreg )
    {
        case REG_AR:
            return 2;
        case REG_MR0:
            return 3;
        case REG_MR1:
            return 4;
        case REG_MR2:
            return 5;
        case REG_SR0:
            return 6;
        case REG_SR1:
            return 7;
    }
    return -1;
}

static int is_alu_xop( int dreg )
{
    switch ( dreg )
    {
        case REG_AX0:
            return 0;
        case REG_AX1:
            return 1;
        default:
            return is_xop( dreg );
    }
}

static int is_alu_yop( int dreg )
{
    switch ( dreg )
    {
        case REG_AY0:
            return 0;
        case REG_AY1:
            return 1;
        case REG_AF:
            return 2;
    }
    return -1;
}

static unsigned long alu_op_xy( int amf, int dreg1, int dreg2 )
{
    int xop;
    int yop;
    unsigned long opcode;

    xop = is_alu_xop( dreg1 );
    yop = is_alu_yop( dreg2 );
    if ( xop >= 0 && yop >= 0 )
    {
        opcode = (amf << AMF_OFFSET) | (xop << XOP_OFFSET) |
            (yop << YOP_OFFSET);
    }
    else if ( dreg2 == REG_AF && xop < 0 )
    {
        yyerror( "xop requires unrestricted and yop requires restricted form" );
        opcode = (amf << AMF_OFFSET) | (xop << XOP_OFFSET);
    }
    else
    {
        opcode =  (amf << AMF_OFFSET) | (dreg1 << XREG_OFFSET) |
            (dreg2 << YREG_OFFSET) | UNCONDITIONAL_AMF;
    }
    return opcode;
}


static unsigned long alu_sub_xy( int amf, int dreg1, int dreg2 )
{
    int op1;
    int op2;

    op1 = is_alu_xop( dreg1 );
    op2 = is_alu_yop( dreg2 );
    if ( op1 >= 0 && op2 >= 0 )
    {
        return amf << AMF_OFFSET | op1 << XOP_OFFSET | op2 << YOP_OFFSET;
    }

    op1 = is_alu_yop( dreg1 );
    op2 = is_alu_xop( dreg2 );
    if ( op1 >= 0 && op2 >= 0 )
    {
        assert( amf == 0x17 || amf == 0x16 );
        if ( amf == 0x17 )
        {
            amf = 0x19;
        }
        else
        {
            amf = 0x1a;
        }
        return amf << AMF_OFFSET | op1 << YOP_OFFSET | op2 << XOP_OFFSET;
    }
    return amf << AMF_OFFSET | dreg1 << XREG_OFFSET |
        dreg2 << YREG_OFFSET | UNCONDITIONAL_AMF;
}

static unsigned long alu_op_x( int amf, int dreg )
{
    int xop;
    unsigned long opcode;

    xop = is_alu_xop( dreg );
    if ( xop >= 0 )
    {
        opcode = (amf << AMF_OFFSET) | (xop << XOP_OFFSET) |
            YOP_ZERO;
    }
    else
    {
        opcode =  (amf << AMF_OFFSET) | (dreg << XREG_OFFSET) |
            UNCONDITIONAL_AMF | Y0;
    }
    return opcode;
}

static int is_mac_xop( int dreg )
{
    switch ( dreg )
    {
        case REG_MX0:
            return 0;
        case REG_MX1:
            return 1;
        default:
            return is_xop( dreg );
    }
}

static int is_mac_yop( int dreg )
{
    switch ( dreg )
    {
        case REG_MY0:
            return 0;
        case REG_MY1:
            return 1;
        case REG_SR1:
            return 2;
    }
    return -1;
}

static int is_shifter_xop( int dreg )
{
    switch ( dreg )
    {
        case REG_SI:
            return 0;
        case REG_SR2:
            return 1;
        default:
            return is_xop( dreg );
    }
}

static unsigned long mac_op_xy( int amf, int dreg1, int dreg2 )
{
    int xop;
    int yop;

    xop = is_mac_xop( dreg1 );
    if ( dreg1 == dreg2 )
    {
        if ( amf == MAC_SU || amf == MAC_US)
            yyerror("Squaring - use SS, UU, or RND");
        if ( xop >= 0 )
        {
            return amf << AMF_OFFSET | xop << XOP_OFFSET | MAC_SQUARE;
        }
        else
        {
            return amf << AMF_OFFSET | dreg1 << XREG_OFFSET |
                dreg2 << YREG_OFFSET | UNCONDITIONAL_AMF;
        }
    }
    else
    {
        yop = is_mac_yop( dreg2 );
        if ( xop >= 0 && yop >= 0 )
        {
            return amf << AMF_OFFSET | xop << XOP_OFFSET |
                yop << YOP_OFFSET;
        }
        else
        {
            return amf << AMF_OFFSET | dreg1 << XREG_OFFSET |
                dreg2 << YREG_OFFSET | UNCONDITIONAL_AMF;
        }
    }
}

static unsigned long dm_direct( unsigned long opreg, expression_t *expression,
                         int dmwrite )
{
    unsigned long reg;
    unsigned long group;
    unsigned long retval;

    reg = REGISTER(opreg);
    group = REGISTER_GROUP(opreg);
    if ( group == 0 )
    {
        retval = 0x800000 | reg;
    }
    else if ( group <= 2 )
    {
        if ( reg >= 8 )
        {
            yyerror( "Register must be a DREG, IREG, or MREG" );
        }
        else
        {
            if ( group == 1 )
            {
                if ( reg >= 4 )
                    reg += 4;
            }
            else  /* group == 2 */
            {
                if ( reg < 4 )
                    reg += 4;
                else
                    reg += 8;
            }
        }
        retval = 0xa00000 | reg;
    }
    else
    {
        yyerror( "Invalid Register specified" );
        retval = 0;
    }
    if ( dmwrite )
    {
        retval |= 1 << 20;
    }
    if ( IS_CONSTANT(*expression) )
    {
        if ( expression->addend < -0x8000 || expression->addend > 0xffff )
        {
            yyerror( "Address is out of range" );
        }
        else
        {
            retval |= (expression->addend & 0xffff) << 4;
        }
    }
    else
    {
        symbol_add_relocation( expression->symbol, expression->addend,
                               (expression->type & SYMBOL_MASK) | R_ADSP219X_DM16 );
    }
    return retval;
}


static unsigned long indirect_rw(
   int write,
    unsigned long mem_type,
    unsigned long opreg,
    unsigned long indirect )
{
    unsigned long group;
    unsigned long reg;
    unsigned long retval;

    group = REGISTER_GROUP(opreg);
    reg = REGISTER(opreg);
    if ( group > 3 )
    {
        yyerror( "Illegal register in indirect memory operation" );
        group = 0;
    }
    retval = reg << INDIRECT_REG_OFFSET |
        group << INDIRECT_RGP_OFFSET |
        mem_type |
        indirect;
    if ( write )
    {
        retval |= 1 << DIRECTION_OFFSET;
    }
    return retval;
}

static unsigned long indirect_immod_rw(
    int write,
    unsigned long opreg,
    unsigned long indirect
)
{
    unsigned long retval;
    unsigned long reg;

    if ( REGISTER_GROUP(opreg) != 0 )
    {
        yyerror( "Only data registers are allowed in this operation" );
    }
    reg = REGISTER(opreg);
    retval =  (reg & 0x3) << 0 |
        (reg & 0xc) << 12 |
        indirect;
    if ( write )
    {
        retval |= 1 << DIRECTION_OFFSET;
    }
    return retval;
}


static unsigned long indirect( unsigned long ireg, unsigned long mreg,
                                int post_modify )
{
    unsigned long retval;

    if (I_DAG(ireg) != M_DAG(mreg))
        yyerror("Mismatched DAGs");
    retval = (I_DAG(ireg) << DAG_GROUP_OFFSET) |
        (I_REGISTER(ireg) << IREG_OFFSET) |
        (M_REGISTER(mreg) << MREG_OFFSET);
    if ( post_modify )
    {
        retval |= 1 << 14;
    }
    return retval;
}

static unsigned long indirect_immod(
    unsigned long ireg,
    expression_t *immediate,
    int post_modify )
{
    unsigned long retval;

    retval = (I_DAG(ireg) << DAG_GROUP_OFFSET) |
        (I_REGISTER(ireg) << IREG_OFFSET);
    if ( post_modify )
    {
        retval |= 1 << 16;
    }
    if ( IS_CONSTANT(*immediate) )
    {
        if ( immediate->addend < -128 || immediate->addend > 127 )
        {
            yyerror( "Immediate value is out of range" );
        }
        else
        {
            retval |= (immediate->addend & 0xff) << 4;
        }
    }
    else
    {
        symbol_add_relocation( immediate->symbol, immediate->addend,
                               (immediate->type & SYMBOL_MASK) |
                                   R_ADSP219X_MODIFY_IMMEDIATE );
    }
    return retval;
}

static unsigned long io_rw(
    int write,
    expression_t *expression,
    unsigned long opreg
)
{
    unsigned long retval;

    retval = 0x068000;
    if ( write )
        retval |= 1 << 12;
    if (REGISTER_GROUP(opreg) != 0)
    {
        yyerror("Illegal register specified");
        opreg = 0;
    }
    retval |= opreg;
    if ( IS_CONSTANT(*expression) )
    {
        if ( expression->addend < 0 || expression->addend > 1023 )
        {
            yyerror("Address is out of range");
        }
        else
        {
            retval |= ((expression->addend & 0xff) << 4) |
                ((expression->addend & 0x300) << 5);
        }
    }
    else
    {
        symbol_add_relocation( expression->symbol, expression->addend,
                               (expression->type & SYMBOL_MASK) | R_ADSP219X_IOADDR );
    }
    return retval;
}

static unsigned long system_reg(
    int write,
    int sys_reg,
    unsigned long opreg
)
{
    unsigned long retval;

    retval = 0x060000;
    if ( write )
        retval |= 1 << DIRECTION_OFFSET;
    if ( REGISTER_GROUP(opreg) != 0 )
    {
        yyerror( "Register must be a data register" );
        opreg = 0;
    }
    if ( sys_reg < 0 || sys_reg > 0xff )
    {
        yyerror( "Invalid system register" );
        sys_reg = 0;
    }
    return retval | sys_reg << 4 | opreg;
}

static unsigned long condition( unsigned long op, unsigned long condition )
{
    unsigned long retval;

    /* shift */
    if ( (op & 0xff0000) == 0x0e0000 )
    {
        retval = op | condition;
    }
    /* alu/mac */
    else if ( (op & 0xf80000) == 0x200000 )
    {
        retval = op;
        if ( (op & BO_MASK) == UNCONDITIONAL_AMF )
        {
            if ( condition != IF_TRUE )
            {
                yyerror( "This instruction cannot be conditional" );
            }
        }
        else
        {
            retval |= condition;
        }
    }
    /* rti/rts or indirect jump/call */
    else if ( (op & 0xfe0000) == 0x0a0000 )
    {
        retval = op | condition << 4;
    }
    /* direct jump/call */
    else if ( (op & 0xf80000) == 0x180000 )
    {
        if ( condition == IF_TRUE )
        {
            retval = op;
        }
        else
        {
            retval = op;
            if ( (op & (1 << 2)) )
            {
                yyerror( "Conditional direct call is not allowed. Use lcall" );
            }
            /* if offset is too large */
            else if ( (op & 0x020003) != 0x020003 && (op & 0x020003) != 0 )
            {
                yyerror( "Offset is too large for conditional instruction" );
            }
            else
            {
                /* clear bits 0..3, 17, 18 and move B to bit 17 while putting
                 * the condition in */
                retval = (op & 0xf9fff0) | (op & (1 << 3)) << 14 |
                    condition;
            }
        }
    }
    else
    {
        assert( FALSE );
    }
    return retval;
}

/* multifunction operations */
static unsigned long alu_mac_with_indirect_rw( unsigned long op,
                                               unsigned long indirect_rw )
{
    if ( (op & BO_MASK) != RESTRICTED_AMF )
    {
        yyerror( "The restricted form of the instruction must be used" );
    }
    if ( (indirect_rw & INDIRECT_RGP_MASK) != 0 )
        yyerror( "The register must be a data register (group 0)");
    if ( (indirect_rw & INDIRECT_U_MASK) == 0 )
        yyerror( "Indirect reference must be post modify with update" );
    return 0x600000 | (indirect_rw & 0xff) |
        (indirect_rw & (INDIRECT_G_MASK | INDIRECT_D_MASK)) << 7 |
        op;
}

static unsigned long shift_with_indirect_rw( unsigned long op,
                                             unsigned long indirect_rw )
{
    int xop;

    xop = is_shifter_xop((op >> 8) & 0xf);
    if ( xop < 0 )
    {
        yyerror( "The input register to the shifter is not valid" );
        xop = 0;
    }
    if ( (indirect_rw & INDIRECT_RGP_MASK) != 0 )
        yyerror( "The register must be a data register (group 0)");
    if ( (indirect_rw & INDIRECT_U_MASK) == 0 )
        yyerror( "Indirect reference must be post modify with update" );
    return 0x120000 | (indirect_rw & 0xff) |
        (indirect_rw & INDIRECT_G_MASK) << 3 |
        (indirect_rw & INDIRECT_D_MASK) >> 1 |
        xop << XOP_OFFSET |
        (op & (0xf << 12));
}

static unsigned long alu_mac_with_reg_move( unsigned long op, unsigned long reg )
{
    unsigned long code;

    if ( (op & BO_MASK) != RESTRICTED_AMF )
    {
        yyerror( "The restricted form of the instruction must be used" );
    }
    code = 0x280000 | op;
    if (REG_MOVE_GROUPS(reg) != 0)
        yyerror("Both registers of register move must be data registers" );
    else
    {
        code |= reg;
        alu_mac_clash( code );
    }
    return code;
}

static unsigned long shift_with_reg_move( unsigned long op, unsigned long reg )
{
    unsigned long code;

    code = 0x140000;
    if (REG_MOVE_GROUPS(reg) != 0)
        yyerror("Both registers of register move must be data registers" );
    else
    {
        code |= reg | op;
        shifter_clash( code );
    }
    return code;
}

static unsigned long memory_2reads( unsigned long indirect_rw1,
                                    unsigned long indirect_rw2 )
{
    unsigned long code;
    unsigned long dm;
    unsigned long pm;

    code = 0xc00000;
    if ( (indirect_rw1 & (1 << MS_OFFSET)) ==
         (indirect_rw2 & (1 << MS_OFFSET)) )
    {
        yyerror( "Both reads cannot be from the same memory space" );
        return code;
    }
    if ( (indirect_rw1 & (1 << MS_OFFSET)) )
    {
        pm = indirect_rw1;
        dm = indirect_rw2;
    }
    else
    {
        pm = indirect_rw2;
        dm = indirect_rw1;
    }
    if ( (pm & INDIRECT_D_MASK) != 0 || (dm & INDIRECT_D_MASK) != 0 )
    {
        yyerror( "Only memory read operations are permitted" );
    }
    code = 0xc00000 | (I_M(pm) << 4) | I_M(dm);
    if (INDIRECT_DAG(dm) != 0 || INDIRECT_DAG(pm) != 1)
        yyerror("DM must use DAG 1 and PM must use DAG 2");
    if ( (dm & INDIRECT_RGP_MASK) != 0 ||
         ((DREG(dm) & 0xc) != 0) )
        yyerror( "Data memory operation must use an ALU/MAC X register" );
    if ( (pm & INDIRECT_RGP_MASK) != 0 ||
         ((DREG(pm) & 0xc) != 4) )
        yyerror( "Program memory operation must use an ALU/MAC Y register" );
    return code | ((DREG(dm) & 0x3) << 18) | ((DREG(pm) & 0x3) << 20);
}

static unsigned long alu_mac_with_memory_2reads(
    unsigned long op,
    unsigned long indirect_rw1,
    unsigned long indirect_rw2
)
{
    if ( (op & BO_MASK) != RESTRICTED_AMF )
    {
        yyerror( "The restricted form of the ALU/MAC operation must be used" );
    }
    if ( op & Z_MASK )
    {
        yyerror( "The feedback register is not an allowed destination" );
        op &= ~Z_MASK;
    }
    return (op & (0x3ff << XOP_OFFSET)) |
        memory_2reads( indirect_rw1, indirect_rw2 );
}
