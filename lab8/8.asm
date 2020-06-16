 .model tiny  
.286
Code SEGMENT
Assume CS: Code, DS: Code
org 100h  
resprog:jmp main
     
key             dw 5555h
num			    dw 0
counter			dw 0 
delay 			dw 0  
symbol			db 016h, 00000110b  
screen			dw 2000 dup('$')

oldTimerOffset          dw ?  
oldTimerSegment         dw ?    
oldKeyboardOffset       dw ?
oldKeyboardSegment      dw ?
flag db 0

newKeyboard proc far 
   push es
   push bx
   push cx
   push dx
   push si
   push di
   push ds
   push ax
   push cs
   pop ds
   
;set register DS for data of resident program
resid:
    pushf   ;saving flags
    call dword ptr cs:oldKeyboardOffset ;call old interrupt for keyboard
    
    mov ah, 01h   ;tap keyboard
    int 16h
    jz showScreen ;check buffer content

    cmp ah, 01h   ;check esc
    je reinstallInterrupt  

    showScreen:
        mov ax, delay
        cmp counter, ax
        jl endOfKeyboard
        mov ax, 0B800h ;video memory
        mov es, ax 
	    mov di, 0000h
        mov ax, 0500h  ;set zero page
        int 10h	
        mov di, 0
	    mov cx, 4000 ;write in video memory the saved screen
	    lea si, screen
	    rep movsb
        cmp flag, 1  ;flag is set
        jne endOfKeyboard
        push cs
	    pop  es
	    mov ah, 49h  ;free memory
	    int 21h

    endOfKeyboard:
        mov counter, 0 
        pop ax
	    pop ds
        pop di
	    pop si
	    pop dx
	    pop cx
	    pop bx
	    pop es  
        iret 
         
    reinstallInterrupt:
        mov flag , 1
        mov ds, word ptr cs:oldTimerSegment   ;set old time interrupt
        mov dx, word ptr cs:oldTimerOffset
        mov ax, 2508h   ;return old handler
        int 21h 
        mov ds, word ptr cs:oldKeyboardSegment  ;set old keyboard interrupt
        mov dx, word ptr cs:oldKeyboardOffset
        mov ax, 2509h   ;return old handler
        int 21h
        push cs
        pop ds
        jmp showScreen   
    endp  

newTimer proc far 

   push es
   push bx
   push cx
   push dx
   push si
   push di
   push ds
   push ax
   push cs
   pop ds 

;set register DS for data of resident program

   inc counter
   mov ax, delay  
   cmp counter, ax
   je cont
   jmp endOfTimer 
    
cont:
   mov ax, 0B800h ;video memory
   mov es, ax
   xor bx, bx
   xor di, di

saveScreen: 
    mov ax, es:[di]
	mov [screen+di], ax
	add di, 2
	cmp di, 4000
    jl saveScreen
    mov ax, 0B900h
    mov es, ax    ;load video memory address
   	mov ax, 0501h ;flip pages (01h - select display page 1, 05h - select active display page)  
    int 10h
	xor di, di
	mov cx, 2000

fillScreen:   ;fill the screen
    push cx   
    mov cx, 2 
    mov si, offset symbol
    rep movsb 
    pop cx
	sub cx, 1
    cmp cx, 0
    jne fillScreen  ; if not zero

endOfTimer:
    pop ax  
    pop ds
    pop di
	pop si
	pop dx
	pop cx
	pop bx
    pop es  
    jmp dword ptr cs:oldTimerOffset   ; old timer offset
endp

main: 
    call getCmd
    call checkCmd
    call makeNum
    call set_interrupt
    
printString macro string  
    lea dx, string
    mov ah, 09h
    int 21h
endm 

exit proc  
    mov ax, 4C00h
    int 21h 
    ret
endp

set_interrupt proc near
    push es 
    push ds
    push cs
    pop ds
 
;checking for re-installation of the program (comparing with key)
    mov ax, 3508h                       ;request function 35h
    int 21h                             ;get vector for timer (interrupt 08)
    cmp word ptr es:[103h], 5555h       ;compare with key resident 5555h
    jz inst                             ;if zero
    mov word ptr oldTimerOffset, bx     ;save offset and segment address of old handler
    mov word ptr oldTimerSegment, es
    
    mov ax, 2508h       ;set new time handler
    mov dx, offset newTimer
    int 21h  
    
    mov ax, 3509h  ;read old vector of interrupt
    int 21h
    cmp word ptr es:[103h], 5555h ;compare with key resident 5555h
    jz inst

    mov word ptr oldKeyboardOffset, bx  ;save offset and segment address of old handler
    mov word ptr oldKeyboardSegment, es
    
    mov ax, 2509h     ;set new keyboard handler
    mov dx, offset newKeyboard
    int 21h

    mov dx, offset main ;main - address of first byte after resident space
    int 27h    ;to end, but to stay resident

    pop ds
    pop es
    ret

inst: 
    pop ds
    pop es
    mov ax, 0B800h  ;video memory
    mov es, ax
    mov ax, 0500h   ;set zero page
    int 10h
    printString bye
    mov ax, 4C00h
    int 21h     
endp

makeNum proc near 
  push di
  push dx

  lea si, cmdString  ;set string from command line
  lea di, num  

  xor dx, dx
  xor cx, cx
  xor ax, ax
  mov cl, cmd_len
  sub cx, 1

loop_:
    mul bx      ;multiply AX * 10 (if overflow - the extra part of data goes to DX)
    mov [di], ax
    cmp dx, 0
    jnz error 

    mov al, [si] 
    cmp al, '0'
    jb error
    
    cmp al, '9'
    ja error
    
    sub al, '0' ;sub symbol '0' in order to get number from symbol
    xor ah, ah
    add ax, [di]
    jc error      ;if flag CF = 0
    cmp ax, 8000h ;compare number sign/unsign
    ja error
    jmp endloop

endloop:
    inc si

loop loop_

;store resident
StoreRes:
    mov [di], ax
    mov bx, 18    ;interruption 18 times in second
    mul bx  
    jo checkOverflow
    mov delay, ax
    pop dx
    pop di
    ret

error:
   printString wrongArgs
   mov ax, 4C00h
   int 21h

checkOverflow:
   printString overflowString
   mov ax, 4C00h
   int 21h
endp makeNum  

;get command arguments
getCmd proc near
   mov ax, @data           
   mov es , ax   
   xor ch, ch	
   mov cl, ds:[80h]	
   cmp cl, 0 
   je emptyCommandLine	;amount of symbols of string in cmd line
   mov bl, cl
   dec cl               ;first symbol - space 
   mov cmd_len, cl		;load length of cmd line              		     
   mov si, 82h		    ;offset on parameter which is sent from cmd line
   lea di, cmdString
   rep movsb
   mov ds, ax		    ;load data in DS  
   mov cmd_len, bl
   ret

emptyCommandLine:
   printString emptyLine 
   mov ax, 4C00h
   int 21h
   ret
getCmd endp

;check cmd 
checkCmd proc near 
    lea si, cmdString 
    cmp byte ptr [si], 30h
    je checkFailed ;if ZF = 1 
    
    startOfCheck:
    cmp byte ptr[si], ' '
    je TooManyArgs  ;if ZF = 1
    cmp byte ptr [si], '$'
    je endOfCheck
    cmp byte ptr [si], 30h
    jl checkFailed  ;if SF < OF
    cmp byte ptr [si], 39h
    jg checkFailed  ;if >
    jmp checkPassed

    TooManyArgs:
    printString TooMany
    mov ax, 4C00h
    int 21h
    ret      
    
    checkFailed:
    printString wrongArgs
    mov ax, 4C00h
    int 21h 
    ret   
    
    checkPassed:
    inc si
    jmp startOfCheck 
     
    endOfCheck:  
    ret
endp 

cmdString		    db 80 dup('$') 
cmd_len			    db 0
emptyLine 		    db 13, 10, 'YOU DONT HAVE ANY PARAMETERS IN CMD$'
tooMany             db 0Ah, 0Dh, 'TOO MANY ARGUMENTS IN CMD$'   
wrongArgs           db 0Ah, 0Dh, 'BAD PARAMETERS IN CMD$'
overflowString      db 0Ah, 0Dh, 'VERY BIG NUMBER IN CMD$' 
bye			        db 0Ah, 0Dh, 'ALREADY LOADED IN CMD$'

Code ENDS
END resprog 