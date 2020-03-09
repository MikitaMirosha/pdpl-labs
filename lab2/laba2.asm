.MODEL TINY   
.STACK 100H           
.CODE      		
   
START:
    MOV AX,@DATA	   
    MOV DS,AX		   
              
    LEA DX,base_message	   
    CALL output_string	   

    LEA DX,base_string	   
    CALL input_string	   
            
    LEA DX,find_message    
    CALL output_string	   	

    LEA DX,find_string	   
    CALL input_string	   
     
    LEA DX,insert_message   
    CALL output_string	   

    LEA DX,insert_string   
    CALL input_string       
                        
    XOR AX, AX	           
    XOR DX, DX 		   
                       
    MOV AL, base_string[1]         
    CMP AX, 0	              
    JE error                 
    
    MOV DL, insert_string[1]  
    CMP DX, 0	              
    JE error 		      
    
    XOR DX, DX  	      

    MOV DL, find_string[1]   
    CMP DX, 0                 
    JE error                  
   
    MOV SI, OFFSET base_string + 2		
    MOV DI, OFFSET find_string + 2		
    
    SUB AL, DL   			
      
    XOR CX, CX				
    MOV CL, AL				
    INC CX			
    	
SEARCH:   				
    ;PUSHA 
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH BX 
    PUSH BP
    PUSH SI
    PUSH DI                    
    XOR CX, CX  			
    MOV CX, DX 				
    REPE cmpsb                          
    JZ found 				
    ;POPA	
    POP DI
    POP SI
    POP BP
    POP BX
    POP DX
    POP CX
    POP AX		  
    INC SI
 				        
LOOP SEARCH				
 
    MOV AH,9				
    LEA DX, not_found_message                       
    INT 21H 				
    INT 20H		      
    
    ;-------
    error:

    LEA DX, error_message   		
    CALL output_string			
    RET		
    ;-------
         
    found: 
        
    MOV CX, SI				
    SUB CX, OFFSET base_string + 2      
        
    XOR AX, AX			        
    MOV AL, find_string[1]		
   
    MOV SI, OFFSET insert_string + 2	
    SUB CX, AX          		 
   
    CMP CX, 0			       
    JZ first_word			
			
    PUSH CX				
        
    MOV DI, OFFSET result_string + 1    
    MOV SI, OFFSET base_string + 2     
                                        
    CALL copy_string                    
        
    PUSH SI                             
        
    XOR CX, CX				
    MOV CL, insert_string[1]	        
    MOV SI, OFFSET insert_string + 2	
        
    CALL copy_string			  
        
    XOR CX, CX                          
    MOV CL, 1			       
    MOV SI, ' '				
    CALL copy_string			
        
    POP SI      			
    POP CX				
    INC CX                             
    INC CX				
    CALL copy_string                    
        
    JMP res_in	
    							    
    first_word:   			

    XOR CX, CX				
    MOV CL, insert_string[1]		
    MOV DI, OFFSET result_string + 1     
    MOV SI, OFFSET insert_string + 2  	

    CALL copy_string     		

    XOR CX, CX          		
    MOV CL, 1				
    MOV SI, ' '				

    CALL copy_string      	        
       
    MOV CL, base_string[1]   		
    MOV SI, OFFSET base_string + 2 	

    CALL copy_string    	        
    res_in:      
    
    LEA DX, result_message   		
    CALL output_string			
    LEA DX, result_string+1		
    CALL output_string			 
    INT 20H							     
output_string PROC  
    ;PUSHA
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH BX 
    PUSH BP
    PUSH SI
    PUSH DI        			
    MOV DL, 0DH				
    MOV AH, 02H				
    INT 21H 				
    
    MOV DL, 0AH				
    MOV AH, 02H				
    INT 21H          			   
    ;POPA	
    POP DI
    POP SI
    POP BP
    POP BX
    POP DX
    POP CX
    POP AX	
    			
    MOV AH,9				
    INT 21H				
    
    RET    				
output_string ENDP    

input_string PROC         
    PUSH AX				
    MOV AH,0AH				
    INT 21H   				
    POP AX				
    RET 				
input_string ENDP            
					
copy_string PROC  
    PUSH AX  				
    CMP CX, 0				
    JZ end_copy   			   
    
    loop_string:  			
    MOV AX, [SI]			
    MOV [DI], AX 			
    INC SI				
    INC DI				
    LOOP loop_string			
   
    end_copy:        
    POP AX  				
    RET					
copy_string ENDP     

.DATA 
    base_message DB "ENTER BASE STRING: $" 
    find_message DB "ENTER THE WORD TO FIND IN THE BASE STRING: $"
    not_found_message DB "ERROR! THERE IS NO SUCH WORD IN THE STRING! $"    
    insert_message  DB "ENTER THE WORD TO INSERT IN THE BASE STRING: $" 
    result_message DB "RESULT STRING: $"  
    error_message DB "INPUT ERROR!!! $"
    base_string DB 202,202 DUP ('$')     
    find_string DB 202,202 DUP ('$')               
    insert_string DB 202,202 DUP ('$') 
    result_string DB 202,202 DUP ('$')         
END START                  