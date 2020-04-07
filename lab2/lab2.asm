.model tiny

IN_STATE equ 1
OUT_STATE equ 2 

TRUE equ 1
FALSE equ 0

print_message macro output_string
    mov ah, 9h
    mov dx, offset output_string
    int 21h
endm

enter_string macro input_string
    mov ah, 0ah
    mov dx, offset input_string
    int 21h
endm

.code
.org 0x100

start:
    
    print_message start_message
    enter_string in_string_1
    
    print_message find_message
    enter_string in_string_2
 
    print_message insert_message
    enter_string in_string_3
           
    xor bx, bx
    
skip_spaces:
    cmp byte ptr str[bx], ' '
    jne main_loop                       ; if != 0 
    inc bx
    jmp skip_spaces
    
main_loop:
    cmp bl, byte ptr [str_len]
    jae after_main_loop                 ; if higher or == 0
    
    cmp byte ptr str[bx], ' '           ; while no spaces
    jne _false                          ; if != 0
_true:
    mov byte ptr [word_end], bl         ; if space
    mov byte ptr [state], OUT_STATE
    
    mov al, [word_end]
    sub al, [word_start]
    cmp al, [w1_len]
    jne main_loop_end
    
    ; STRNCMP 1
    ; strncmp &str[word_start], w1, w1_len  
    mov dl, TRUE
    xor ax, ax
    mov al, byte ptr [word_start]
    mov si, ax ; index into str
    mov di, 0  ; index into w1
    mov cl, [w1_len]
strncmp_loop1:
    cmp cl, 0
    je after_strncmp1
    mov al, str[si]
    cmp al, w1[di]
    jne strncmp_not_equal1
    inc si
    inc di
    dec cl
    jmp strncmp_loop1
strncmp_not_equal1:
    mov dl, FALSE
       
after_strncmp1:
    cmp dl, TRUE
    jne main_loop_end
    mov [found], TRUE         
    jmp after_main_loop 
     
_false:
    cmp byte ptr [state], OUT_STATE         ; if out of word
    jne main_loop_end
    mov [state], IN_STATE                   ; if in word
    mov [word_start], bl    
    
main_loop_end:
    inc bx
    jmp main_loop
    

after_main_loop:
    mov [word_end], bl
    
    cmp bl, [str_len]
    jne final_check                    ; if != 0
    
    ; STRNCMP 2
    ; strncmp &str[word_start], w1, w1_len  
    mov dl, TRUE
    xor ax, ax
    mov al, byte ptr [word_start]
    mov si, ax ; index into str
    mov di, 0  ; index into w1
    mov cl, [w1_len]
strncmp_loop2:
    cmp cl, 0
    je after_strncmp2
    mov al, str[si]
    cmp al, w1[di]
    jne strncmp_not_equal2
    inc si
    inc di
    dec cl
    jmp strncmp_loop2
strncmp_not_equal2:
    mov dl, FALSE
       
after_strncmp2:
    cmp dl, TRUE
    jne final_check
    mov [found], TRUE         
    
final_check:
    cmp [found], TRUE
    jne endd
    
    xor cx, cx
    mov cl, [str_len]
    add cl, [w2_len]   ; insert len
    cmp cl, 200 ; max allowed str len
    ja not_enough_spase
    
    xor cx, cx
    mov cl, [str_len]
    sub cl, [word_start]
    inc cl
    
    xor ax, ax
    mov al, byte ptr [str_len]
    add ax, offset str
    mov si, ax ; end of str
    
    xor ax, ax
    mov al, byte ptr [str_len]
    add al, [w2_len]
    inc al
    add ax, offset str
    mov di, ax ; end of shifted shring
    
    std ; backward traversal of string  (set DF)
    rep movsb
    
    xor cx, cx
    mov cl, [w2_len]     ; insert len
    inc cl
    cld          ; unset DF
    mov di, si
    inc di
    mov si, offset w2
    rep movsb
    dec di
    mov [di], ' '
    
    xor bx, bx
    mov bl, byte ptr [word_start]
    add bl, byte ptr [w2_len]           
    add bl, byte ptr [w1_len]           
    inc bx
    
    ; update string length
    mov cl, [w2_len]
    inc cl
    add byte ptr [str_len], cl
    
    cmp bl, byte ptr [str_len]
    jae print_final_string
    mov byte ptr [word_start], 0
    mov byte ptr [word_end], 0
    mov byte ptr [found], FALSE
    mov byte ptr [state], OUT_STATE
 
    jmp skip_spaces
 
print_final_string:    
    jmp endd

not_enough_spase:
    print_message error_message 
    jmp $
        
endd:
    print_message result_message
    
    mov ah, 40h        ; output string
    mov bx, 1          ; stdout
    mov dx, offset str
    xor cx, cx
    add cl, [str_len]
    int 21h
      
     jmp $

word_start db 0
word_end db 0
found db FALSE
state db OUT_STATE    
    
in_string_1 db 201   
str_len db 0
str db 200 dup(0)
  
in_string_2 db 21  
w1_len db 0
w1 db 20 dup(0)
           
in_string_3 db 21           
w2_len db 0
w2 db 20 dup(0)

start_message db "ENTER STRING: ", '$'
find_message db 0ah, 0dh, "ENTER WORD TO FIND: ", '$'
insert_message db 0ah, 0dh, "ENTER WORD TO INSERT: ", '$'
error_message db 0ah, 0dh, "ERROR. NOT ENOUGH SPACE", '$'
result_message db 0ah, 0dh, "RESULT STRING:", '$'
    
end start
