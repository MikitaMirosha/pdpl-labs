.model  small 
.stack  100h
 
.data
        msgPressAnyKey  db      0Dh, 0Ah, "ENTER ANY KEY TO EXIT...", '$'
        errFileOpenRd   db      "FILE OPEN READING ERROR", '$'
        errFileOpenWr   db      "FILE OPEN WRITING ERROR", '$'
        errFileClose    db      "FILE CLOSE ERROR", '$'
        msgResult       db      "STRINGS: ", '$'
        FileName        db      80 dup(0)
        buf             db      0
        nCount          dw      1  ;amount of strings
.code 

get_name proc
    push ax 
    push cx
    push di
    push si
    xor cx, cx
    mov cl, es:[80h]    ;amount of symbols in cmd line
    cmp cl, 0
    je end_get_name
    mov di, 81h         ;offset of cmd line in PSP block
    lea si, FileName    ;load file name in si
cicle1:
    mov al, es:[di]     ;load in AL the value of of cmd line char by char
    cmp al, 0Dh         ;enter 
    je end_get_name
    mov [si], al        ;load symbol from cmd line in file name 
    inc di              ;for next symbol
    inc si            
    jmp cicle1 
end_get_name:        
    pop si          
    pop di
    pop cx
    pop ax   
ret
get_name endp 
 
;show unsigned int 16th digit
ShowUInt16       proc
        mov     bx,     10      ;divider (base of counting system)
        mov     cx,     0       ;amount of entering numbers
divide:
        xor     dx,     dx      ;divide (dx:ax) on bx
        div     bx
        add     dl,     '0'     ;convert remainer of dividing
        push    dx              ;save in stack
        inc     cx              ;inc counter of numbers
        test    ax,     ax      ;if we still have numbers
        jnz     divide          ;repeat  
        
show:
        mov     ah,     02h     ;show number
        pop     dx              
        int     21h             
        loop    show          
        ret
ShowUInt16       endp
 
main    proc
        mov     ax,     @data                   
        mov     ds,     ax 
        call    get_name     
        mov     ah,     3Dh  ;open file
        mov     al,     00h     
        lea     dx,     [FileName]
        int     21h
        jnc     continue     ;if not carriage
        mov     ah,     09h
        lea     dx,     [errFileOpenRd]
        int     21h
        jmp     Exit 

continue:
        mov bx, ax
        m_loop:
            mov ah, 3Fh    ;read file
            mov cx, 1
            mov dx, offset buf
            int 21h
            cmp ax, 0
            je break
            cmp buf, 0Ah   ;cmp with new line
            jne m_loop
            inc nCount     ;inc amount of strings
            jmp m_loop
                              
break:
        mov     ah,     3Eh   ;close file descriptor
        int     21h
        jnc     ShowResult
        mov     ah,     09h
        lea     dx,     [errFileClose]
        int     21h             
        
ShowResult:
        ;RESULT:
        mov     ah,     09h                     
        lea     dx,     [msgResult]
        int     21h
        mov     ax,     [nCount]
        call    ShowUInt16   
        
Exit:                                         
        ;waiting for any key
        mov     ah,     09h
        lea     dx,     [msgPressAnyKey]
        int     21h
        mov     ah,     00h
        int     16h
 
        ;exit the program
        mov     ax,     4C00h
        int     21h
main    endp
 
end     main