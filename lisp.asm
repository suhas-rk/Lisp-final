	global main
	extern puts

	section .text
main:
	mov rdi, message0
	call puts
	mov rdi, message1
	call puts
	mov rdi, message2
	call puts
	mov rdi, message3
	call puts
	mov rdi, message4
	call puts
	mov rdi, message5
	call puts
	mov rdi, message6
	call puts
	ret
	section .data
message0: db 34, "E is 15", 34, 0
message1: db 34, "Value of e is", 34, 0
message2: db "15", 0
message3: db 34, "Printing constant integer", 34, 0
message4: db "10", 0
message5: db 34, "Check is 14", 34, 0
message6: db "5", 0
