/*
 * ez21.c 
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
#include <unistd.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <termios.h>
#include <assert.h>
#include <ctype.h>
#include <elf.h>
#include <libelf.h>

#include "defs.h"
#include "adielf.h"

static char version[] = "Open21xx EZ-Kit Loader Version " VERSION_NUMBER;

static int ttyfd;
static int dump_comms = FALSE;
static unsigned char buffer[3*0x4001];
static int force = FALSE;
static int waitstates = 7;
static int sport2_spi_mode = 0;
static int clockdiv = 5;
static int buswidth = 0;
static int epromwidth = 0;
static char *ackstring = NULL;
enum
{
    data_word_size = 2, program_word_size = 3,
    program_top = 0x37ff, data_top = 0x3dff
};
/*
 * progress is the number of characters of characters to receive
 * or transmit before indicating progress. About 1 seconds worth
 * at the given baud rate.
 */
#define PROGRESS_2400       0x100
#define PROGRESS_4800       (2*PROGRESS_2400)
#define PROGRESS_9600       (2*PROGRESS_4800)
#define PROGRESS_19200      (2*PROGRESS_9600)
#define PROGRESS_38400      (2*PROGRESS_19200)

static int progress_block;
static int progress = FALSE;
static int forcefirstbyte = FALSE;

void dump( const unsigned char *buffer, int count )
{
    const unsigned char *hex, *chr;
    int i, j, length;

    hex = chr = buffer;
    for ( i = 0 ; i < count ; count -= 16 )
    {
        length = count;
        if ( length > 16 )
            length = 16;
        for ( j = 0 ; j < length ; ++j )
        {
            printf( "%02x ", *hex++ );
        }
        for ( ; j < 16 ; ++j )
        {
            printf( "   " );
        }
        printf( "   " );
        for ( j = 0 ; j < length ; ++j )
        {
            printf( "%c", isprint( *chr ) ? *chr : '.' );
            ++chr;
        }
        printf( "\n" );
    }
}

static Elf32_Half download_machine( const char *filename )
{
    Elf *elf;
    Elf32_Ehdr *ehdr;
    int fd;
    Elf32_Half machine = 0;
    
    if ((fd = open(filename, O_RDONLY | O_BINARY)) != -1)
    {
        if (elf_version(EV_CURRENT) != EV_NONE)
        {
            elf = elf_begin(fd, ELF_C_READ, NULL);
            if (elf)
            {
                ehdr = elf32_getehdr( elf );
                if (ehdr )
                {
                    machine = ehdr->e_machine;
                }
                else
                {
                    fprintf( stderr,
                             "Failed to get ELF header: %s\n",
                             elf_errmsg(-1) );
                }
                elf_end(elf);
            }
            else
            {
                fprintf( stderr, "download_machine: elf_begin - %s\n",
                         elf_errmsg(-1) );
            }
        }
        else
        {
            fprintf(stderr, "Elf library is out of date\n" );
        }
        if (close( fd ) != 0)
            perror("Error closing executable");
    }
    else
    {
        perror("Error opening executable" );
    }
    return machine;
}

unsigned long data_word( unsigned char *data )
{
    return ((unsigned long)*data << 8) | ((unsigned long)*(data+1));
}

unsigned long program_word( unsigned char *data )
{
    return ((unsigned long)*data << 16) |
        ((unsigned long)*(data+1) << 8) |
        ((unsigned long)*(data+2));
}

unsigned long check_sum( unsigned char *data, int length, int by_bytes )
{
    unsigned long sum, value;
    int i, j;

    assert( (length % by_bytes) == 0 );
    sum = 0;
    for ( i = 0 ; i < length ; i += by_bytes )
    {
        value = 0;
        for ( j = 0 ; j < by_bytes ; ++j )
        {
            value = (value << 8) | *data++;
        }
        sum += value;
    }
    return sum & ((1 << (by_bytes * 8)) - 1);
}

int received( int expected )
{
    int result, i;
    int block;
    int so_far;

    assert( expected <= sizeof(buffer) );
    assert( expected > 0 );
    so_far = 0;
    for ( result = 1, i = 0 ; result > 0 && i < expected ; )
    {
        if ( expected - i > progress_block - so_far )
        {
            block = progress_block - so_far;
        }
        else
        {
            block = expected - i;
        }
        result = read( ttyfd, buffer + i, block );
        if (result >= 0)
            i += result;
        else
            perror( "Error reading from port" );
        if ( progress )
        {
            so_far += result;
            if ( so_far >= progress_block )
            {
                printf( "." );
                fflush( stdout );
                so_far = 0;
            }
        }
    }
    if (dump_comms)
    {
        if (progress)
        {
            printf( "\n" );
        }
        printf( "Received:\n" );
        dump( buffer, i );
    }
    return i;
}

void write_drain( int fd, const unsigned char *data, unsigned long length )
{
    int i, result, block;

    if ( length == 0 )
    {
        return;
    }
    tcflush( fd, TCIFLUSH );
    for ( result = 1, i = 0 ; result > 0 && i < length ; )
    {
        if ( (length - i) > progress_block )
        {
            block = progress_block;
        }
        else
        {
            block = length - i;
        }
        result = write( fd, data + i, block );
        tcdrain( fd );
        if ( result >= 0 )
        {
            i += result;
        }
        else
        {
            perror( "Error writing to port\n" );
        }
        if ( progress )
        {
            printf( "." );
            fflush( stdout );
        }
    }
    if (dump_comms)
    {
        if ( progress )
        {
            printf( "\n" );
        }
        printf( "Sent:\n" );
        dump( data, length );
    }
}

int beep( void )
{
    static const unsigned char beep_string[] = "$$$";
    int count;

    write_drain( ttyfd, beep_string, sizeof(beep_string) - 1 );
    count = received( 6 );
    if ( count < 2 || buffer[0] != 'o' || buffer[1] != 'k')
    {
        count = 0;
    }
    return count;
}

int alive( void )
{
    static const unsigned char alive_string[] = "$OK";
    int count;

    write_drain( ttyfd, alive_string, sizeof(alive_string) - 1 );
    count = received( 6 );
    if ( count < 2 || buffer[0] != 'o' || buffer[1] != 'k')
    {
        count = 0;
    }
    return count;
}

int upload_data( unsigned int start, unsigned int length )
{
    static unsigned char upload_data_string[] = "$UD    ";
    int count;
    unsigned long check;

    if (length * 2 > sizeof(buffer))
        return 0;
    upload_data_string[3] = start >> 8;
    upload_data_string[4] = start;
    upload_data_string[5] = length >> 8;
    upload_data_string[6] = length;
    write_drain( ttyfd, upload_data_string, sizeof(upload_data_string) - 1 );
    /* bytes received not counting the checksum */
    count = received( 2 + length * 2 ) - 2;
    if ( count > 0 )
    {
        check = check_sum( buffer, count, 2 );
        if (check != data_word( buffer + count ))
        {
            fprintf( stderr, "Bad data check sum: %x/%x\n",
                     data_word( buffer + count ), check );
            count = 0;
        }
    }
    else
    {
        count = 0;
    }
    return count;
}

int upload_program( unsigned int start, unsigned int length )
{
    static unsigned char upload_program_string[] = "$UP    ";
    int count;
    unsigned long check;

    if (length * 3 > sizeof(buffer))
        return 0;
    upload_program_string[3] = start >> 8;
    upload_program_string[4] = start;
    upload_program_string[5] = length >> 8;
    upload_program_string[6] = length;
    write_drain( ttyfd, upload_program_string, sizeof(upload_program_string) - 1 );
    /* bytes received not counting check sum */
    count = received( 3 + 3 * length ) - 3;
    if ( count > 0 )
    {
        check = check_sum( buffer, count, 3 );
        if (check != program_word( buffer + count ))
        {
            fprintf( stderr, "Bad data check sum: %x/%x\n",
                     program_word( buffer + count ), check );
            count = 0;
        }
    }
    else
    {
        count = 0;
    }
    return count;
}

int download_data( void *datap, unsigned long start, unsigned long length )
{
    static unsigned char download_data_string[] = "$DD    ";
    unsigned long check;
    unsigned long word_length = length / data_word_size;

    if ( length > 0 )
    {
        download_data_string[3] = start >> 8;
        download_data_string[4] = start;
        download_data_string[5] = word_length >> 8;
        download_data_string[6] = word_length;
        check = check_sum( datap, length, data_word_size );
        write_drain( ttyfd, download_data_string,
                     sizeof(download_data_string) - 1 );
        write_drain( ttyfd, datap, length );
        if (received( 2 ) != data_word_size && check != data_word( buffer ))
        {
            fprintf( stderr, "Data download error: %x/%x\n",
                     check, data_word( buffer ) );
            length = 0;
        }
    }
    return length;
}

int download_program( void *datap, unsigned long start, unsigned long length )
{
    static unsigned char download_program_string[] = "$DP    ";
    unsigned long check;
    enum { program_word_size = 3 };
    unsigned long word_length = length / program_word_size;

    if ( length > 0 )
    {
        download_program_string[3] = start >> 8;
        download_program_string[4] = start;
        download_program_string[5] = word_length >> 8;
        download_program_string[6] = word_length;
        check = check_sum( datap, length, program_word_size );
        write_drain( ttyfd, download_program_string,
                     sizeof(download_program_string) - 1 );
        write_drain( ttyfd, datap, length );
        if (received( 3 ) != program_word_size && check != program_word( buffer ))
        {
            fprintf( stderr, "Program download error: %x/%x\n",
                     check, program_word( buffer ) );
            length = 0;
        }
    }
    return length;
}

int go( unsigned int start )
{
    static unsigned char go_string[] = "$GO  ";

    go_string[3] = start >> 8;
    go_string[4] = start;
    write_drain( ttyfd, go_string, sizeof(go_string) - 1 );
    return received( 2 );
}

int send_219x_block( int fd, Elf32_Phdr *phdr, int final )
{
    int failed;
    int words;
    int word_size;
    int type;
    enum BOOT_FLAGS
    {
        /* Bit map of boot flags
         * Zero | Final | DM */
        PM_24,
        DM_16,
        PM_FINAL_24,
        DM_FINAL_16,
        PM_24_ZEROED,
        DM_16_ZEROED,
        PM_FINAL_24_ZEROED,
        DM_FINAL_16_ZEROED,
    };
    int flag;
    int zeroed;
    unsigned char *bufp;
    unsigned char *endp;
    unsigned char swap;
    off_t offset;
    int total;
    int max_bytes;
    ssize_t bytes_read;
    int to_read;
    
    if ( phdr->p_flags & PF_X )
    {
        word_size = program_word_size;
        flag = 0;
    }
    else
    {
        word_size = data_word_size;
        flag = 1;
    }
    if ( final )
    {
        flag |= 0x2;
    }
    if ( phdr->p_filesz == 0 )
    {
        flag |= 0x4;
    }
    words = phdr->p_memsz / word_size;
    bufp = buffer;
    *bufp++ = (unsigned char)flag;
    *bufp++ = (unsigned char)(flag >> 8);
    *bufp++ = (unsigned char)phdr->p_vaddr;
    *bufp++ = (unsigned char)(phdr->p_vaddr >> 8);
    *bufp++ = (unsigned char)(phdr->p_vaddr >> 16);
    *bufp++ = 0;
    *bufp++ = (unsigned char)words;
    *bufp++ = (unsigned char)(words >> 8);
    write_drain( ttyfd, buffer, bufp - buffer );
    if ( phdr->p_filesz )
    {
        offset = lseek( fd, phdr->p_offset, SEEK_SET );
        if (offset == phdr->p_offset)
        {
            total = phdr->p_filesz;
            /* load only a whole number of words */
            max_bytes = (sizeof(buffer) / word_size) * word_size;
            bytes_read = 1;
            while ( total && bytes_read > 0 )
            {
                if ( total > max_bytes )
                {
                    to_read = max_bytes;
                }
                else
                {
                    to_read = total;
                }
                bytes_read = read( fd, buffer, to_read );
                if( bytes_read == to_read )
                {
                    bufp = buffer;
                    endp = bufp + bytes_read;
                    if ( phdr->p_flags & PF_X )
                    {
                        /* swab data to little endian */
                        while ( bufp < endp )
                        {
                            swap = *bufp;
                            *bufp = *(bufp + 2);
                            *(bufp + 2) = swap;
                            bufp += word_size;
                        }
                    }
                    else
                    {
                        /* swab data to little endian */
                        while ( bufp < endp )
                        {
                            swap = *bufp;
                            *bufp = *(bufp + 1);
                            *(bufp + 1) = swap;
                            bufp += word_size;
                        }
                    }
                    write_drain( ttyfd, buffer, bytes_read );
                }
                else
                {
                    bytes_read = 0;
                }
                total -= bytes_read;
            }
            if ( total )
            {
                fprintf( stderr, "Failed to send complete section\n" );
            }
        }
        else
        {
            perror( "Seek failed reading program" );
        }
    }
}

void boot_219X( int fd, Elf32_Ehdr *ehdr, Elf32_Phdr *phdr )
{
    static const unsigned char autobaud[] = { 0xaa };
    int count;
    unsigned char *headerp;
    int control;
    int i;
    int lastpm, lastdm;
    Elf32_Phdr *scanphdr;
    int failed;
    size_t acklen;
        
    write_drain( ttyfd, autobaud, sizeof(autobaud) );
    count = received( 2 );
    if ( (count == 2 && buffer[0] == 'O' && buffer[1] == 'K') ||
         (count == 1 && buffer[0] == 'K') )
    {
        control = (waitstates << 0 ) | (clockdiv << 3) |
                  (sport2_spi_mode << 6) |
                  (buswidth << 8) |
                  (epromwidth << 10);
        headerp = buffer;
        if ( forcefirstbyte )
        {
            *headerp++ = control;
        }
        *headerp++ = control >> 8;
        write_drain( ttyfd, buffer, headerp - buffer );
        
        /* look for last pm and last dm indexes */
        lastpm = lastdm = -1;
        scanphdr = phdr + ehdr->e_phnum;
        for ( i = ehdr->e_phnum - 1 ; i >= 0 ; --i )
        {
            --scanphdr;
            if ( scanphdr->p_type == PT_LOAD )
            { 
                if ( scanphdr->p_flags & PF_X )
                {
                    if ( lastpm < 0 )
                    {
                        lastpm = i;
                    }
                }
                else
                {
                    if ( lastdm < 0 )
                    {
                        lastdm = i;
                    }
                }
            }
        }
        if ( lastpm >= 0 && lastdm >= 0 )
        {
            scanphdr = phdr;
            failed = FALSE;
            for ( i = 0 ; i < ehdr->e_phnum && !failed ; ++i )
            {
                if ( scanphdr->p_type == PT_LOAD &&
                    i != lastpm && i != lastdm )
                {
                    failed = !send_219x_block( fd, scanphdr, FALSE );
                }
                ++scanphdr;
            }
            if ( !failed )
            {
                failed = !send_219x_block( fd, phdr + lastpm, TRUE );
                if ( !failed )
                {
                    failed = !send_219x_block( fd, phdr + lastdm, TRUE );
                }
            }
            if ( failed )
            {
                fprintf( stderr, "Failed to boot.\n" );
            }
            else
            {
                if ( ackstring )
                {
                    acklen = strlen( ackstring );
                    count = received( acklen );
                    if ( count == acklen &&
                         strncmp( ackstring, (char *)buffer, acklen ) == 0 )
                    {
                        printf( "Download successful.\n" );
                    }
                    else
                    {
                        printf( "Download failed.\n" );
                    }
                }
                else
                {
                    printf( "Download complete\n" );
                }
            }
        }
        else
        {
            fprintf( stderr, "At least one program and one data section is required.\n" );
        }
    }
    else
    {
        fprintf( stderr, "No connection! Boot failed.\n" );
    }
}

void download_go( int fd, Elf32_Ehdr *ehdr, Elf32_Phdr *phdr )
{
    int i, j;
    int bytes_read;
    off_t offset;
    /*
     * On the ezkite lite, the monitor keeps a shadow vector table at
     * 0x3fc0 in program memory. The contents of this table is swapped
     * with the real vector table during a go command before the
     * downloaded programs entry point is called
     * table_top is the top of the real vector table.
     */
    enum { table_top = 0x30, swap_table = 0x3fc0 };
    unsigned long start, length;
    unsigned char *source;

    for ( i = 0 ; i < ehdr->e_phnum ; ++i )
    {
        if (phdr->p_type == PT_LOAD)
        { 
            if ( phdr->p_filesz > sizeof( buffer ) )
            {
                fprintf( stderr, "Loadable section size is too large: %d.\n",
                         phdr->p_filesz );
                return;
            }
            offset = lseek( fd, phdr->p_offset, SEEK_SET );
            if (offset != phdr->p_offset)
            {
                perror( "Seek failed reading program" );
                return;
            }
            bytes_read = read( fd, buffer, phdr->p_filesz );
            if (bytes_read != phdr->p_filesz)
            {
                perror( "Failed to read complete block" );
                return;
            }
            if (phdr->p_flags & PF_X)
            {
                if (phdr->p_vaddr + (phdr->p_filesz / program_word_size) >
                    program_top)
                {
                    fprintf( stderr, "Download would overwrite monitor program.\n" );
                    return;
                }
                if ( phdr->p_vaddr < table_top )
                {
                    start = phdr->p_vaddr + swap_table;
                    length = (table_top - phdr->p_vaddr) * program_word_size;
                    if ( download_program( buffer, start,
                                           length ) != length )
                    {
                        fprintf( stderr, "Failed to download program section\n" );
                        return;
                    }
                    start += length;
                    source = buffer + length;
                    length = phdr->p_filesz - length;
                }
                else
                {
                    source = buffer;
                    start = phdr->p_vaddr;
                    length = phdr->p_filesz;
                }
                if ( length )
                {
                    if ( download_program( source, start,
                                           length ) != length )
                    {
                        fprintf( stderr, "Failed to download program section\n" );
                        return;
                    }
                }
            }
            else
            {
                if (phdr->p_vaddr + phdr->p_filesz /
                    data_word_size > data_top)
                {
                    fprintf( stderr, "Download would overwrite monitor data.\n" );
                    return;
                }
                if ( download_data( buffer, phdr->p_vaddr,
                                    phdr->p_filesz ) != phdr->p_filesz )
                {
                    fprintf( stderr, "Failed to download data section\n" );
                    return;
                }
            }
        }
        ++phdr;
    }

    go( ehdr->e_entry );
}

void download_file( const char *filename, Elf32_Half machine,
                    void (*download_go)( int fd, Elf32_Ehdr *ehdr,
                                        Elf32_Phdr *phdr ) )
{
    Elf *elf;
    Elf32_Phdr *phdr;
    Elf32_Ehdr *ehdr;
    int fd;

    if ( machine == EM_ADSP218X )
    {
        printf( "Downloading and running \"%s\" to 218X EZ-Kit\n", filename );
    }
    else if ( machine == EM_ADSP219X )
    {
        printf( "Booting \"%s\" over 219X UART\n", filename );
    }
    else
    {
        return;
    }
    if ((fd = open(filename, O_RDONLY | O_BINARY)) != -1)
    {
        if (elf_version(EV_CURRENT) != EV_NONE)
        {
            elf = elf_begin(fd, ELF_C_READ, NULL);
            if (elf)
            {
                ehdr = elf32_getehdr( elf );
                if (ehdr )
                {
                    phdr = elf32_getphdr( elf );
                    if ( phdr )
                    {
                        (*download_go)( fd, ehdr, phdr );
                    }
                    else
                    {
                        fprintf( stderr,
                                    "Failed to get program header: %s",
                                    elf_errmsg(-1) );
                    }
                }
                else
                {
                    fprintf( stderr,
                             "Failed to get ELF header: %s\n",
                             elf_errmsg(-1) );
                }
                elf_end(elf);
            }
            else
            {
                fprintf( stderr, "download_file: elf_begin - %s\n",
                         elf_errmsg(-1) );
            }
        }
        else
        {
            fprintf(stderr, "Elf library is out of date\n" );
        }
        if (close( fd ) != 0)
            perror("Error closing executable");
    }
    else
    {
        perror("Error opening executable" );
    }
}

/*
 * one_section and sections scan a memory list which is a comma separated
 * list of <memory type(p, P, d, or D)><memory range> and memory range is
 * either <memory start):<length> or <memory start>-<memory end>.
 * one_section returns the number of characters scanned or -1 on error.
 * sections returns the number of sections read or -1 on error. 
 */
int one_section( const char *memory_list, unsigned long *start,
                 unsigned long *length )
{
    int count = 0, save_index;
    char *endptr;
    int end_address = FALSE;

    if (*memory_list == '\0')
    {
        return 0;
    }
    if (tolower(*memory_list) != 'p' &&
        tolower(*memory_list) != 'd')
    {
        return -1;
    }
    ++count;
    ++memory_list;
    *start = strtol( memory_list, &endptr, 0 );
    count += endptr - memory_list;
    memory_list = endptr;
    if (*memory_list == '-')
    {
        end_address = TRUE;
    }
    else if (*memory_list != ':')
    {
        return -1;
    }
    ++count;
    ++memory_list;
    *length = strtol( memory_list, &endptr, 0 );
    count += endptr - memory_list;
    memory_list = endptr;
    if (*memory_list == ',')
    {
        ++count;
    }
    if ( end_address )
    {
        *length = *length - *start + 1;
    }
    return count;
}

int sections( const char *memory_list )
{
    int length;
    int count;
    unsigned long dummy;

    count = 0;
    for ( length = 1 ; length > 0 ; )
    {
        length = one_section( memory_list, &dummy, &dummy );
        if (length < 0)
        {
            count = -1;
            break;
        }
        else if (length > 0)
        {
            ++count;
        }
        memory_list += length;
    }
    return count;
}

/*
 * create the ELF program headers for the file created by upload
 */
void upload_phdrs(
    int fd, const char *memory_list,
    Elf *elf, Elf32_Ehdr *ehdr, Elf32_Phdr *phdr
)
{
    const char *scan_list = memory_list;
    off_t offset;
    char *errlocation;
    int length;
    unsigned long mem_start, mem_length;

    errlocation = NULL;
    ehdr->e_machine = EM_ADSP218X;
    if ( elf_update(elf, ELF_C_WRITE) >= 0 )
    {
        elf_flagphdr( elf, ELF_C_SET, ELF_F_DIRTY );
        offset = lseek( fd, 0, SEEK_END );
        length = 1;
        while (length > 0)
        {
            length = one_section( scan_list, &mem_start,
                                  &mem_length );
            if (length > 0)
            {
                phdr->p_type = PT_LOAD;
                phdr->p_offset = offset;
                phdr->p_vaddr = mem_start;
                if (tolower(*scan_list) =='p')
                {
                    phdr->p_filesz = mem_length *
                        program_word_size;
                    phdr->p_flags = PF_R | PF_W | PF_X;
                }
                else
                {
                    phdr->p_filesz = mem_length *
                        data_word_size;
                    phdr->p_flags = PF_R | PF_W;
                }
                phdr->p_memsz = phdr->p_filesz;
                offset += phdr->p_filesz;
                ++phdr;
                scan_list += length;
            }
        }
        if ( elf_update(elf, ELF_C_WRITE) < 0 )
            errlocation = "Failed to update program header";
    }
    else
        errlocation = "Failed to update ELF header";
    if ( errlocation )
        fprintf( stderr, "upload_sections: %s - %s\n",
                 errlocation, elf_errmsg(-1) );
}

void upload_file( const char *filename, const char *memory_list )
{
    int fd = -1;
    int length;
    unsigned long mem_start, mem_length;
    unsigned long bytes_uploaded, write_bytes;
    Elf *elf = NULL;
    Elf32_Ehdr *ehdr;
    Elf32_Phdr *phdr = NULL;
    int program_sections;
    int success = FALSE;
    const char *from;
    int file_flags;
    static const char *program = "program";
    static const char *data = "data";
    char *errlocation;

    errlocation = NULL;
    program_sections = sections( memory_list );
    if (program_sections <=  0)
    {
        fprintf( stderr, "Error in memory list: %s.\n", memory_list );
        return;
    }
    if (filename)
    {
        file_flags = O_WRONLY | O_CREAT | O_BINARY;
        if (force)
        {
            file_flags |= O_TRUNC;
        }
        else
        {
            file_flags |= O_EXCL;
        }
        printf( "Uploading to \"%s\" from EZ-Kit\n", filename );
        if ((fd = open(filename, file_flags, S_IRUSR | S_IWUSR)) != -1)
        {
            if (elf_version(EV_CURRENT) != EV_NONE)
            {
                elf = elf_begin(fd, ELF_C_WRITE, NULL);
                if (elf)
                {
                    ehdr = elf32_newehdr(elf);
                    if ( ehdr )
                    {
                        phdr = elf32_newphdr(elf, program_sections);
                        if (phdr)
                        {
                            success = TRUE;
                            upload_phdrs( fd, memory_list, elf, ehdr,
                                          phdr );
                        }
                        else
                            errlocation = "phdr";
                    }
                    else
                        errlocation = "ehdr";
                }
                else
                    errlocation = "elf";
                if ( errlocation )
                {
                    fprintf( stderr,
                             "upload_file: %s - %s\n",
                             errlocation, elf_errmsg(-1));
                }
            }
            else
                fprintf( stderr, "Elf library is out of date\n" );
        }
        else
            perror( "Failed to open output file" );
    }
    if (filename == NULL || phdr != NULL)
    {
        length = 1;
        while (length > 0)
        {
            length = one_section( memory_list, &mem_start, &mem_length );
            if (length > 0)
            {
                if (tolower(*memory_list) == 'p')
                {
                    bytes_uploaded = upload_program( mem_start, mem_length );
                    write_bytes = bytes_uploaded;
                    success = mem_length * program_word_size == write_bytes;
                    from = program;
                }
                else
                {
                    bytes_uploaded = upload_data( mem_start, mem_length );
                    write_bytes = bytes_uploaded;
                    success = mem_length * data_word_size == write_bytes;
                    from = "data";
                }
                if (success)
                {
                    if (phdr)
                    {
                        write( fd, buffer, write_bytes );
                        ++phdr;
                    }
                    else
                    {
                        printf( "Uploaded %s: %#x-%x\n", from, mem_start,
                                mem_length );
                        dump( buffer, bytes_uploaded );
                    }
                    memory_list += length;
                }
                else
                {
                    length = -1;
                    fprintf( stderr,
                             "Failed to upload the correct amount of data.\n" );
                }
            }
        }
    }
    if (elf)
    {
        if (phdr)
        {
            if ( elf_update(elf, ELF_C_WRITE) < 0 )
                fprintf(stderr, "Failed to update program data: %s\n",
                        elf_errmsg(-1));
        }
        elf_end( elf );
    }
    if (fd >= 0)
    {
        close( fd );
        if (!success)
        {
            unlink(filename);
        }
    }
}

int main( int argc, char **argv )
{
    static char usage[] =
        "Usage:\n"
        "    ez21 <switches> [file]\n"
        "      Common switches/paramaters:\n"
        "        [-b 2400|4800|9600|19200|38400] - set the serial port baud rate\n"
        "        [-D] - turn on debugging\n"
        "        [-d <device>] - set the communications device (default /dev/ttyS0)\n"
        "        [-v] - display version information\n"
        "        [file] - file to download from or upload to.\n"
        "      218x switches:\n"
        "        [-B] - send a beep to the 218x EZ-Kit.\n"
        "        [-f] - force overwrite of output file on upload\n"
        "        [-u (p|P|d|D)<start>(:<words>|-<end),...] - upload memory.\n"
        "      219x switches (see ADI's EE-131 tech note on UART booting):\n"
        "        [-A <string>] - response to expect after booting. (default: none)\n"
        "        [-c 1|2|4|8|16|32] - control word clock divider.\n"
        "        [-F] - Force first byte of control word. \n"
        "        [-O SPI|SPORT] - control word SPI/SPORT. (default: SPI)\n"
        "        [-s 0-7] - control word wait states (default: 0)\n"
        "        [-W 8|16] - control word external/host port bus width. (default: 8 bits)\n"
        "        [-w 8|16] - control word external EEPROM width. (default: 8 bits)\n";
    struct termios modes, save_modes;
    ssize_t count;
    static unsigned char buf[100];
    int i, bytes_read;
    int result;
    int option;
    char *port = "/dev/ttyS0";
    int send_beep = FALSE;
    int baud_rate;
    speed_t baud_setting = B9600;
    const char *upload_list = NULL;
    char *endarg;
    int retcode = 0;
    Elf32_Half machine;

    progress_block = PROGRESS_9600;
    while ((option = getopt( argc, argv, "Bu:A:c:FO:s:W:w:b:Dd:fv")) != -1)
    {
        switch( option )
        {
            /* 218x specific switches */
            case 'B':
                send_beep = TRUE;
                break;
            case 'f':
                force = TRUE;
                break;
            case 'u':
                upload_list = optarg;
                break;
                
            /* 219x specific switches */
            case 'A':
                ackstring = optarg;
                break;
            case 'c':    /* clock divider for control */
                clockdiv = strtol( optarg, &endarg, 0 );
                if ( *endarg != '\0' )
                {
                    clockdiv = 0;    /* an illegal value */
                }
                switch ( clockdiv )
                {
                    case 1:
                        clockdiv = 0;
                        break;
                    case 2:
                        clockdiv = 1;
                        break;
                    case 4:
                        clockdiv = 2;
                        break;
                    case 8:
                        clockdiv = 3;
                        break;
                    case 16:
                        clockdiv = 4;
                        break;
                    case 32:
                        clockdiv = 5;
                        break;
                    default:
                        fprintf( stderr,
                                 "%s is not a valid clock divider. Try 1, 2, 4, 8, 16, or 32\n",
                                 optarg );
                        exit( 1 );
                    break;
                }
                break;
            case 'F':
                forcefirstbyte = TRUE;
                break;
            case 'O':    /* operating mode for control word */
                if ( strcmp( optarg, "SPORT2" ) == 0 )
                {
                    sport2_spi_mode = 0;
                }
                else if ( strcmp( optarg, "SPI" ) == 0 )
                {
                    sport2_spi_mode = 1;
                }
                else
                {
                    fprintf( stderr,
                             "%s is not a valid operating mode. Try \"SPORT2\" or \"SPI\"\n",
                             optarg );
                    exit( 1 );
                }
                break;
            case 's':    /* wait states for control word */
                waitstates = strtol( optarg, &endarg, 0 );
                if ( *endarg !='\0' || waitstates < 0 || waitstates > 7 )
                {
                    fprintf( stderr,
                             "%s is not a valid wait state count.\n"
                             "Try a number from 0 to 7\n", optarg );
                    exit( 1 );
                }
                break;
            case 'W':    /* External/Host port bus width for control word */
                buswidth = strtol( optarg, &endarg, 0 );
                if ( *endarg != '\0' )
                {
                    buswidth = 0;
                }
                if ( buswidth == 8 )
                {
                    buswidth = 0;
                }
                else if ( buswidth == 16 )
                {
                    buswidth = 1;
                }
                else
                {
                    fprintf( stderr,
                             "%s is not a valid external/host port bus width.\n"
                             "Try \"8\" or \"16\".\n", optarg );
                    exit( 1 );
                }
                break;
            case 'w':    /* External EPROM width for control word */
                epromwidth = strtol( optarg, &endarg, 0 );
                if ( *endarg != '\0' )
                {
                    epromwidth = 0;
                }
                if ( epromwidth == 8 )
                {
                    epromwidth = 0;
                }
                else if ( epromwidth == 16 )
                {
                    epromwidth = 1;
                }
                else
                {
                    fprintf( stderr,
                             "%s is not a valid eprom width.\n"
                             "Try \"8\" or \"16\".\n", optarg );
                    exit( 1 );
                }
                break;
            
            /* common switches */
            case 'b':
                baud_rate = strtol( optarg, &endarg, 10 );
                if ( *endarg != '\0' )
                {
                    baud_rate = 0;
                }
                switch ( baud_rate )
                {
                    case 2400:
                        baud_setting = B2400;
                        progress_block = PROGRESS_2400;
                        break;
                    case 4800:
                        baud_setting = B4800;
                        progress_block = PROGRESS_4800;
                        break;
                    case 9600:
                        baud_setting = B9600;
                        progress_block = PROGRESS_9600;
                        break;
                    case 19200:
                        baud_setting = B19200;
                        progress_block = PROGRESS_19200;
                        break;
                    case 38400:
                        baud_setting = B38400;
                        progress_block = PROGRESS_38400;
                        break;
                    default:
                        fprintf( stderr, "Invalid baud rate\n%s", usage );
                        exit(1);
                }
                break;
            case 'D':
                dump_comms = TRUE;
                break;
            case 'd':
                port = optarg;
                break;
            case 'v':
                printf( "%s\n", version );
                exit( 0 );
            case ':':
            case '?':
            default:
                fprintf( stderr, "%s", usage );
                exit( 1 );
        }
    }
    if ((ttyfd = open(port, O_RDWR | O_NOCTTY | O_BINARY)) != -1)
    {
        result = tcgetattr( ttyfd, &modes );
        save_modes = modes;
        if ( result == 0 &&
             cfsetispeed( &modes, baud_setting ) == 0 &&
             cfsetospeed( &modes, baud_setting ) == 0 )
        {
            modes.c_cc[VMIN] = 0;
            modes.c_cc[VTIME] = 10;
            modes.c_lflag &= ~(ICANON | ECHO | ECHOE | ECHOK | ECHOKE |
                               IEXTEN | ISIG);
            modes.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON | IGNPAR);
            modes.c_cflag &= ~(CSIZE | PARENB);
            modes.c_cflag |= CS8;
            modes.c_oflag &= ~(OPOST | ONLCR);
            if (tcsetattr( ttyfd, TCSAFLUSH, &modes ) == 0)
            {
                tcflush( ttyfd, TCIOFLUSH );
                machine = EM_ADSP218X;
                if ( optind + 1 == argc && upload_list == NULL )
                {
                    machine = download_machine( argv[optind] );
                    if ( machine == EM_ADSP219X )
                    {
                        download_file( argv[optind], machine,
                                       boot_219X );
                    }
                }
                if ( machine == EM_ADSP218X )
                {
                    if (alive())
                    {
                        printf( "Ezkit lite is fully functional and ready.\n" );
                        if (send_beep)
                        {
                            beep( );
                        }
                        if (optind + 1 == argc || upload_list != NULL)
                        {
                            progress = TRUE;
                            if (upload_list)
                            {
                                upload_file( argv[optind], upload_list );
                            }
                            else
                            {
                                download_file( argv[optind], machine,
                                               download_go );
                            }
                            printf( "\n" );
                        }
                    }
                    else
                    {
                        fprintf( stderr, "Ezkit lite is not responding.\n" );
                        retcode = 2;
                    }
                }
                else if ( machine != EM_ADSP219X )
                {
                    fprintf( stderr, "Unrecognized machine: %x.\n", machine );
                    retcode = 4;
                }
            }
        }
        else
        {
            perror( "Failed to set port speed" );
            retcode = 3;
        }
        tcsetattr( ttyfd, TCSAFLUSH, &save_modes );
        if (close( ttyfd ) != 0)
            perror( "Error closing port" );
    }
    else
    {
        perror( "Error opening port" );
        retcode = 3;
    }

    return retcode;
}





