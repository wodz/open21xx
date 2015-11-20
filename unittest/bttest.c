#include <unistd.h>
#include <stdio.h>
#include "bbtree.h"

struct numeric
{
    BBTREE_NODE_T node;
    int number;
};

void print_node( BBTREE_NODE_T *node, int depth )
{
    int i;
    struct numeric *numeric = (struct numeric *)node;

    for (i=0 ; i<depth ; ++i )
        printf( " " );
    printf("%c:%p %p %p %p %d\n",
           node->colour == BBTREE_RED ? 'R' : 'B',
           node,
           node->parent, node->left, node->right,
           numeric->number );
}

void delete_node( BBTREE_NODE_T *node, int depth )
{
    if (node->left != NULL)
    {
        printf("Still have a left node\n");
    }
    if (node->right != NULL)
    {
        printf("Still have a right node\n");
    }

    if (node->parent)
    {
        if (node->parent->left == node)
        {
            node->parent->left = NULL;
        }
        else if(node->parent->right == node)
        {
            node->parent->right = NULL;
        }
        else
        {
            printf("We're not our parents child\n");
        }
    }
    free(node->right);
}

int comparefn( void *key, BBTREE_NODE_T *element )
{ 
    return *(int *)key - ((struct numeric *)element)->number;
}

int main( int argc, char **argv )
{
    int number, depth;
    BBTREE_T tree;
    BBTREE_NODE_T *parent;
    struct numeric *numeric;
    int compare;

    BBTREE( &tree, comparefn, 0 );
    while(argc > 1)
    {
        --argc;
        ++argv;
        number = atoi(*argv);
        //printf("Inserting %d\n", number );

        parent = bbtree_preinsert( &tree, &number, &compare );
        if (!parent || compare != 0)
        {
            numeric = (struct numeric *)malloc(sizeof(*numeric));
            if (!numeric)
            {
                printf("Memory alloc error\n");
                exit(1);
            }
            numeric->number = number;
            bbtree_insert( &tree, parent, &numeric->node,
                           compare );
        }
        else
            printf("parent=%p compare=%d\n", parent, compare );
    }
    depth = 0;
    printf("Tree after insertion\n" );
    bbtree_leftright_walk( &tree, tree.root, print_node, &depth );
    bbtree_bottomup_walk( &tree, tree.root, delete_node, &depth );
    tree.root = NULL;
    printf("Tree after deletion\n" );
    bbtree_leftright_walk( &tree, tree.root, print_node, &depth );
#if 0
    printf("%p\n", tree.root );
    print_node( &tree.root );
    printf( "\n" );
#endif
    return 0;
}

/*
 * Local variables:
 *  compile-command: "gcc -g -o main main.c bbtree.c"
 * End:
 */


