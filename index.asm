; Data section is used for declaring initialized data or constants.
; - Data does not change at runtime
; - Declare various constant values, file names, or buffer size, etc.
section .data
    ; Syntax defining a string value: (label): db (define byte) 10 (Optional: argument, new line in ASCII), "<string_value>", 10 (Optional: argument, new line in ASCII)
    ; Syntax determine the string length: (label): equ (equate), $-<label reference>
    commandText db "Input a number ranging from 0-9: "
    commandText_len equ $ - commandText
    successMsg db 10,"Correct!",10
    successMsg_len equ $ - successMsg
    failureMsg db 10,"Incorrect! The answer should be "
    failureMsg_len equ $ - failureMsg
    digit db 0,10

; bss Section is used for declaring variables
section .bss
    ; Syntax: (label), resb (reserve byte), # (number of bytes)
    input resb 1     ; 1 byte as single digit, no numeric signs
    randomNum resb 1 ; 1 byte as single digit, no numeric signs

; The text section is used for keeping the actual code
; The section must begin with the declaration of global _start
; Tells the kernel where the program execution begins
section .text
    global _start

_start:
    ; Calls subroutines
    call _getUserInput
    call _generatePseudoRandomNumber
    call _printResultMsg

; ==== Read and store the user input ====
; https://man7.org/linux/man-pages/man2/read.2.html
; ssize_t read(int fd, void *buf, size_t count);
_getUserInput:
    ; Print instructions
    call _printInstructions

    ; Register Accumulator is used as input/output for most arithmetic/logical instructions
    ; Purpose: System call to read (read 0)
    mov rax, 0
    ; Register destination index, File handle for stdout, File descriptor (FD = 0)
    mov rdi, 0
    ; Register source index, use the string to store the user input as the buffer.
    mov rsi, input
    ; Register data, stores the length of the user input string as the count.
    mov rdx, 1
    syscall ; invoke the os to perform the read operation

    ; Turn user input from string to integer
    ; Store user input into the register accumulator
    mov rax, [input]
    ; Subtract 48 (in ASCII '0') as a terminator used to indicate the string has ended.
    sub rax, 48
    ; 'rax' is made up of 'ah' (upper half bits) and 'al' (lower half bits)
    ; Storing al (rax lower half values) to the user input variable
    mov [input], al
    ret ; subroutine finished, return to _start

; ==== Message to ask user for input ====
; https://man7.org/linux/man-pages/man2/write.2.html
; size_t write(int fd, void *buf, size_t count)
_printInstructions:
    ; Register Accumulator is used as input/output for most arithmetic/logical instructions
    ; Purpose: System call to write (write = 1)
    mov rax, 1
    ; Register destination index, File handle for stdout, File descriptor (FD = 1)
    mov rdi, 1
    ; Register source index, use the string stored in commandTextg as the buffer.
    mov rsi, commandText
    ; Register data, stores the length of the commandText string as the count.
    mov rdx, commandText_len
    syscall ; invoke os to perform write operation.
    ret     ; subroutine finished, return to _getUserInput

_generatePseudoRandomNumber:
    ; https://man7.org/linux/man-pages/man2/time.2.html
    ; time_t time(time_t *tloc)
    ; time() - returns the time as the number of seconds since Epoch (1970-01-01 00:00:00 +0000 (UTC);
    ; mov (instruction), rax (register), 201 (argument, system call time)
    ; Purpose: Get the time in second and store it in rax where values are return to this register
    mov rax, 201
    syscall ; invoke os to perform the get system time in seconds.

    ; Divide the value of sys_time by 10, such that the remainder would range between 0 - 9
    ; Use to clear the content of rdx so we do not use existing content when dividing.
    xor rdx, rdx
    ; Store the value 10 the divisor into register rcx
    mov rcx, 10
    ; Divide rax which has the system time in seconds with rcx register that contains the value 10.
    ; Put the ratio result into rax, and the remainder into rdx.
    div rcx

    ; Store the value from rdx (holds, intermediate calculate values) into randomNum variable
    mov [randomNum], rdx
    ret ; subroutine finished, return to _start

_printResultMsg:
    ; Compare dl value to the user input value
    ; subtract input value to dl and compare if they are equal.
    ; Operands value does not change.
    cmp dl, [input]

    ; Uses the compare result value from previous line,
    ; if the compare result are not equal, jump to incorrectGuess label
    ; otherwise go to next line.
    jne incorrectGuess

    ; Calls subroutine of print sucess message
    call _printSuccessMsg

    ; Jumps to the "end" label to exit program
    jmp end

    incorrectGuess:
        ; Calls subrountine of print failure message
        call _printFailureMsg
        ; Jumps to the "end" label to exit program
        jmp end

    end:
        ; Exit code
        ; https://man7.org/linux/man-pages/man2/exit.2.html
        ; noreturn void _Exit(int status);
        ; Purpose: Syscall for exit
        mov rax, 60
        ; Purpose: xor of a register with itself will result in zero. Therefore exit code is 0. This is used for the exit status.
        xor rdi, rdi
        syscall ; invoke os to exit after either printing sucess/failure message.

; ==== Message for correct guess ====
; https://man7.org/linux/man-pages/man2/write.2.html
; size_t write(int fd, void *buf, size_t count)
_printSuccessMsg:
    ; Register Accumulator is used as input/output for most arithmetic/logical instructions
    ; Purpose: System call to write (write = 1)
    mov rax, 1
    ; Register destination index, File handle for stdout, File descriptor (FD = 1)
    mov rdi, 1
    ; Register source index, use the string stored in sucess message as the buffer.
    mov rsi, successMsg
    ; Register data, stores the length of the sucess message string as the count.
    mov rdx, successMsg_len
    syscall ; invoke os to perform write operation.
    ret     ; subroutine finished, return to _printResultMsg

; ==== Message for incorrect guess ====
; https://man7.org/linux/man-pages/man2/write.2.html
; size_t write(int fd, void *buf, size_t count)
_printFailureMsg:
    ; Register Accumulator is used as input/output for most arithmetic/logical instructions
    ; Purpose: System call to write (write = 1)
    mov rax, 1
    ; Register destination index, File handle for stdout, File descriptor (FD = 1)
    mov rdi, 1
    ; Register source index, use the string stored in failure message as the buffer.
    mov rsi, failureMsg
    ; Register data, stores the length of the failure message string as the count.
    mov rdx, failureMsg_len
    syscall                 ; invoke os to perform write operation.
    call _printRandomNumber ; call subroutine of print random number
    ret                     ; subroutine finished, return to _printResultMsg

; ==== Print the random Number generated ====
; https://man7.org/linux/man-pages/man2/write.2.html
; size_t write(int fd, void *buf, size_t count)
_printRandomNumber:
    ; Store the variable value of randomNum of type Integer into rax register
    mov rax, [randomNum]
    ; Convert it back to a string by adding 48, in ASCII '0' as a terminator used to indicate the string has ended.
    add rax, 48
    ; 'rax' is made up of 'ah' (upper half bits) and 'al' (lower half bits)
    ; Storing al (rax lower half bit values) to the digit variable
    mov [digit], al

    ; ==== Output random number ====
    ; https://man7.org/linux/man-pages/man2/write.2.html
    ; size_t write(int fd, void *buf, size_t count)

    ; Register Accumulator is used as input/output for most arithmetic/logical instructions
    ; Purpose: System call to write (write = 1)
    mov rax, 1
    ; Register destination index, File handle for stdout, File descriptor (FD = 1)
    mov rdi, 1
    ; Register source index, use the string stored in digit as the buffer.
    mov rsi, digit
    ; Register data, stores the length of a digit (1 byte) as the count.
    mov rdx, 1
    syscall           ; invoke os to perform write operation.
    ret               ; subroutine finished, return to _printFailureMsg