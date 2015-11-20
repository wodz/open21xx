/*
 * bbtree.h 
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
 * bbtree provides a tool set to use to create arbitrary balanced
 * binary trees.
 */

#ifndef BBTREE_H
#define BBTREE_H

enum colour
{
    BBTREE_BLACK,
    BBTREE_RED
};

typedef struct bbtree_node_t bbtree_node_t;
typedef struct bbtree_t bbtree_t;

typedef void (*bbtree_walkfn_t)( bbtree_t *tree,
                                 bbtree_node_t *node,
                                 void *user );

typedef int (*bbtree_cmpfn_t)( const void *key,
                               const bbtree_node_t *element );

typedef void (*bbtree_deletefn_t)( bbtree_node_t *node );

struct bbtree_node_t
{
    bbtree_node_t *left, *right, *parent;
    enum colour colour;
};

struct bbtree_t
{
    bbtree_node_t *root;
    bbtree_cmpfn_t cmpfn;
    int allow_duplicates;
    bbtree_node_t nil;
    int height;       /* used to check for a balanced tree */
};

void bbtree( bbtree_t *tree,
             bbtree_cmpfn_t cmpfn,
             int allow_duplicates );

void bbtree_deletefn( bbtree_node_t *node );
void bbtree_destroy( bbtree_t *tree, bbtree_deletefn_t deletefn );

/*
 * bbtree_preinsert and bbtree_insert are used together to add nodes to a
 * balanced binary tree. bbtree_preinsert will find the parent of the node
 * that would be inserted with key. Once you've found the parent
 * allocate a node plus whatever other information you want to keep
 * with the node and insert it with bbtree_insert. If compare is zero on 
 * return from preinsert, parent points to a node with a key that is equal
 * to the key supplied to the preinsert call. The code between
 * bbtree_preinsert and bbtree_insert defines whether the tree allows
 * duplicate keys and can determine other characteristics of the
 * specific tree.
 */ 
bbtree_node_t *bbtree_preinsert( const bbtree_t *tree,
                                 const void *key, int *compare );

void bbtree_insert( bbtree_t *tree, bbtree_node_t *parent, 
                    bbtree_node_t *node, int compare );

bbtree_node_t *bbtree_remove( bbtree_t *tree, bbtree_node_t *node );

/* tree walking functions */
void bbtree_leftright_walk( bbtree_t *tree,
                            bbtree_node_t *start_node,
                            bbtree_walkfn_t walkfn,
                            void *user );

void bbtree_bottomup_walk( bbtree_t *tree,
                           bbtree_node_t *start_node,
                           bbtree_walkfn_t walkfn,
                           void *user );

#endif



