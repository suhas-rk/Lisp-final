lex opt.l
yacc -d opt.y
g++ y.tab.c lex.yy.c -ll
./a.out -Op -nasm < Icg.txt
