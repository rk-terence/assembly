comment #
    Author: RK Terence in Zhejiang University
    Email: rkterence@zju.edu.cn
    This program can print Fibonacci(n). At the start of
the program, you should input n, and then hit [RETURN].
#
code segment
assume cs:code
main:
    call near ptr getn
    ;
    push ax
    call near ptr fibo  ; ax = fibo(9)
    add sp, 2
    ;
    push ax
    call near ptr print_each_decbit
    add sp, 2
exit:
    mov ah, 4Ch
    int 21h
;=================================
;==return: ax, stack argument: n==
;=================================
fibo proc near
    push bp
    mov bp, sp
    push bx
    push dx
    ;
    mov bx, [bp+4]  ; bx = n
    cmp bx, 2
    ja recurse
less_than_three:
    mov ax, 1
    jmp fibo_return
recurse:
    dec bx
    push bx
    call fibo
    add sp, 2
    mov dx, ax
    ;
    dec bx
    push bx
    call fibo
    add sp, 2
    add dx, ax
    mov ax, dx
fibo_return:
    pop dx
    pop bx
    pop bp
    ret
fibo endp
;================print_each_decbit===================
;INPUT: the number to be printed (16-bit unsigned)===
;RETURN: none
;This program uses recursive method to print the number
;bit by bit
;====================================================
print_each_decbit proc near
    push bp
    mov bp, sp
    push bx
    push dx
    ;
    mov ax, [bp+4]
    cmp ax, 0
    jne not_zero
is_zero:
    jmp print_each_decbit_exit
not_zero:
    mov bx, 10
    mov dx, 0
    div bx  ; DX:AX / BX = AX ... DX
    ;
    push ax
    call print_each_decbit
    add sp, 2
    ;
    add dl, '0'
    mov ah, 2
    int 21h
print_each_decbit_exit:
    pop dx
    pop bx
    pop bp
    ret
print_each_decbit endp
;================getn===================
;INPUT: none
;RETURN: AX = n
;====================================================
getn proc near
    push bx
    push cx
    push dx
    mov bx, 0  ; bx will store n
getn_again:
    ; getchar()
    mov ah, 1
    int 21h
    ;
    cmp al, 0Dh
    je getn_return
    ;
    cbw
    sub ax, '0'
    push ax
    ; bx = dx + 10 * bx
    mov ax, bx
    mov cx, 10
    mul cx
    mov bx, ax
    pop ax
    add bx, ax
    jmp getn_again
getn_return:
    mov ax, bx
    ;
    pop dx
    pop cx
    pop bx
    ret
getn endp
code ends
end main