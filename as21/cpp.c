/*
 * cpp.c 
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

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "../defs.h"
#include "listing.h"
#include "symbol.h"
#include "as21-lex.h"
#include "pp-grammar.h"
#include "cpp.h"

#define MAX_INCLUDES           (16)
#define MIN_TEXT_SIZE          (2048)
#define MIN_ARGUMENT_SIZE      (32)

extern FILE *yyin;
extern int yylex(void);
extern int ppparse(void);

/* NOTE: yytext must only be refenced in cases where there is no lookahead
 *       ie after an explicit call to yylex. */
extern char *yytext;
extern int yyleng;

typedef enum
{
    NO_COMMENT,
    C_COMMENT,
    CPP_COMMENT
} COMMENT_STATE;

typedef struct condition_t
{
    struct condition_t *next;
    int inherited;
    int state;
    int elsed;
} condition_t;

typedef void *YY_BUFFER_STATE;

typedef struct file_t
{
    struct file_t *next;
    int line_number;
    int last_length;
    int column;
    int return_end;
    int continuation;
    COMMENT_STATE comment_state;
    FILE *infile;
    condition_t *first_condition;
    YY_BUFFER_STATE flex_buffer;
    char *alias;
    int delta_line;
    char name[0];
} file_t;

typedef struct macro_reference_t
{
    struct macro_reference_t *next;
    const macro_definition_t *definition;
    YY_BUFFER_STATE macro_buffer;
    char text[0];       /* must be last in structure */
} macro_reference_t;

typedef struct include_dir_t
{
    const char *dir;
    int length;
} include_dir_t;

static condition_t *condition_stack = NULL;
static file_t *file_stack = NULL, *first_file = NULL;
static int quote_char = '\0';
static int last_char = '\0';
static int include_depth = 0;
static int preprocess_include = FALSE;

static int macro_text_size = 1024;    /* initial size will be double this */
static char *macro_text = NULL;
static char *new_macro_text = NULL;
static char *end_macro_text;

static int offset_list_size = 32;     /* initial size will be double this */
static macro_offset_t *offset_list = NULL;
static macro_offset_t *new_offset = NULL;
static macro_offset_t *end_offset;

static macro_reference_t *macro_stack = NULL;
static include_dir_t include_dir_list[32];
static int include_dir_index;
static int max_include_dir_length;
static expand_t expansion = CPP_EXPAND_ALL;


/*
 * Manipulate the conditional assembly stack
 */
void cpp_push_condition( int condition )
{
    condition_t *push;

    push = (condition_t *)malloc(sizeof(condition_t)) ;
    if (push)
    {
        push->next = condition_stack;
        push->inherited = TRUE;
        if ( condition_stack )
        {
            push->inherited = condition_stack->state;
        }
        push->state = push->inherited && condition;
        push->elsed = FALSE;
        condition_stack = push;
        if ( file_stack->first_condition == NULL )
        {
            file_stack->first_condition = push;
        }
    }
    else
    {
        fprintf( stderr, "Failed to allocate condition stack element\n" );
        abort();
    }
}

void cpp_elif_condition( int condition )
{
    if ( condition_stack == NULL )
    {
        yyerror( "#elif found with no matching #if" );
        return;
    }
    if ( condition_stack->elsed )
    {
        yyerror( "Expected #endif but found #elif" );
        
    }
    if ( condition_stack->state )
    {
        condition_stack->inherited = FALSE;
    }
    condition_stack->state = condition_stack->inherited && condition;
}

void cpp_else_condition( void )
{
    if ( condition_stack == NULL )
    {
        yyerror( "#else found with no matching #if" );
        return;
    }
    if ( condition_stack->elsed )
    {
        yyerror( "Expected #endif but found #else" );
    }
    if ( condition_stack->state )
    {
        condition_stack->inherited = FALSE;
    }
    condition_stack->state = condition_stack->inherited;
    condition_stack->elsed = TRUE;
}

void cpp_pop_condition( void )
{
    condition_t *pop;

    pop = condition_stack;
    if (pop)
    {
        condition_stack = condition_stack->next;
        if ( file_stack->first_condition == pop )
        {
            file_stack->first_condition = NULL;
        }
        free( pop );
    }
    else
    {
        yyerror( "Unexpected #endif" );
    }
}

int cpp_assembly_on( void )
{
    return condition_stack == NULL || condition_stack->state;
}

/*
 * All of this is to remove line continuation and comments before lexing
 */
#define TEST_READ_BUF 0
int cpp_read_buf( char *buf, int max_size )
{
    register int ch, ch2;
    register int chars_read = 0;

    if (file_stack)
    {
#if TEST_READ_BUF
        printf( "\n\n<%s@%d %d %d<<",
		file_stack->name, file_stack->line_number,
		file_stack->comment_state,
		file_stack->continuation );
#endif
        if (file_stack->continuation)
        {
            cpp_line_add( 1 );
            file_stack->continuation = FALSE;
        }
        /* - 2 to leave room for testing comments and quotes */
        while (chars_read < max_size - 2)
        {
            ch = getc( yyin );
            if (ch == EOF)
            {
                break;
            }
            else if (ch == '\r')    /* strip carriage returns */
            {
                continue;
            }
            else
            {
                buf[chars_read] = ch;
                if (ch == '\n')
                {
                    quote_char = '\0';
                    if (file_stack->comment_state == CPP_COMMENT)
                    {
                        file_stack->comment_state = NO_COMMENT;
                        ++chars_read;
                    }
                    else if (file_stack->comment_state == C_COMMENT)
                    {
                        if (chars_read > 0)
                        {
                            ungetc(ch, yyin);
                            break;
                        }
                        else
                        {
                            cpp_line_add( 1 );
                        }
                    }
                    else
                    {
                        ++chars_read;
                    }
                }
                else if (ch == '\\')
                {
                    ch2 = getc( yyin );
                    while ( ch2 == '\r' )
                    {
                        ch2 = getc( yyin );
                    }
                    if (ch2 == '\n')
                    {
                        if (chars_read > 0)
                        {
                            file_stack->continuation = TRUE;
                            break;
                        }
                        else
                        {
                            cpp_line_add( 1 );
                        }
                    }
                    else
                    {
                        ungetc( ch2, yyin );
                        if (file_stack->comment_state == NO_COMMENT)
                        {
                            ++chars_read;
                        }
                    }
                }
                else if (file_stack->comment_state == NO_COMMENT)
                {
                    switch (ch)
                    {
                        case '\"':
                        case '\'':
                            if (quote_char)
                            {
                                if (last_char != '\\' && quote_char == ch)
                                {
                                    quote_char = '\0';
                                }
                            }
                            else
                            {
                                quote_char = ch;
                            }
                            ++chars_read;
                            break;
                        case '/':
                            if (quote_char == '\0')
                            {
                                ch2 = getc( yyin );
                                if (ch2 == '*')
                                {
                                    file_stack->comment_state = C_COMMENT;
                                }
                                else if (ch2 == '/')
                                {
                                    file_stack->comment_state = CPP_COMMENT;
                                }
                                else
                                {
                                    ungetc( ch2, yyin );
                                    ++chars_read;
                                }
                            }
                            break;
                        default:
                            ++chars_read;
                            break;
                    }
                }
                else if (file_stack->comment_state == C_COMMENT && ch == '*')
                {
                    ch2 = getc( yyin );
                    if (ch2 == '/')
                    {
                        file_stack->comment_state = NO_COMMENT;
                    }
                    else
                    {
                        ungetc( ch2, yyin );
                    }
                }
                if ( chars_read )
                {
                    last_char = buf[chars_read-1];
                }
            }
        }
    }
#if TEST_READ_BUF
    if ( file_stack )
    {
        int i;
        char *bufp;

        bufp = buf;
        for ( i = 0 ; i < chars_read ; ++i )
        {
        putchar( *bufp++ );
    }
        printf( ">%s@%d %d %d %d>>\n\n",
            file_stack->name, file_stack->line_number,
            chars_read,
            file_stack->comment_state,
            file_stack->continuation );
    }
    else
    {
        printf( "\n\n<<<>>>\n\n" );
    }
#endif
    return chars_read;
}
#undef TEST_READ_BUF

/*
 * returns != 0 if the file was successfully pushed
 * return_end is TRUE if yywrap should indicate no more files even if there
 *            are more files after popping this one.
 */
int cpp_push_file( const char *name, int return_end )
{
    file_t *push;
    FILE *next_file;
    static const char cmd_line_text[] = "command line";

    quote_char = '\0';
    last_char = '\0';
    if ( include_depth >= MAX_INCLUDES )
    {
        yyerror( "Maximum include depth exceeded" );
        return 0;
    }
    if ( name != NULL )
    {
        next_file = fopen(name, "r");
    }
    else
    {
        name = cmd_line_text;
        next_file = NULL;
    }
    if ( name == cmd_line_text || next_file != 0 )
    {
        push = (file_t *)malloc(sizeof(file_t) +
                                strlen(name) + 1);
        if (push)
        {
            ++include_depth;
            push->next = file_stack;
            push->line_number = 1;
            push->column = 1;
            push->last_length = 0;
            push->return_end = return_end;
            push->continuation = FALSE;
            push->comment_state = NO_COMMENT;
            push->infile = next_file;
            push->first_condition = NULL;
            push->alias = NULL;
            push->delta_line = 0;
            strcpy( push->name, name );
            if ( file_stack == NULL )
            {
                first_file = push;
            }
            file_stack = push;
            if ( next_file )
            {
                file_stack->flex_buffer =
                    lex_scan_file( file_stack->infile );
            }
            else
            {
                file_stack->flex_buffer =
                    lex_scan_string( macro_text );
            }
            return 1;
        }
        fclose(next_file);
    }
    else
    {
        fprintf( stderr, "File not found\n" );
    }
    return 0;
}

/*
 * pop the next file off the stack
 */
void cpp_pop_file(void)
{
    file_t *pop;

    if ( quote_char )
    {
        yyerror( "Open quote at end of file" );
        quote_char = '\0';
    }
    last_char = '\0';
    lex_state( LEX_INITIAL );

    pop = file_stack;
    if (pop)
    {
        if ( pop->continuation )
        {
            yyerror( "Continuation at end of file" );
        }
        if ( pop->comment_state == C_COMMENT )
        {
            yyerror( "Open comment at end of file" );
        }
        /* clean up any pending preprocessor conditions */
        if ( pop->first_condition )
        {
            yyerror( "Expecting #endif but found end of file" );
            while ( pop->first_condition )
            {
                cpp_pop_condition();
            }
        }
        file_stack = file_stack->next;
        if ( file_stack == NULL )
        {
            first_file = NULL;
        }
        if ( pop->infile )
        {
            fclose(pop->infile);
        }
        if ( pop->alias )
            free( pop->alias );
        lex_delete_buffer( pop->flex_buffer );
        --include_depth;
        if ( file_stack == NULL )
        {
            assert( include_depth == 0 );
        }
        else
        {
            lex_use_buffer( file_stack->flex_buffer );
        }
        free( pop );
    }
}

void cpp_line_add( int count )
{
    file_stack->line_number += count;
    file_stack->column = 1;
    file_stack->last_length = 0;
}

/*
 * Returns the true line number of the file, not the one which
 * may have been modified by a #line directive
 */
int cpp_current_line( void )
{
    if ( first_file )
    {
        return first_file->line_number;
    }
    return 0;
}

/*
 * Returns the file name and line number used of error purposes etc.
 * May have been modified by #line
 */
int cpp_current_location( const char **file_name, int *line, int *column )
{
    if (file_stack)
    {
        if (file_name)
        {
            *file_name = file_stack->alias ? file_stack->alias :
                file_stack->name;
        }
        if (line)
        {
            *line = file_stack->line_number + file_stack->delta_line;
        }
        if (column)
        {
            *column = file_stack->column;
        }
        return TRUE;
    }
    return FALSE;
}

void cpp_change_location( int line, const char *file_name )
{
    int compare;

    if ( file_name )
    {
        compare = strcmp( file_stack->name, file_name );
    }
    else
    {
        compare = 0;  /* force equal to real file name */
    }
    if(  file_stack->alias &&
         ( compare == 0 ||
           strcmp( file_name, file_stack->alias ) != 0 ) )
    {
        free( file_stack->alias );
        file_stack->alias = NULL;
    }
    if ( compare != 0 )
    {
        file_stack->alias = strdup( file_name );
    }
    if ( line <= 0 )
    {
        file_stack->delta_line = 0;
    }
    else
    {
        file_stack->delta_line = line - file_stack->line_number - 1;
    }
}

void cpp_add_column( int last_length )
{
    if ( file_stack )
    {
        file_stack->column += file_stack->last_length;
        file_stack->last_length = last_length;
    }
}

void cpp_init_collection(void)
{
    new_macro_text = macro_text;
    new_offset = offset_list;
}

/* makes room for length amount of text plus a trailing '\0' */
static void make_macro_room( int length )
{
    int current_size;

    ++length;
    if (macro_text == NULL ||
        ((end_macro_text - new_macro_text) < length + 1) )
    {
        while( length >= macro_text_size - (end_macro_text - new_macro_text) )
        {
            macro_text_size *= 2;
        }
        current_size = new_macro_text - macro_text;
        macro_text = realloc( macro_text, macro_text_size );
        if ( macro_text == NULL )
        {
            yyerror( "Failed to reallocate macro area" );
            abort();
        }

        new_macro_text = macro_text + current_size;
        end_macro_text = macro_text + macro_text_size;
    }
}

static void collect_text( const char *text, int length )
{
	assert( length >= 0 );
    make_macro_room( length );
    /* join adjacent strings */
    if ( new_macro_text != macro_text &&
         *(new_macro_text - 1) == '\"' &&
         text[0] == '\"' )
    {
        memmove( new_macro_text - 1, text + 1, length );
        new_macro_text += length - 2;
    }
    /* else handle regular tokens */
    else
    {
        memmove( new_macro_text, text, length );
        new_macro_text += length;
    }
    /* make sure the string is terminated */
    *new_macro_text = '\0';
}

static void collect_offset( int type )
{
    int current_size;

    if (offset_list == NULL ||
        new_offset == end_offset )
    {
        offset_list_size *= 2;
        current_size = new_offset - offset_list;
        offset_list = realloc( offset_list,
                                  offset_list_size * sizeof(*offset_list));
        if ( offset_list == NULL )
        {
            fprintf( stderr, "Failed to reallocate offset list\n" );
            abort();
        }
        new_offset = offset_list + current_size;
        end_offset = offset_list + offset_list_size;
    }
    new_offset->offset = new_macro_text - macro_text;
    new_offset->type = type;
    ++new_offset;
}

void cpp_collect_token( const char *text, int length )
{
    collect_offset( new_offset - offset_list );
    collect_text( text, length + 1 );
}

char *cpp_collect_tokens( int *length )
{
    int token;
    char *start;

    expansion = CPP_EXPAND_NONE;
    collect_offset( new_offset - offset_list );
    start = new_macro_text;
    while ( (token = yylex()) && token != '\n' )
    {
        /* collect without trailing '\0' */
        collect_text( yytext, yyleng );
    }
    if ( new_macro_text == start )
    {
        collect_text( "", 1 );
    }
    if ( length )
    {
        *length = new_macro_text - macro_text + 1;
    }
    expansion = CPP_EXPAND_ALL;
    return macro_text;
}

/*
 * NOTE: init_collection() should have been called before collecting
 *       the parameters for this macro
 */
void cpp_collect_macro(void)
{
    int token, last_token;
    int parameter_count;
    int parameter;
    int i;
    int collect;
    int macro_start;
    int total_offsets;
    int total_text;
    int collected_offsets;

    lex_state( LEX_PREPROC_TEXT );
    macro_start = new_macro_text - macro_text;
    parameter_count = new_offset - offset_list;
    /* we'd better have collected the name */
    assert( parameter_count > 0 );
    last_token = 0;
    while ( (token = yylex()) && token != '\n' )
    {
        collect = TRUE;
        parameter = FALSE;
        switch (token)
        {
            case NAME:
                /* look for a matching parameter */
                for ( i = 1 ;
                      i < parameter_count &&
                          strcmp( yytext, macro_text +
                                  offset_list[i].offset ) != 0 ;
                      ++i )
                {
                }
                if ( i < parameter_count )
                {
                    collect = FALSE;
                    collect_offset( i - 1 );
                    parameter = TRUE;
                }
                break;
            case PPMACRO_LABEL:
                /* collect without trailing '?' and '\0' */
                collect_text( yytext, yyleng - 1 );
                collect_offset( MACRO_LABEL );
                collect = FALSE;
                break;
            case PPCONCAT:
                if ( last_token == 0 )
                {
                    yyerror( "'##' cannot appear at the beginning of a macro" );
                }
                collect = FALSE;
                break;
            case PPSTRINGIZE:
                collect_offset( MACRO_STRINGIZE );
                collect = FALSE;
                break;
            default:
                break;
        }
        if ( last_token == '#' && !parameter )
        {
            yyerror( "'#' is not followed by a macro parameter" );
            --new_offset; /* discard it's effect */
        }
        if ( collect )
        {
            collect_text( yytext, yyleng );
        }
        last_token = token;
    }
    if ( last_token == PPCONCAT )
    {
        yyerror( "'##' cannot appear at the end of a macro" );
    }
    total_text = new_macro_text - macro_text;
    total_offsets = new_offset - offset_list;
    collected_offsets = total_offsets - parameter_count;
    /* trim leading and trailing space */
    if ( macro_text[macro_start] == ' ' )
    {
        if ( collected_offsets == 0 ||
             offset_list[parameter_count].offset > macro_start )
        {
            ++macro_start;
        }
    }
    if ( total_text - macro_start > 0 && new_macro_text[-1] == ' ' )
    {
        if ( collected_offsets == 0 ||
             offset_list[total_offsets - 1].offset < total_text - macro_start )
        {
            --total_text;
            --new_macro_text;
        }
    }
    collect_offset( MACRO_END );
    ++total_offsets;
    /* adjust offsets to the start of the macro text */
    for ( i = parameter_count ; i < total_offsets ; ++i )
    {
        offset_list[i].offset -= macro_start;
    }
    define_macro( macro_text,
                  parameter_count - 1,
                  offset_list + parameter_count,
                  total_offsets - parameter_count,
                  macro_text + macro_start,
                  total_text - macro_start );
}

static int collect_one_argument()
{
    int nesting_index;
    int token;
    int done;

    nesting_index = 0;
    done = FALSE;
    collect_offset( new_offset - offset_list );
    while ( !done )
    {
        token = yylex();
        switch (token)
        {
            case '(':
                ++nesting_index;
                break;
            case ')':
                if ( nesting_index == 0 )
                {
                    done = TRUE;
                }
                else
                {
                    --nesting_index;
                }
                break;
            case ',':
                if ( nesting_index == 0 )
                {
                    done = TRUE;
                }
                break;
            case 0:
                yyerror( "Unexpected end of file in macro" );
                return 0;
            default:
                break;
        }
        if ( !done )
        {
            collect_text( yytext, yyleng );
        }
        else if ( token == ')' || token == ',' )
        {
            collect_text( "", 1 );
        }
    }
    
    return token;
}

static int collect_arguments( void )
{
    int token;
    int arg_count;

    expansion = CPP_EXPAND_NONE;
    arg_count = 0;
    token = yylex();
    if ( token == '(' )
    {
        lex_state( LEX_MACRO_ARG_LIST );
        while ( (token = collect_one_argument()) && token == ',' )
        {
        }
        if ( token == ')' )
        {
            arg_count = new_offset - offset_list;
        }
        else
        {
            arg_count = -1;
        }
        lex_state( LEX_INITIAL );
    }
    expansion = CPP_EXPAND_ALL;
    return arg_count;
}

#define TEST_BUILD_MACRO 0
static macro_reference_t *build_macro(
    const macro_definition_t *definition
)
{
    const macro_offset_t *def_offset, *arg_offset;
    macro_reference_t *push;
    int i, j;
    int start, next_start;
    int length;
    int first_offset;
    const char *value;
    char *text;
    char number[12];
    int arg_start;
    int arg_length;

    start = next_start = 0;
    value = definition->value;
    collect_offset( 0 );  /* offset of start of built macro */
    first_offset = new_offset - offset_list;
    def_offset = definition->offsets;
    for ( i = 0 ; i < definition->offset_count ; ++i )
    {
        next_start = def_offset->offset;
        collect_text( value + start, next_start - start );
        if ( def_offset->type >= 0 )
        {
            arg_offset = offset_list + def_offset->type;
            collect_text( macro_text + arg_offset->offset,
                          (arg_offset + 1)->offset -
                          arg_offset->offset - 1 );
        }
        else
        {
            switch( def_offset->type )
            {
                case MACRO_STRINGIZE:
                    assert( def_offset->offset == (def_offset+1)->offset );
                    ++def_offset;
                    ++i;
                    assert( def_offset->type >= 0 );
                    arg_start = offset_list[def_offset->type].offset;
                    arg_length = offset_list[def_offset->type + 1].offset -
                        arg_start;
                    /* make room to escape every character and add 2 quotes */
                    make_macro_room( 2 * arg_length + 2 );
                    text = macro_text + arg_start;
                    *new_macro_text++ = '\'';
                    for ( j = 0 ; j < arg_length - 1 ; ++j )
                    {
                        if ( *text == '\'' || *text == '\\' )
                        {
                            *new_macro_text++ = '\\';
                        }
                        *new_macro_text++ = *text++;
                    }
                    *new_macro_text++ = '\'';
                    *new_macro_text = '\0';
                    break;
                case MACRO_LABEL:
                    sprintf( number, "_%02d", definition->reference_count );
                    collect_text( number, strlen(number) );
                    break;
                case MACRO_END:
                    break;
                default:
                    fprintf( stderr, "Unexpected offset type %d\n",
                             def_offset->type );
                    abort();
                    break;
            }
        }
        start = next_start;
        ++def_offset;
    }
    collect_text( "\0", 2 );  /* 2 end of buffer chars */
    start = offset_list[definition->parameter_count].offset;
    length = new_macro_text - macro_text - start;
    push = (macro_reference_t *)malloc( sizeof(*push) + length );
    if ( push )
    {
        memmove( push->text, macro_text + start, length );
        push->definition = definition;
        push->macro_buffer = lex_scan_buffer( push->text, length );
#if TEST_BUILD_MACRO
        {
            printf( "\n\n\n");
            printf( "Built Macro %p %d\n", push->macro_buffer, length );
            for ( i = 0 ; i < length ; ++i )
            {
                printf( " %02x", push->text[i] );
                if ( (i & 0xf) == 0xf || 
                     i == length - 1 )
                {
                    printf( "\n" );
                }
            }
            printf( "%s\n", push->text );
            printf( "\n\n\n");
        }
#endif
    }
    else
    {
        fprintf( stderr, 
                 "Failed to allocate memory for macro reference\n" );
        abort();
    }
    return push;
}
#undef TEST_BUILD_MACRO

int cpp_push_macro( const char *name )
{
    const macro_definition_t *definition;
    macro_reference_t *push;
    int arg_count;
    char macro_text[12];
    const char *file_name;
    int line_number;
    int length;
    static macro_offset_t predefined_offset =
    {
        MACRO_END, 0
    };
    static macro_definition_t predefine =
    {
        NULL,
        0, 0, 1,
        &predefined_offset
    };

    if ( expansion != CPP_EXPAND_ALL )
    {
        if ( expansion == CPP_EXPAND_NEXT_OFF )
            expansion = CPP_EXPAND_ALL;
        return FALSE;
    }
    if ( strcmp( name, "__LINE__" ) == 0 )
    {
        cpp_current_location( &file_name, &line_number, NULL );
        definition = &predefine;
        predefine.value = macro_text;
        sprintf( macro_text, "%d", line_number );
        predefined_offset.offset = strlen( macro_text );
    }
    else if ( strcmp( name, "__FILE__" ) == 0 )
    {
        cpp_current_location( &file_name, &line_number, NULL );
        definition = &predefine;
        length = strlen( file_name );
        predefine.value =
            (char *)malloc( length + 3 );
        if ( predefine.value == NULL )
        {
            yyerror( "Memory allocation error" );
            return TRUE;
        }
        sprintf( (char *)predefine.value,
                 "'%s'", file_name );
        predefined_offset.offset = length + 2;
    }
    else
    {
        definition = find_macro( name );
    }
    if ( definition )
    {
        push = macro_stack;
        while ( push )
        { 
            /* already expanding this macro */
            if ( definition == push->definition ) 
            {
                assert( definition != &predefine );
                return FALSE;
            }
            push = push->next;
        }
        arg_count = 0;
        cpp_init_collection();
        if ( definition->parameter_count > 0 )
        {
            arg_count = collect_arguments();
        }
        if ( arg_count == definition->parameter_count )
        {
            push = build_macro( definition );
            push->next = macro_stack;
            macro_stack = push;
        }
        else
        {
            yyerror( "Wrong number of parameters provided for macro" );
        }
    }
    if ( predefine.value )
    {
        if ( predefine.value != macro_text )
        {
            free( (char *)predefine.value );
        }
        predefine.value = NULL;
    }
    return definition && arg_count >= 0;
}

void cpp_pop_macro( void )
{
    macro_reference_t *pop;

    if ( macro_stack )
    {
        pop = macro_stack;
        macro_stack = macro_stack->next;
        lex_delete_buffer( pop->macro_buffer );
        free( pop );
        if ( macro_stack )
        {
            lex_use_buffer( macro_stack->macro_buffer );
        }
        else
        {
            lex_use_buffer( file_stack->flex_buffer );
        }
    }
}

int cpp_cmd_line_macro( char *text )
{
    static const char define_text[] = "define";
    int length;
    char *equals;

    length = strlen(text);
    /* build a define statement to parse */
    /* include space for \n, 2 \0s and a possible " 1" */
    make_macro_room( sizeof(define_text) + length + 5 );
    strcpy( macro_text, define_text );
    macro_text[sizeof(define_text)-1] = ' ';
    memmove( macro_text + sizeof(define_text), text, length );
    length += sizeof(define_text);
    macro_text[length] = '\0';
    equals = strchr( macro_text + sizeof(define_text), '=' );
    if ( equals )
    {
        *equals = ' ';
    }
    else
    {
        macro_text[length] = ' ';
        ++length;
        macro_text[length] = '1';
        ++length;
    }
    macro_text[length] = '\n';
    ++length;
    macro_text[length] = '\0';
    ++length;

    if ( cpp_push_file( NULL, 1 ) )
    {
        assert( macro_stack == NULL );
        cpp_preprocess();
        cpp_pop_file();
        return error_count == 0;
    }
    return 0;
}

void cpp_queue_include_dir( const char *dir_name )
{
    include_dir_t *dir;

    if ( include_dir_index > sizearray(include_dir_list) )
    {
        fprintf( stderr, "Too many include directories: %s\n",
                 dir_name );
    }
    else
    {
        dir = include_dir_list + include_dir_index;
        dir->dir = dir_name;
        dir->length = strlen( dir_name );
        if ( dir_name[dir->length - 1] != '/' )
        {
            /* include space for a '/' */
            ++dir->length;
        }
        ++include_dir_index;
        if ( dir->length > max_include_dir_length )
        {
            max_include_dir_length = dir->length;
        }
    }
}

void cpp_push_include_file( const char *include_name, int local )
{
    int length = strlen( include_name );
    int i;
    include_dir_t *dir;
    const char *path;
    const char *name;
    FILE *file;

    if ( local && (file = fopen( include_name, "r" )) != NULL )
    {
        path = include_name;
        name = include_name;
        fclose( file );
    }
    else
    {
        make_macro_room( length+max_include_dir_length );
        memmove( macro_text + max_include_dir_length, include_name, length + 1 );
        dir = include_dir_list;
        name = macro_text + max_include_dir_length;
        for ( i = 0 ; i < include_dir_index ; ++i )
        {
            path = macro_text + max_include_dir_length - dir->length;
            memmove( (char *)path, dir->dir, dir->length );
            macro_text[max_include_dir_length-1] = '/';
            if ( (file = fopen( path, "r" )) != NULL )
            {
                fclose( file );
                break;
            }
            ++dir;
        }
        if ( i >= include_dir_index )
        {
            path = NULL;
        }
    }
    if ( path )
    {
        cpp_push_file( path, FALSE );
        preprocess_include = TRUE;
    }
    else
    {
        yyerror( "Include file not found: %s", name );
    }
}

void cpp_init_pass( void )
{
    include_dir_index = 0;
    max_include_dir_length = 0;
}

void cpp_terminate(void)
{
    if (macro_text != NULL)
    {
        free( macro_text );
    }
    if (offset_list != NULL)
    {
        free( offset_list );
    }
}

/*
 * Like yywrap
 */
int cpp_wrap()
{
    int return_end;

    if ( macro_stack )
    {
        cpp_pop_macro();
        return 0;
    }
    /* keep one flex buffer on the stack */
    if ( file_stack && file_stack->next )
    {
        return_end = file_stack->return_end;
        cpp_pop_file();
        return return_end;
    }
    return 1;
}

void cpp_expand( expand_t expand )
{
    expansion = expand;
}


#define TEST_PREPROCESS 0
int cpp_preprocess( void )
{
    static int recurse = FALSE;

    if ( macro_stack == NULL )
    {



#if TEST_PREPROCESS
        printf( "Start ppparse() %s-%d\n",
                file_stack->name, file_stack->line_number );
#endif
        lex_state( LEX_PREPROC_DIRECTIVE );
        assert( recurse == FALSE );
        recurse = TRUE;
        ppparse();
        recurse = FALSE;
        expansion = CPP_EXPAND_ALL;
        if ( preprocess_include )
        {
            ++file_stack->next->line_number;
            file_stack->next->column = 1;
            file_stack->next->last_length = 0;
            preprocess_include = FALSE;
        }
        else
        {
            ++file_stack->line_number;
            file_stack->column = 1;
            file_stack->last_length = 0;
        }
#if TEST_PREPROCESS
        printf( "End ppparse() %s-%d\n",
                file_stack->name, file_stack->line_number );
#endif
        if ( !cpp_assembly_on() )
        {
            lex_state( LEX_GOBBLE );
        }
        return TRUE;
    }
    return FALSE;
}
#undef TEST_PREPROCESS
