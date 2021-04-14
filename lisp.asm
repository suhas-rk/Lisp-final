	global main
	extern puts

	section .text
main:
	mov rdi, message0
	call puts
	mov rdi, message1
	call puts
	ret
	section .data
message0: db "Value of result is", 0
message1: db "0", 0
