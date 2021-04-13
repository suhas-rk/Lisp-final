lex opt.l
yacc -d opt.y
gcc y.tab.c lex.yy.c -ll
./a.out < Icg.txt
