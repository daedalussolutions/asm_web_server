.intel_syntax noprefix
.globl _start

.section .text

_start:
    # Socket syscall
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    mov sockfd, rax
    
    # Bind socket
    mov rdi, sockfd
    lea rsi, sockaddr
    mov rdx, 16
    mov rax, 49
    syscall

    # Listen syscall
    mov rax, 50
    mov rdi, sockfd
    mov rsi, 0
    syscall

accept_loop:
    # Accepting a signal
    mov rax, 43
    mov rdi, sockfd
    mov rdx, 0
    mov rsi, 0
    syscall
    mov tunnel, rax

    # Fork
    mov rax, 57
    syscall

    cmp rax, 0
    je child_process

parent_process:

    mov rdi, tunnel
    mov rax, 3
    syscall
    jmp accept_loop

child_process:

    mov rdi, sockfd
    mov rax, 3 
    syscall

    mov rdi, tunnel
    lea rsi, buffer
    mov rdx, 1024
    mov rax, 0
    syscall
    mov bufferlen, rax

    # determine GET or POST
    mov eax, buffer
    mov ebx, bufferget
    cmp eax, ebx
    je GET
    mov ebx, bufferpost
    cmp eax, ebx
    je POST

    jmp exit

GET:
    lea rdi, [buffer+4] # get file name
    movb [rdi+16], 0
    mov rsi, 0 # O_RDONLY
    mov rax, 2 
    syscall
    mov file, rax

    mov rdi, file
    lea rsi, filecontent
    mov rdx, 1024
    mov rax, 0 
    syscall
    mov filecnt, rax 
    mov rdi, file
    mov rax, 3
    syscall

    # Write ("HTTP/1.0 200 OK\r\n\r\n", 19) = 19
    mov rdi, tunnel
    lea rsi, response
    mov rdx, 19
    mov rax, 1
    syscall

    mov rdi, tunnel
    lea rsi, filecontent
    mov rdx, filecnt
    mov rax, 1 
    syscall

    jmp exit

POST:
    lea rdi, [buffer+5] # Get file name
    movb [rdi+16], 0
    mov rsi, 0x41 # O_WRONLY | O_CREAT
    mov rdx, 0777
    mov rax, 2 
    syscall
    mov file, rax

    mov rcx, 0
    mov ebx, separate
CONTENT:
    mov eax, [buffer+rcx]
    add rcx, 1
    cmp eax, ebx
    jne CONTENT

    add rcx, 3
    mov rdi, file
    lea rsi, [buffer+rcx]
    mov rdx, bufferlen
    sub rdx, rcx
    mov rax, 1 
    syscall

    mov rdi, file
    mov rax, 3
    syscall

    mov rdi, tunnel
    lea rsi, response
    mov rdx, 19
    mov rax, 1 
    syscall

exit:
    mov rdi, 0
    mov rax, 60 
    syscall

.section .data

buffer:  .space 1024
filecontent: .space 1024
bufferget: .ascii "GET "
bufferpost: .ascii "POST"
separate: .ascii "\r\n\r\n"
response: .ascii "HTTP/1.0 200 OK\r\n\r\n"
sockaddr: .quad 0x50000002
          .quad 0x0
          .quad 0x0
          .quad 0x0
sockfd:   .quad 0
tunnel:   .quad 0
file:  .quad 0
filecnt:  .quad 0
bufferlen: .quad 0