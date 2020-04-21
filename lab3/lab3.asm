 .model small
.stack 100h

.data
 
minus_flag                     db 0
minus_flag_max                 db 0
minus_flag_min                 db 0
 
accuracy                       dw 6
            
num_10	                    dw	10
b_num_10                    db 10

MaxArrayLength              equ 30 
Array                       dw  MaxArrayLength dup (0)           

sk db 0Ah, 0Dh, '$'             

MinEl                       dw  ?
MaxEl                       dw  ?

div_0_str                   db 0Ah, 0Dh, 'Error! You cant divide by 0!$'
                            
ArrayLength                 db  ?
InputArrayLengthMsgStr      db  0Dh,'Input array length [2-30]: $'
tmp                         db  ?


InputMsgStr                 db  0Dh,'Element['    
CurEl1                      db  48 
CurEl2                      db  48
InputMsgStr_2               db  '] - $'                            

Task                        db 0Ah,0Dh,'Result ((Max-Min)/Max) = $'
ErrorInputMsgStr            db 0Ah, 0Dh,'Error! Incorrect input!' ,0Ah,'$'  
.code
 
mov ax, @data
mov ds, ax                          
                                                                                                     
;*********************[input array length]**********************         
                 
input_array_length proc    
    
    call arr_length_mess 	
    call inp_length 		
         
endp                                             


; output "Input array length [2-30]:"
arr_length_mess proc         
    xor bx, bx 				
    mov ah, 09h 			 
    lea dx, InputArrayLengthMsgStr
    int 21h 		
    ret 
endp   


; input number of length
inp_length proc
    
    mov ah, 01h 				
	int 21h 	    	
	cmp al, 0dh 	        ; if we have '\r'		
	je  push_to_arr_len		; push length number 
	jmp isNum 		        ; else - check value	
  next: ; translate ascii-code
	sub al,'0' ; num and symbol of num are different with code '0'		
	xor ah, ah					
	mov cx, ax				
	xor ax, ax				 
	mov ax, bx						 				
	mul num_10				
	add ax, cx				 
	mov bx, ax 				
	jmp check_arr_length 	
endp

; check value between [0 - 9]
isNum proc
    cmp al, '0'				
    jae nx					
    jmp errorArrLength		
  nx:
    cmp al, '9'				
    jle next				
    jmp errorArrLength		
endp  

     
; check array length
check_arr_length:
    mov cx, MaxArrayLength 	
	cmp bx, cx				
 	jle inp_length ; if less or equal	
 	jmp errorArrLength 		
                   

; push length number to current array                    
push_to_arr_len:			
    cmp bx, 1 ; check if array <= 1					
    jle errorArrLength		
    mov ArrayLength, bl		
    mov tmp, bl				
    jmp inp_array_of_shorts	; for input element nums
                              
       
       
;*******************[input array]*******************        
       
                     

inp_array_of_shorts proc 
    xor si, si				
    call inp_num			
endp
                         
                         
                         
;**********************[stop]***********************    
                
print_arr_index:  
    mov ah, 09h
    lea dx, sk				
    int 21h  ; '\n', '\r'     
    
    mov ah,09h
    lea dx, InputMsgStr ; print 'Element[]'
    int 21h        
    
    add CurEl2, 1		
    cmp CurEl2, 58		
    je set_counter 
    			
    z:						
    jmp exe

set_counter:				
    add CurEl1, 1
    mov CurEl2, 48
    jmp z 
    				    
inp_num proc  
    jmp print_arr_index 	
  exe:                 
    xor bx, bx 				      
    xor dx, dx				
  loop2:               
    mov ah, 01h 				
	int 21h	; enter num in array	
	cmp al, 0dh 			
	je  mini_max ; jump when num is	entered and '\r'		
	cmp al, '-'	; check minus			
	je minus_check			
	jmp isNm ; check num				 
  nxt: ; translate ascii-code
	sub al,'0' ; num and symbol of num are different with code '0'
	xor ah, ah	
	mov cx, ax
	xor ax, ax
	mov ax, bx	 		 				
	mul num_10 
	jo error ; if OF = 1
	add ax, cx
	mov bx, ax
    jmp overflow_check 
endp     


; check overflow
overflow_check:				
    cmp bx, 32768
    ja error				
    jmp loop2

; value minus check
minus_check proc  
   test bx, bx 
   jnz error ; if ZF != 0  
   call set_minus_flag
   mov minus_flag, 1
   jmp loop2
endp

; set minus flag 
set_minus_flag proc
    push cx 				
    mov cl, minus_flag 		
    test cl, cl 			 												
    pop cx 					
    jnz error ; if ZF != 0 				
    ret  
endp 
 
; check value between [0 - 9]
isNm proc 
    cmp al, '0'
    jae nex
    jmp error
  nex:
    cmp al, '9'
    jle nxt
    jmp error   
endp

; push element num into array
push_to_arr proc 			
    add si, 2
    sub tmp, 1
    cmp tmp, 0 ; compare if we don't have more elements
    ja inp_num ; if we have more elements				
    jmp print_task ; else - print result
endp
     
     
;****************[find min and max]*****************    
mini_max proc 
                                                                                                        
    mov cl, minus_flag
    test cl, cl
    jz pos ; if ZF = 0
    neg bx                                                                                          
    er:
    jns error ; if SF = 0				
    jmp e_mm   
  pos:
    cmp bx, 32768
    je error ; if overflow  
  e_mm:
   cmp si, 0
   je setMinMaxEl ; if ZF = 1
   
   cmp bx, MinEl
   jle setMinEl ; 1 < 2
 
   cmp bx, MaxEl
   jge setMaxEl ; 1 > 2
 
   call push_to_arr  ; push element into array 
endp             

; set min and max element
setMinMaxEl:
    mov cl, minus_flag
    mov minus_flag_max, cl
    mov minus_flag_min, cl
    mov MinEl, bx 
    mov MaxEl, bx
    mov minus_flag, 0
    call push_to_arr

; set min element    
setMinEl:
    mov cl, minus_flag
    mov minus_flag_min, cl
    mov MinEl, bx
    mov minus_flag, 0
    call push_to_arr
 
; set max element 
setMaxEl:
    mov cl, minus_flag
    mov minus_flag_max, cl
    mov MaxEl, bx
    mov minus_flag, 0
    call push_to_arr

; print "Result ((Max-Min)/Max) = "       
print_task: 
    mov ah, 09h
    lea dx, Task
    int 21h
    jmp calculate 

;******************[output]********************* 

; push numbers to stack                           
push_num_to_stack proc
    push dx
    push bx
    mov bx, ax 
    mov bp, sp									
loop1:  .            
    cmp ax, 0
    je skip_actions
    div b_num_10    
    xor bx, bx
    mov bl, ah
    xor ah, ah
skip_actions:
    push bx 
    cmp al, 0
    je print_num 
    jmp loop1
print_num:   ; print numbers       
loop3:
    xor dx, dx  
    pop bx
    add bx, '0'
    mov ah, 02h ; output
    mov dl, bl
    int 21h
    cmp bp, sp
    jne loop3
    pop bx
    pop dx    
    ret
endp
 
;******************[divide]***********************  

calculate:                 
    mov ax, MaxEl  ; max el
    cmp ax, 0
    je err_div_0 ; if we divide by zero
    sub ax, MinEl  ; max el - min el
    call pr_div
    jmp end  


pr_div proc 
    push ax 
    push dx 
    push bx  
    mov bx, MaxEl  
    mov dl, minus_flag 
    cmp dl, minus_flag_max 
    jl sing_div ; if <             
    
; divide without sign   
unsing_div: 
    div MaxEl 
    call push_num_to_stack 
    test dx, dx 
    jz pr_div_end ; if ZF = 0
    mov ax, MaxEl 
    call ost_output 
    jmp pr_div_end 

; divide with sign   
sing_div: 
    push ax
    push dx
    
    ; display output
    mov ah, 02h
    mov dx, '-'
    int 21h
    
    pop dx
    pop ax
    
    neg bx
    idiv bx 
    call push_num_to_stack  
    test dx, dx 
    jz pr_div_end ; if ZF = 0
    mov ax, MaxEl
    cmp minus_flag_max, 0h 
    jz pr_div_ost_unsign ; if ZF = 0
    neg ax   

; dividing without sign output    
pr_div_ost_unsign: 
    call ost_output 
    jmp pr_div_end 

; end dividing   
pr_div_end: 
    pop bx 
    pop dx 
    pop ax 
    ret 
endp 

; output '.'
ost_output proc 
    push ax 
    push dx 
    push cx 
    push dx 
    mov bx, ax 
    mov ah, 2h  ; output
    mov dl, '.'   ; 0.0
    int 21h 
    pop dx 					
    mov cx, accuracy    
; output numbers after '.'    
ost_cycle:             
    mov ax, dx 				
    mul num_10 				
    div bx 
    push dx 
    mov dx, ax 
    mov ah, 2h 
    add dx, '0' 
    int 21h 
    sub dx, '0' 
    pop dx 
    cmp dx, dx 
    loopz ost_cycle     
ost_end: 
    pop cx 
    pop dx 
    pop ax 
    ret 
endp   

;*****************[errors]*****************  

errorArrLength: ; error incorrect array length
    mov ah, 09h
    lea dx, ErrorInputMsgStr
    int 21h
    jmp input_array_length 
 
error: ; error incorrect input
    mov ah, 09h
    lea dx, ErrorInputMsgStr
    int 21h
    sub CurEl2, 1 
    mov minus_flag, 0
    jmp inp_num
    
err_div_0:  ; error dividing by zero
    mov ah, 09h
    lea dx, div_0_str
    int 21h
    jmp end 
    
;******************[exit]*****************
end: 
    mov ax, 4c00h
    int 21h