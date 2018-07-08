comment #
    Author: Terence
    Email: rkterence@zju.edu.cn
    This program can show character 'T' on the screen. The feature
is that it uses int8, and every 1/18 second, one more 'T' will be filled
on the console, until the screen is full of 'T's, when you can press any
key to terminate the program.
#
code segment
assume cs:code
old8h dw 0, 0
main:
change_int8h:
    xor ax, ax
    mov ds, ax
    mov bx, 8*4
    push word ptr [bx]
    pop old8h[0]
    push word ptr [bx+2]
    pop old8h[2]
    ; change the ISR
    cli
    mov word ptr [bx], offset int8h
    mov [bx+2], cs
    mov ax, 0B800h
    mov es, ax
    mov cx, 2000
    ;
    mov al, 'T'
    mov ah, 71h
    mov di, 0
    sti
wait_for_int8:
    cmp cx, 0
    jnz wait_for_int8
    
    ; getchar()
    mov ah, 01h
    int 21h
    ; exit
    mov ah, 4Ch
    int 21h
int8h:
    stosw
    dec cx
    jmp dword ptr old8h
code ends
end main