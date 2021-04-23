COMPFLAG="-ll"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  COMPFLAG=""
fi

exitcode="0"

echo "Running parser!"
echo
g++ -c ASTTree.cc
lex scanner.l
yacc -d parser.y
g++ y.tab.c lex.yy.c ASTTree.cc $COMPFLAG
./a.out < "$1"
exitcode="$?"

if [ "$exitcode" == "0" ]; then
  echo
  echo "Running optimization and super optimization!"
  echo
  lex opt.l
  yacc -d opt.y
  g++ y.tab.c lex.yy.c $COMPFLAG
  ./a.out -Op -nasm < ic.3ac
  exitcode="$?"
fi

if [ "$exitcode" == "0" ]; then
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo
    echo "Assembling and running produced NASM code for x86_64 on GNU/Linux!"
    echo
    nasm -felf64 lisp.asm
    gcc -no-pie lisp.o -o lisp-nasm
    ./lisp-nasm
  fi
fi