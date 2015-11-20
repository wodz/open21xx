/*
 * bbtree.c
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
 * Algorithm taken from:
 *  Introduction to Algorithms
 *    By Thomas H. Cormen
 *       Charles E. Leiserson
 *       Ronald L. Rivest
 */

#include <stdlib.h>
#include <assert.h>
#include "../defs.h"
#include "bbtree.h"

static void left_rotate( bbtree_t *tree, bbtree_node_t *node )
{
    bbtree_node_t *node2;
    bbtree_node_t *nil = &tree->nil;
    
    node2 = node->right;
    node->right = node2->left;
    if (node2->left != nil)
        node2->left->parent = node;
    node2->parent = node->parent;
    if (node->parent == nil)
        tree->root = node2;
    else
    {
        if (node == node->parent->left)
            node->parent->left = node2;
        else
            node->parent->right = node2;
    }
    node2->left = node;
    node->parent = node2;
}

static void right_rotate( bbtree_t *tree, bbtree_node_t *node )
{
    bbtree_node_t *node2;
    bbtree_node_t *nil = &tree->nil;
    
    node2 = node->left;
    node->left = node2->right;
    if (node2->right != nil)
        node2->right->parent = node;
    node2->parent = node->parent;
    if (node->parent == nil)
        tree->root = node2;
    else
    {
        if (node == node->parent->right)
            node->parent->right = node2;
        else
            node->parent->left = node2;
    }
    node2->right = node;
    node->parent = node2;
}

static void bbtree_insert_fixup( bbtree_t *tree,
                                 bbtree_node_t *node )
{
    bbtree_node_t *node2;
    bbtree_node_t *nil = &tree->nil;

    while (node != tree->root && node->parent->colour == BBTREE_RED)
    { 
        if (node->parent == node->parent->parent->left)
        { 
            node2 = node->parent->parent->right;
            if (node2 != nil && node2->colour == BBTREE_RED)
            { 
                node->parent->colour = BBTREE_BLACK;
                node2->colour = BBTREE_BLACK;
                node->parent->parent->colour = BBTREE_RED;
                node = node->parent->parent;
            }
            else
            {
                if (node == node->parent->right)
                {
                    node = node->parent;
                    left_rotate( tree, node );
                }
                node->parent->colour = BBTREE_BLACK;
                node->parent->parent->colour = BBTREE_RED;
                right_rotate( tree, node->parent->parent );
            }
        }
        else
        {
            node2 = node->parent->parent->left;
            if (node2 != nil && node2->colour == BBTREE_RED)
            { 
                node->parent->colour = BBTREE_BLACK;
                node2->colour = BBTREE_BLACK;
                node->parent->parent->colour = BBTREE_RED;
                node = node->parent->parent;
            }
            else
            {
                if (node == node->parent->left)
                {
                    node = node->parent;
                    right_rotate( tree, node );
                }
                node->parent->colour = BBTREE_BLACK;
                node->parent->parent->colour = BBTREE_RED;
                left_rotate( tree, node->parent->parent );
            }
        }
    }
    tree->root->colour = BBTREE_BLACK;
}

void bbtree( bbtree_t *tree,
             bbtree_cmpfn_t cmpfn,
             int allow_duplicates )
{ 
    tree->root = tree->nil.left = tree->nil.right =
        tree->nil.parent = &tree->nil;
    tree->cmpfn = cmpfn;
    tree->allow_duplicates = allow_duplicates;
}

static void bbtree_delete_walk( bbtree_t *tree,
                                bbtree_node_t *node,
                                bbtree_deletefn_t deletefn )
{
    if ( node != &tree->nil )
    {
        bbtree_delete_walk( tree, node->left, deletefn );
        bbtree_delete_walk( tree, node->right, deletefn );
        if ( deletefn )
            (*deletefn)( node );
    }
}

/*
 * Utility if all the tree owner wants to do is delete the node
 * If something else has to be done or the tree owner is managing
 * the node memory, the delete function should be NULL.
 */
void bbtree_deletefn( bbtree_node_t *node )
{
    free( node );
}

void bbtree_destroy( bbtree_t *tree, bbtree_deletefn_t deletefn )
{
    bbtree_delete_walk( tree, tree->root, deletefn );
    tree->root = &tree->nil;
}

/*
 * return a pointer to a matching node if it exists
 * or to the parent of a node that would be inserted
 * under key. NOTE: the two may be but aren't
 * necessarily the same.
 */
bbtree_node_t *bbtree_preinsert( const bbtree_t *tree,
                                 const void *key,
                                 int *compare )
{
    bbtree_node_t *scan;
    const bbtree_node_t *last_scan;
    const bbtree_node_t *nil = &tree->nil;

    last_scan = nil;
    scan = tree->root;
    /* default to a none zero value */
    *compare = 1;
    while (scan != nil)
    {
        last_scan = scan;
        *compare = tree->cmpfn(key, scan);
        if (!tree->allow_duplicates && *compare == 0)
            return scan;
        else if (*compare < 0)
            scan = scan->left;
        else
            scan = scan->right;
    }
    return (bbtree_node_t *)last_scan;
}

void bbtree_insert( bbtree_t *tree,
                    bbtree_node_t *parent,
                    bbtree_node_t *new_node,
                    int compare )
{
    bbtree_node_t *nil = &tree->nil;

    new_node->left = nil;
    new_node->right = nil;
    new_node->colour = BBTREE_RED;
    new_node->parent = parent;
    if (parent == nil)
        tree->root = new_node;
    else if (compare < 0)
        parent->left = new_node;
    else
        parent->right = new_node;
    bbtree_insert_fixup( tree, new_node );
}

#if 0
void bbtree_delete( bbtree_t *tree, bbtree_node_t *node )
{
    assert(node->left == &tree->nil);
    assert(node->right == &tree->nil);

    if (node->parent)
    {
        if (node->parent->left == node)
        {
            node->parent->left = &tree->nil;
        }
        else if(node->parent->right == node)
        {
            node->parent->right = &tree->nil;
        }
        else
        {
            assert(FALSE);
        }
    }

    free(node);
}
#endif

void bbtree_remove_fixup( bbtree_t *tree, bbtree_node_t *node )
{
    bbtree_node_t *sibling;

    while ( node != tree->root && node->colour == BBTREE_BLACK )
    {
        if ( node == node->parent->left )
        {
            sibling = node->parent->right;
            if ( sibling->colour == BBTREE_RED )
            {
                sibling->colour = BBTREE_BLACK;
                node->parent->colour = BBTREE_RED;
                left_rotate( tree, node->parent );
                sibling = node->parent->right;
            }
            if ( sibling->left->colour == BBTREE_BLACK &&
                 sibling->right->colour == BBTREE_BLACK )
            {
                sibling->colour = BBTREE_RED;
                node = node->parent;
            }
            else
            {
                if ( sibling->right->colour == BBTREE_BLACK )
                {
                    sibling->left->colour = BBTREE_BLACK;
                    sibling->colour = BBTREE_RED;
                    right_rotate( tree, sibling );
                    sibling = node->parent->right;
                }
                sibling->colour = node->parent->colour;
                node->parent->colour = BBTREE_BLACK;
                sibling->right->colour = BBTREE_BLACK;
                left_rotate( tree, node->parent );
                node = tree->root;
            }
        }
        else
        {
            sibling = node->parent->left;
            if ( sibling->colour == BBTREE_RED )
            {
                sibling->colour = BBTREE_BLACK;
                node->parent->colour = BBTREE_RED;
                right_rotate( tree, node->parent );
                sibling = node->parent->left;
            }
            if ( sibling->right->colour == BBTREE_BLACK &&
                 sibling->left->colour == BBTREE_BLACK )
            {
                sibling->colour = BBTREE_RED;
                node = node->parent;
            }
            else
            {
                if ( sibling->left->colour == BBTREE_BLACK )
                {
                    sibling->right->colour = BBTREE_BLACK;
                    sibling->colour = BBTREE_RED;
                    left_rotate( tree, sibling );
                    sibling = node->parent->left;
                }
                sibling->colour = node->parent->colour;
                node->parent->colour = BBTREE_BLACK;
                sibling->left->colour = BBTREE_BLACK;
                right_rotate( tree, node->parent );
                node = tree->root;
            }
        }
    }
}

bbtree_node_t *bbtree_remove( bbtree_t *tree, bbtree_node_t *node )
{
    bbtree_node_t *x, *y;
    bbtree_node_t *nil = &tree->nil;
    int fixup;

    /* y is node if node has at most 1 child */
    if ( node->left == nil ||
         node->right == nil )
    {
        /* y = node */
        y = node;
    }
    else
    /* else y is node's successor which has at most 1 child */
    {
        /* y = successor(node) */
        y = node->right;
        while (y->left != nil)
            y = y->left;
    }
    /* x is the non-nil child of y if there is one
     * else x is nil */
    if ( y->left != nil )
    {
        x = y->left;
    }
    else
    {
        x = y->right;
    }
    /* replace y with x in the tree */
    x->parent = y->parent;
    if ( y->parent == nil )
    {
        tree->root = x;
    }
    else
    {
        if ( y == y->parent->left )
        {
            y->parent->left = x;
        }
        else
        {
            y->parent->right = x;
        }
    }
    fixup = y->colour == BBTREE_BLACK;
    /* if y is not node then y replaces node in the tree
     * otherwise node is already removed */
    if ( y != node )
    {
        /* hook y in place of node */
        *y = *node;
        /* hook y as it's parent's child */
        if ( y->parent == nil )
        {
            tree->root = y;
        }
        else if ( y->parent->left == node )
        {
            y->parent->left = y;
        }
        else
        {
            y->parent->right = y;
        }
        /* hook y as it's children's parent */
        if ( y->left != nil )
        {
            y->left->parent = y;
        }
        if ( y->right != nil )
        {
            y->right->parent = y;
        }
    }

    if ( fixup )
        bbtree_remove_fixup( tree, x );

    return node;
}

/* tree walking functions */
void bbtree_leftright_walk( bbtree_t *tree,
                            bbtree_node_t *node,
                            bbtree_walkfn_t walkfn,
                            void *user )
{
    if (node != &tree->nil)
    {
        ++tree->height;
        bbtree_leftright_walk( tree, node->left, walkfn, user );
        assert( node->left == &tree->nil ||
                node->left->parent == node );
        assert( node->right == &tree->nil ||
                node->right->parent == node );
        (*walkfn)( tree, node, user );
        bbtree_leftright_walk( tree, node->right, walkfn, user );
        --tree->height;
    }
}

void bbtree_bottomup_walk( bbtree_t *tree,
                           bbtree_node_t *node,
                           bbtree_walkfn_t walkfn,
                           void *user )
{
    if (node != &tree->nil)
    {
        ++tree->height;
        bbtree_bottomup_walk( tree, node->left, walkfn, user );
        bbtree_bottomup_walk( tree, node->right, walkfn, user );
        assert( node->left == &tree->nil ||
                node->left->parent == node );
        assert( node->right == &tree->nil ||
                node->right->parent == node );
        (*walkfn)( tree, node, user );
        --tree->height;
    }
}




