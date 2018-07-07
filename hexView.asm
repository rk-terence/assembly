comment #
    Author: Terence
    email: rkterence@zju.edu.cn
    This program can serve as a hex viewer of a file.
    It can view the hexadecimal format of a file, which is closest to what the file 
really is. You can view it as 010Editor or QuickView or something else (Definitely 
the utilities of this program is very limited, as it cannot help you change the file,
you can only view it.)
    Control keys: PgUp, PgDn, Home and End
#
.386
data segment use16
info db "Please input filename:", 0Dh, 0Ah, "$"
error_info db "Cannot open file!", 0Dh, 0Ah, "$"
buf db 256 dup(0)  ;The buffer that store 256 bytes at most 
                    ;for the file to be read
rowstr db "00000000:            |           |           |                             "
rowstr_pattern db "00000000:            |           |           |                             "
        ;This is the output str format for a row
char_table db "0123456789ABCDEF"; This table stores the character representatives of 
                                ; 0 - 16 in ASCII coding.
filename db 100, 101 dup(0)  ; file to open. The first two bytes are the information
                             ; about the length and the maximum length of this str.
handle dw -1  ;The handle for the file
file_size dd 0
file_offset dd 0
bytes_in_buf dw 0
bytes_on_row db 0
rows db 0  ; The number of rows of a specific page
data ends

code segment use16
assume cs:code, ds:data
main:
    mov ax, data
    mov ds, ax
output_info:
    mov ah, 9
    mov dx, offset info
    int 21h
input_filename:
    mov dx, offset filename
    mov ah, 0Ah
    int 21h
adjust_filename_string:  ; change the last element from '\n' to '\0'
    movzx bx, byte ptr filename[1]
    mov byte ptr filename[bx+2], byte ptr 0
openfile:
    stc  ; make CF 1 so that the default status is open failure
    mov ah, 3Dh
    mov al, 0  ; READ ONLY
    mov dx, offset filename
    add dx, 2  ; The first address of the filename address. This may be improved.
    int 21h
    mov handle, ax
    ;
    jnc determine_filesize
error_open_failed:
    ; Display error message
    mov ah, 9
    mov dx, offset error_info
    int 21h
    ; exit the program
    jmp exit
determine_filesize:
    ; file_size = lseek(handle, 0, 2)
    mov ah, 42h
    mov al, 2  ; EOF is the start point
    mov bx, handle
    mov cx, 0
    mov dx, 0
    int 21h
    ;
    mov word ptr file_size[2], dx
    mov word ptr file_size[0], ax
again:
    ; Check to see whether this page have full bytes
    mov eax, dword ptr file_size
    sub eax, dword ptr file_offset  ; eax = file_size - file_offset
    cmp eax, 256
    jb less_than256
not_less_than256:
    mov bytes_in_buf, word ptr 256
    jmp lseak 
less_than256:
    mov bytes_in_buf, ax  ; bytes_in_buf = file_size - file_offset
lseak:
    ; lseek(handle, file_offset, 0): to move the file pointer to the current 
      ;offset
    mov ah, 42h
    mov al, 0  ; The 0 offset is the start point
    mov bx, handle
    mov cx, word ptr file_offset[2]
    mov dx, word ptr file_offset[0]
    int 21h
read_to_buf:
    ; _read(handle, buf, bytes_in_buf): to read the bytes into the global variable "buf"
    mov ah, 3Fh
    mov bx, handle
    mov cx, bytes_in_buf
    mov dx, offset buf
    int 21h
show_this_page:
    call clear_this_page  ; function: clear this page
    mov ax, bytes_in_buf
    ;
    add ax, 15
    shr ax, 4  ; ax = ax / 4
    mov rows, al  ; rows = (bytes_in_buf + 15) / 16
    mov cx, 1  ; cx stores the current row in this page.  
    mov di, 0  ; For each page, di will turn to zero to restart the reading form buf
again_printpage:
    mov bytes_on_row, byte ptr 16
    movzx ax, rows  ; ax = rows
    cmp cx, ax
    ; If this is the last row, calculate bytes_on_row
    jne show
    mov ax, bytes_in_buf
    movzx bx, rows
    dec bx
    shl bx, 4  ; bx = (rows-1) * 16
    sub ax, bx
    mov bytes_on_row, al  ; bytes_on_row = bytes_in_buf - (rows-1) * 16
show:
    ; write the bytes in array buf
    push cx
    push di
    call write_row_str
    add sp, 2
    ; the call of print_this_row
    push cx
    call print_this_row
    add sp, 2
    ;
    inc cx
    movzx ax, bytes_on_row
    add di, ax  ; get the first index of the first element of the next row in buf
    movzx ax, rows
    inc ax  ; ax = rows + 1
    cmp cx, ax  ; check if this is the last row
    jne again_printpage
bioskey:
    mov ah, 0
    int 16h
    ; Judge the key input - 
    cmp ax, 04900h
    je PageUp
    ;
    cmp ax, 05100h
    je PageDown
    ;
    cmp ax, 04700h
    je Home
    ;
    cmp ax, 04F00h
    je Endkey
    ;
    jmp loop_flag
PageUp:
    sub file_offset, dword ptr 256
    cmp file_offset, dword ptr 0
    jnl loop_flag
offset_less_than_0:
    mov file_offset, 0
    jmp loop_flag
PageDown:
    add file_offset, dword ptr 256
    mov eax, dword ptr file_size
    cmp file_offset, eax
    jb loop_flag
offset_no_less_than_filesize:
    sub file_offset, dword ptr 256
    jmp loop_flag
Home:
    mov file_offset, dword ptr 0
    jmp loop_flag
Endkey:
    mov eax, file_size
    mov ebx, eax  ; ebx = eax
    and ebx, 000000FFh  ; ebx = ebx % 256
    mov eax, file_size
    sub eax, ebx  ; eax = file_size - filesize % 256
    mov file_offset, eax
loop_flag:
    cmp ax, 011Bh
    je close_file
    jmp again
close_file:
    mov ah, 3Eh
    mov bx, handle
    int 21h
exit:
    mov ah, 4Ch
    int 21h

;----------------------------------------------------
;Below are the functions called in this program
;----------------------------------------------------

;---------clear_this_page----------------
;This function can clear this page using es == 0B800h
clear_this_page:
    push cx
    push es
    push di
    ;
    mov ax, 0B800h
    mov es, ax
    ; stosb to fill the RAM
    mov cx, 16*80
    mov ax, 0020h
    mov di, 0
    rep stosw
    ;
    pop di
    pop es
    pop cx
    ret
;---------write_row_str---------------
;   Input:     16-bit - the current row number
;              16-bit - the start index of buf for this row.
;   PREREQUISITES:
;              1. global variable: rowstr, buf.
;   This function can fill rowstr(global variable) according to buf.
;The current row number and the start index of buf should be pushed
;into stack before this operand.
write_row_str:
    push bp
    mov bp, sp
    push cx
    push si
    push di
    ;strcpy(rowstr_pattern, rowstr)
    mov cx, 75
    ;
    mov ax, ds
    mov es, ax  ; ds = es
    ;
    mov di, offset rowstr
    mov si, offset rowstr_pattern
    push cx
    shr cx, 2  ; ecx = ecx / 4
    rep movsd
    pop cx
    and cx, 3  ; ecx = ecx % 4
    rep movsb
write_address:
    mov si, 0
    mov eax, file_offset
    mov cx, [bp+6]
    dec cx  ; cx = cx - 1
    shl cx, 4  ; cx = cx * 16
    movzx ecx, cx
    add eax, ecx  ; eax = (cx-1)*16 + file_offset
write_address_again:
    rol eax, 8
    push eax  ; protect eax before [and] operation
    and eax, 0FFh
    ; The call of function char2hex:
    push ax
    push si
    call char2hex
    add sp, 4
    ;
    add si, 2
    pop eax
    cmp si, 8  ; if si<8, continue writing the addr
    jne write_address_again
write_hex:
    movzx cx, bytes_on_row  ; cx will control the number of write hex
    add si, 2  ;  si = 10
    mov di, [bp+4]
write_hex_again:
    movzx ax, byte ptr buf[di]
    ;
    push ax
    push si
    call char2hex
    add sp, 4
    ;
    add si, 3
    inc di
    dec cx
    cmp cx, 0  ; if the element reached bytes_on_row before
                          ; si reaches 58, go to the next part
    jne write_hex_again 
write_ascii:
    ; 59 is the start index of the last part of a row
    lea di, rowstr[59]
    mov si, [bp+4]
    lea si, buf[si]
    ;
    movzx cx, bytes_on_row
    rep movsb
    ;
    pop di
    pop si
    pop cx
    pop bp
    ret
;---------print_this_row---------------
;   INPUT: 16-bit - the current row number
;   PREREQUISITION:  global variable row_str appropriately set 
;   This function can print rowstr to the screen after the implementation
;of write_rowstr
print_this_row:
    push bp
    mov bp, sp
    push bx
    push si
    push di
    ;
    mov ax, 0B800h
    mov es, ax  ; make es point to the video card
    ; to get the offset of this row in VIDEO DISPLAY
    ; bx = (ax - 1) * 160
    mov eax, 0
    mov ax, [bp+4]
    dec ax
    shl ax, 4  ; ax = ax * 16
    lea eax, [eax + 4*eax]  ; ax = ax * 80
    lea eax, [eax * 2]  ; ax = ax * 2
    mov bx, ax
    ;
    mov si, 0
    mov di, 0
print_this_row_again:
    mov al, rowstr[si]
    mov es:[bx+di], al  ; es:[di] = rowstr[si]
    inc di  ; ready to print the color for the pixel
    cmp si, 59
    jae white_foreground
bright_white_foreground:
    cmp rowstr[si], '|'
    jne white_foreground
    mov es:[bx+di], byte ptr 0Fh
    jmp finish_this_pixel
white_foreground:
    mov es:[bx+di], byte ptr 07h
finish_this_pixel:
    inc di
    inc si
    cmp si, 75  ; Totally 75 elements 
    jne print_this_row_again
finish_print_this_row:
    pop di
    pop si
    pop bx
    pop bp
    ret
;---------char2hex---------------
;   Input: 
;       16-bit -  the char value to be transformed
;       16-bit -  the first index of the two elements in rowstr
;   Output: None, but this can write the transferred hex character into
;      row_str(global variable).
char2hex:
    push bp
    mov bp, sp
    push si
    push bx
    push cx
    ;
    mov cx, 2
    mov si, [bp+4]
    mov bx, [bp+6]
char2hex_again:
    rol bl, 4
    push bx
    and bl, 0Fh 
    mov bl, char_table[bx]
    mov rowstr[si], bl
    pop bx
    dec cx
    inc si
    cmp cx, 0
    jne char2hex_again
    ;
    pop cx
    pop bx
    pop si
    pop bp
    ret
code ends
end main