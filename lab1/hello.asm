.model tiny 
.code
org 100h
start: mov ah,9
       mov dx,offset message1
       int 21h   
       mov ah,9
       mov dx,offset message2
       int 21h
       mov ah,9
       mov dx,offset message3
       int 21h
       ret 
message1 db "Hello World!",0Dh,0Ah,'$'  
message2 db "Hi there!",0Dh,0Ah,'$'     
message3 db "Good evening!",0Dh,0Ah,'$'
        end start

                  


