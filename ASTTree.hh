#ifndef ASTNODE_HH
#define ASTNODE_HH

struct row
{
    char id[128];
    int line_no;
    int scope;
    int valid_value;
    int num_value;
    char bool_value;
    char *str_value;
    int type;
};

class ASTNode{
    public:
    int number_of_children;
    ASTNode *child[3];
    int type;
    /*
        0 - NULL value
        1 - operator - for/while/if/+/-....
        2 - id
        3 - number value
        4 - bool value
        5 - string value
    */
    char *ope;
    char *id;
    int num_value;
    bool bool_value;
    char *str_value;
};


ASTNode* makeLeafNode_id(char *n);
ASTNode* makeLeafNode_num(int n);
ASTNode* makeLeafNode_bool(bool n);
ASTNode* makeLeafNode_str(char *n);
ASTNode* makeNode1(char *value, ASTNode *c1);
ASTNode* makeNode2(char *value, ASTNode *c1, ASTNode *c2);
ASTNode* makeNode3(char *value, ASTNode *c1, ASTNode *c2, ASTNode *c3);
void preorder_traversal(ASTNode *root);
#endif