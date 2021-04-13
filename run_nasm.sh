nasm -felf64 lisp.asm
gcc -no-pie lisp.o -o lisp-nasm
./lisp-nasm