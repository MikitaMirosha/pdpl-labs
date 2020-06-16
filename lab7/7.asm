.286
.model      small
.stack      100h

.data
    startMessage      db "CONSOLE PARAMETERS: ", '$'
    iterationsMsg     db "ITERATIONS COUNT: ", '$'
    fileMsg           db "FILENAME: ", '$'
    applicationError  db "APPLICATION START ERROR!", '$'
    stringMsg         db "STRING NUMBER: ", '$'
    negativeExit      db "ENTER CORRECT NUMBER!", '$'
    allocatingError   db "ALLOCATING MEMORY ERROR!", '$'
    startupError      db "STARTUP ERROR!", '$'
    badFileMessage    db "CANNOT OPEN FILE", 0dh, 0ah, '$'
    badArguments      db "BAD ARGUMENTS ERROR!", 0dh, 0ah, '$'
    fileError         db "ERROR OPENING FILE!", '$'
    badFileName       db "BAD FILE NAME!", '$'

    partSize          equ 256
    wasPreviousLetter dw 0
    realPartSize      dw 256
    descriptor        dw 0
    pointerPosition   dd 0
    path              db 256 dup('$')
    tempVariable      dw 0
    isEndl            db 0
    spacePos          dw 0
    base              dw 10
    iterations        dw 0
    stringNumber      dw 0
    parsingStep       dw 1
    endl              db 13, 10, '$'
    endlCounter       dw 0
    
    tempString        db 256 dup('$')
    fileName          db 256 dup(0)
    dtaBuffer         db 128 dup(0)
    applicationName   db 256 dup(0)
    part              db partSize dup('$')
    
    ;Exec Parameter Block (EPB) for funcion 4Bh (load and run program)
    env               dw 0
    cmd_off           dw ? 
    cmd_seg           dw ?
    fcb1              dd ?        ;address of FCB structure (37 bytes for file description)
    fcb2              dd ?
    Len               dw $ - env  ;EPB length

    dsize=$-startMessage          ;size of data segment 
.code

;printing string
printString proc  
    push    bp
    mov     bp, sp   
    pusha 
    mov     dx, [ss:bp+4+0]     
    mov     ax, 0900h
    int     21h 
    mov     dx, offset endl
    mov     ax, 0900h
    int     21h  
    popa
    pop     bp      
    ret 
endp

;output string
puts proc
    mov     ah, 9
    int     21h
    ret
endp

;bad file name
badFileNameCall proc
    lea     dx, badFileName
    call    puts
    call    exit
endp

exit proc
    mov     ax, 4c00h
    int     21h
endp

;bad range
badRange:
    lea     dx, negativeExit
    call    puts
    call    exit
ret

;convert to int
toInteger proc
    pusha        
    xor     di, di
    lea     di, path 
    xor     bx, bx     
    xor     ax, ax   
    xor     cx, cx
    xor     dx, dx
    mov     bx, spacePos
    
    skipSpacesInteger:
        cmp     [di + bx], byte ptr ' '
        jne     unskippingInteger
        inc     bx
        jmp     skipSpacesInteger
    
    unskippingInteger:
        cmp     [di + bx], byte ptr '-'
        jne     atoiLoop
        jmp     atoiError

    atoiLoop:        
        cmp     [di + bx], byte ptr '0'    
        jb      atoiError  
        cmp     [di + bx], byte ptr '9'    
        ja      atoiError                     
        mul     base            ;mul 10
        mov     dl, [di + bx] 
        jo      atoiError 
        sub     ax, '0'  
        jo      atoiError
        add     ax, dx 
        inc     bx 
        cmp     [di + bx], byte ptr ' '
        jne     atoiLoop  
        jmp     atoiEnd 
    
    atoiError:
        jmp     badRange

    atoiEnd: 
        mov     tempVariable, ax 
        mov     spacePos, bx
        inc     parsingStep
        cmp     tempVariable, 255
        jg      badRange
        cmp     tempVariable, 0
        je      badRange
        popa
        ret
endp

;convert to string
toString proc
    pusha
    xor     di, di
    lea     di, tempString
    mov     ax, tempVariable
    xor     bx, bx
    mov     bx, di
    xor     cx, cx
    mov     cx, 256
    setZeroString:
        mov     [di], byte ptr '$'
        loop    setZeroString
        lea     di, tempString
    itoaLoop:
        xor     dx, dx
        div     base  
        add     dl, '0'
        mov     [di], dl
        inc     di                   
        cmp     ax, 0
        ja      itoaLoop
        dec     di
        xor     si, si
        mov     si, bx 
    reverseMini:
        xor     dx, dx
        xor     cx, cx  
        mov     dl, byte ptr [si]  
        mov     cl, byte ptr [di]
        mov     [si], cl
        mov     [di], dl
        inc     si
        dec     di
        cmp     si, di
        je      reverseMini
        popa
        ret
endp

;app error
applicationStartError:
    lea     dx, applicationError
    call    puts
    call    exit
ret

;memory allocating
allocateMemory proc
    push    ax
    push    bx 
    mov     bx, ((csize/16)+1)+256/16+((dsize/16)+1)+256/16
    mov     ah, 4Ah   ;change size of memory block
    int     21h 
    jc      allocateMemoryError
    jmp     allocateMemoryEnd 
    allocateMemoryError:
        lea     dx, allocatingError
        call    puts
        call    exit    
    allocateMemoryEnd:
        pop     bx
        pop     ax
        ret
endp

;get iterations
getIterations proc
    pusha
    xor     ax, ax
    call    toInteger
    mov     ax, tempVariable
    mov     iterations, ax
    popa
    ret
endp

;load and run application
loadAndRun proc
    mov     ax, 4B00h      ;load and execute
    lea     dx, applicationName
    lea     bx, env
    int     21h
    jb      applicationStartError    ;if lower
    ret
endp

;file error call
fileErrorCall:
    lea     dx, fileError
    call    puts
    call    exit
ret

;get file name
getFilename proc
    pusha
    lea     di, path 
    xor     bx, bx     
    xor     ax, ax   
    mov     bx, spacePos
    skipSpacesString:
        cmp     [di + bx], byte ptr ' '
        jne     unskippingString
        inc     bx
        jmp     skipSpacesString
    unskippingString:
        lea si, fileName
    copyFilename:
        xor     ax, ax
        mov     al, [di + bx] 
        mov     [si], al
        inc     bx
        inc     si
        cmp     [di + bx], byte ptr '$'
        jne     copyFilename
        mov     spacePos, bx
        popa
        ret
endp

;get string number
getStringNumber proc
    pusha
    xor     ax, ax
    call    toInteger
    mov     ax, tempVariable
    mov     stringNumber, ax
    popa
    ret
endp

;get application name
getApplicationName proc
    pusha
    xor     ax, ax
    mov     dx, offset fileName
    mov     ah, 3Dh        ;open file
    mov     al, 00h
    int     21h
    mov     descriptor, ax
    mov     bx, ax
    jnc     readFilePart
    jmp     fileErrorCall;
    readFilePart:    
        mov     ah, 42h     ;set pointer of file (lseek)
        mov     cx, word ptr [offset pointerPosition]
        mov     dx, word ptr [offset pointerPosition + 2]
        mov     al, 0  
        mov     bx, descriptor
        int     21h
        mov     cx, partSize
        lea     dx, part
        mov     ah, 3Fh     ;read file with descriptor
        mov     bx, descriptor
        int     21h
        mov     realPartSize, ax
        call    searchApplicationName
        call    memset
        cmp     realPartSize, partSize
        jb      closeFile
        mov     bx, stringNumber
        cmp     endlCounter, bx
        je      closeFile
        mov     cx, word ptr [offset pointerPosition]
        mov     dx, word ptr [offset pointerPosition + 2]
        add     dx, ax
        adc     cx, 0
        mov     word ptr [offset pointerPosition], cx
        mov     word ptr [offset pointerPosition + 2], dx
        jmp     readFilePart
    closeFile:
    exitFromFile:
        mov     ah, 3Eh        ;close file
        mov     bx, descriptor
        int     21h
        popa
        ret
endp

;search application name
searchApplicationName proc
    pusha
    xor     si, si
    partParsing:
        call    checkEndl 
        mov     ax, stringNumber
        cmp     endlCounter, ax
        je      parseApplicationName
        cmp     isEndl, 0
        je      increment
        inc     endlCounter
        jmp     partParsingCycle
        increment:
            inc     si
        partParsingCycle:
            mov     isEndl, 0
            cmp     si, realPartSize
            jb      partParsing        ;if lower
            popa
            ret
    parseApplicationName:
        cmp     isEndl, 1
        jne     parseStart   
        call    badFileNameCall
        parseStart:
            lea     di, applicationName
            copyApplicationName:
                xor     ax, ax
                mov     al, [part + si]
                mov     [di], al
                inc     si
                inc     di
                cmp     [part + si], 0dh
                je      exitFromParsing
                cmp     [part + si], 0ah
                je      exitFromParsing
                cmp     si, realPartSize
                je      exitFromParsing
                jmp     copyApplicationName    
    exitFromParsing:
        popa
        ret
endp

;check endl
checkEndl proc
    mov     al, [part + si]
    xor     ah,ah
    cmp     al, 0dh
    je      checkNextSymbol
    cmp     al, 0ah
    jne     exitFromEndlCheck
    inc     si
    call    setIsEndl
    exitFromEndlCheck:
    ret
endp

;check next symbol
checkNextSymbol:
    call    setIsEndl
    mov     bl, [part + si + 1]
    xor     bh,bh
    cmp     bl, 0ah
    jne     exitFromCheck
    inc     si
    exitFromCheck:
        inc     si
ret

;set is endl (flag)
setIsEndl proc
    mov     isEndl, 1
    ret
endp

;memset
memset proc
    pusha
    xor     si, si
    lea     si, part
    mov     cx, partSize
    setEndCycle:
        mov     byte ptr [si], '$'
        inc     si
        loop    setEndCycle
        popa
        ret
endp

;bad arguments call
badArgumentsCall:
    lea     dx, badArguments
    call    puts
    call    exit
ret

;start
start proc
    call    allocateMemory
    mov     ax, @data        ;move data segment address in DS
    mov     ds, ax
    mov     bl, es:[80h]     ;length of com line
    add     bx, 80h          ;args line last (call kernel)   
    mov     si, 82h          ;args line start
    mov     di, offset path
    cmp     si, bx
    ja      badArgumentsCall ;if higher
    getPath:
        mov     al, es:[si]
        mov     [di], al
        cmp     BYTE PTR es:[si], byte ptr ' '
        jne     getNextCharacter
        cmp     wasPreviousLetter, 0
        je      skipCurrentSymbol
        mov     wasPreviousLetter, 0
        cmp     parsingStep, 1
        jne     stepTwo
        call    getIterations
        jmp     skipCurrentSymbol
        stepTwo:
            call    getStringNumber
            jmp     skipCurrentSymbol
        stepThree:
            call    getFilename
            jmp     main
        getNextCharacter:
            mov     wasPreviousLetter, 1
        skipCurrentSymbol:
            inc     di
            inc     si
            cmp     si, bx
            jg      stepThree    ;if bigger
    jbe getPath      ;if lower or equal
    
    main:
        lea     dx, startMessage
        call    puts
        lea     ax, path 
        push    ax
        call    printString  
        pop     ax
        dec     stringNumber
        call    getApplicationName
        xor cx, cx
        mov cx, iterations
        startApps:
            call    loadAndRun
            loop    startApps
            call exit
endp

csize = $ - printString

end start