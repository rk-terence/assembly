comment #
    Author: Terence
    Email:  rkterence@zju.edu.cn
    This program can get a buffer input. After getting the input,
it will start another line in the console, and then print the same 
string on the second line.
    What is worth mentioning is that this code uses the dynamic variable
inside an [echo] function. This is the specific way C compliers do.
#
code segment
assume cs:code
main:
    call near ptr echo
    ;
    mov ah, 4Ch
    int 21h
;====FUNCTION: echo=========
;====INPUT, OUTPUT: none====
;This function creates a local char string and simply
;print it again
echo proc near
    push bp
    push ds
    push dx
    push si
    mov bp, sp
    ;
    sub sp, 10100B  ; This creates a 20-byte space for a new
                ; string
    ;
    mov byte ptr [bp-20], 18
    mov ax, ss
    mov ds, ax
    ;
    lea dx, [bp-20]
    mov ah, 1010B
    int 21h
    ;
    mov al, byte ptr [bp-19]
    cbw
    mov si, ax
    mov byte ptr [bp+si-18], '$'
    ;
    mov ah, 01h
    int 21h
    ;
    mov ah, 09h
    lea dx, [bp-18]
    int 21h
    ;
    mov sp, bp
    ;
    pop si
    pop dx
    pop ds
    pop bp
    ret
echo endp
code ends
end main