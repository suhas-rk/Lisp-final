g++ -c ASTTree.cc
lex scanner.l
yacc -d parser.y
g++ y.tab.c lex.yy.c ASTTree.cc -ll
./a.out < test1.txt

