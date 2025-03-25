include irvine32.inc
.data
; string buffer
BUFFER_LENGTH = 255
buffer db BUFFER_LENGTH + 1 dup (?)

; constant used in str_to_float
float_ten real4 10.0
; variable used in str_to_float
float_length dd 0
; generic variable used to store float (in IEEE single-precision format) temporarily
float_register dd 0
; variable used to store float result (in IEEE single-precision format)
float_result dd 0

attempt_str db " more times", 0
attempt_lock db "You have attempted too many times", 0

login_dialog db "Please enter username (Empty to cancel): ", 0
wrong_username db "Wrong username! You can only attempt ", 0
username db "wilson"
username_attempt dd 3

password_dialog db "Please enter password (Empty to cancel): ", 0
wrong_password db "Wrong password! You can only attempt ", 0
password db "password"
password_attempt dd 3

menu_dialog db "Menu", 0

wait_dialog db "Press Enter to continue", 0

option_loan db "Compute loan", 0
option_interest db "Compute compound interest", 0
option_debt db "Compute Debt-to-Interest ratio", 0
option_exit db "Exit", 0
options dd offset option_loan, offset option_interest, offset option_debt, offset option_exit
option_dialog db "Please select a valid option: ", 0

loan_dialog db "Please enter the following values", 0
loan_p_dialog db "Principal: RM ", 0
loan_r_dialog db "Monthly interest rate (in %): ", 0
loan_n_dialog db "Number of payments: ", 0
loan_principal dd 0 ; float
loan_rate dd 0 ; float
loan_payment dd 0 ; int
loan_emi_dialog db "Estimated Monthly Instalment: ", 0

.code
main proc
    call clrscr
login_username:
    ; print dialog
    lea edx, login_dialog
    call writestring
    
    ; read username
    call read_to_buffer

    .if eax == 0
        ; empty input
        jmp main_end
    .elseif eax == sizeof username
        ; check username
        lea esi, username
        mov ecx, eax
        call buffer_cmp
        ; username correct
        je login_password
    .endif
    
    ; wrong username
    call clrscr

    ; check attempts
    dec username_attempt
    .if username_attempt == 0
        lea edx, attempt_lock
        call writestring
        call new_line
        jmp main_end
    .endif

    lea edx, wrong_username
    call writestring
    mov eax, username_attempt
    call writedec
    lea edx, attempt_str
    call writestring
    call new_line
    jmp login_username
login_password:
    ; print dialog
    lea edx, password_dialog
    call writestring
    
    ; read password
    call read_to_buffer
    
    .if eax == 0
        ; empty input
        jmp main_end
    .elseif sizeof password
        ; check password
        lea esi, password
        mov ecx, eax
        call buffer_cmp
        ; password correct
        je menu
    .endif
    
    ; wrong password
    call clrscr

    ; check attempts
    dec password_attempt
    .if password_attempt == 0
        call clrscr
        lea edx, attempt_lock
        call writestring
        call new_line
        jmp main_end
    .endif

    lea edx, wrong_password
    call writestring
    mov eax, password_attempt
    call writedec
    lea edx, attempt_str
    call writestring
    call new_line
    jmp login_password
menu:
    call clrscr

    ; print dialog
    lea edx, menu_dialog
    call writestring
    call new_line
    mov ecx, lengthof options
menu_loop:
    ; print all options
    mov eax, lengthof options
    sub eax, ecx
    mov edx, [options + eax * 4]
    inc eax
    call writedec
    mov al, ')'
    call writechar
    mov al, ' '
    call writechar
    call writestring
    call new_line
    loop menu_loop

    ; ask for option selection
    call new_line
    lea edx, option_dialog
    call writestring

    ; option input
    call readdec

    ; check for invalid input
    jc menu
    cmp eax, 0
    je menu
    dec eax
    cmp eax, lengthof options
    jnc menu
    mov edx, [options + eax * 4]
jump_options:
    call clrscr
    call writestring
    call new_line
    call new_line
    ; jump to function page
    cmp edx, offset option_loan
    je loan
    cmp edx, offset option_interest
    je interest
    cmp edx, offset option_debt
    je debt
    cmp edx, offset option_exit
    je main_end
loan:
    lea edx, loan_dialog
    call writestring
    call new_line

    ; print principal dialog
    lea edx, loan_p_dialog
    call writestring

    .if loan_principal == 0
        ; ask for principal
        call readdec
        lea edx, option_loan
        jo jump_options
        mov loan_principal, eax
    .else
        mov eax, loan_principal
        call writedec
        call new_line
    .endif

    ; print rate dialog
    lea edx, loan_r_dialog
    call writestring

    .if loan_rate == 0
        ; ask for rate
        call read_to_buffer

        ; try convert to float
        lea esi, buffer
        mov ecx, eax
        call str_to_float
        lea edx, option_loan
        jo jump_options

        ; divide by 100
        mov float_register, eax
        fld float_register
        fld float_ten
        fld float_ten
        fmul
        fdiv
        fstp float_register

        mov eax, float_register
        mov loan_rate, eax
    .else
        mov eax, loan_rate
        call print_float
        call new_line
    .endif

    ; print payment dialog
    lea edx, loan_n_dialog
    call writestring

    .if loan_payment == 0
        ; ask for rate
        call readdec
        lea edx, option_loan
        jo jump_options
        mov loan_payment, eax
    .else
        mov eax, loan_payment
        call writedec
        call new_line
    .endif

    ; calculate (1+r)^n
    fild loan_payment
    fld1
    fld loan_rate
    fadd
    ; code from https://www.madwizard.org/programming/snippets?id=36
    fyl2x
    fld1
    fld st(1)
    fprem
    f2xm1
    fadd
    fscale
    fxch
    fstp st
    ; duplicate float
    fld st(0)

    ; calculate EMI
    fld1
    fsub
    fxch
    fild loan_principal
    fld loan_rate
    fmul
    fmul
    fxch
    fdiv
    fstp float_result

    ; print EMI
    call new_line
    lea edx, loan_emi_dialog
    call writestring
    mov eax, float_result
    call print_float
    call new_line

    ; reset data
    mov loan_principal, 0
    mov loan_rate, 0
    mov loan_payment, 0

    ; wait input to return to menu
    call new_line
    lea edx, wait_dialog
    call writestring
    call new_line
    call read_to_buffer
    jmp menu
interest:
debt:
main_end:
    call clrscr
    exit
main endp

; read string into the buffer
; overwrite ecx, edx
; set eax = length of string (not including 0)
read_to_buffer proc
    lea edx, buffer
    mov ecx, BUFFER_LENGTH
    call readstring
    ret
read_to_buffer endp

; compare string to buffer
; esi = string to be compared to
; ecx = number of bytes to compare
; overwrite edi
; set flags same as cmp
buffer_cmp proc
    lea edi, buffer
buffer_cmp_loop:
    mov al, [esi]
    mov ah, [edi]
    cmp al, ah
    ; jump if different byte
    jne buffer_cmp_end
    inc esi
    inc edi
    loop buffer_cmp_loop
buffer_cmp_end:
    ; set flags again
    cmp al, ah
    ret
buffer_cmp endp

; print new line
; overwrite al
new_line proc
    mov al, 10
    call writechar
    ret
new_line endp

; convert string to float
; esi = string
; ecx = string length
; overwrite edi
; set eax = float
; set OF if string is invalid
str_to_float proc
    mov float_length, ecx
    mov edi, esi
    ; f = 0
    fldz
decimal_loop:
    mov eax, 0
    mov al, [edi]
    inc edi

    ; check if al is .
    cmp al, '.'
    je fraction

    ; check if al is 0-9
    cmp al, '0'
    jb decimal_error
    cmp al, '9'
    ja decimal_error
    sub al, '0'

    ; f *= 10
    fmul float_ten
    ; f += eax
    mov float_register, eax
    fild float_register
    fadd
    loop decimal_loop

    ; eax = f
    fstp float_result
    mov eax, float_result
    ret
fraction:
    mov edi, esi
    add edi, float_length
    dec ecx

    ; g = 0
    fldz
fraction_loop:
    dec edi
    mov eax, 0
    mov al, [edi]

    ; check if al is 0-9
    cmp al, '0'
    jb fraction_error
    cmp al, '9'
    ja fraction_error
    sub al, '0'

    ; g += eax
    mov float_register, eax
    fild float_register
    fadd

    ; g /= 10
    fdiv float_ten
    loop fraction_loop

    ; f += g
    fadd

    ; eax = f
    fstp float_result
    mov eax, float_result
    ret
fraction_error:
    ; pop float
    fstp st
decimal_error:
    ; pop float
    fstp st
    ; set overflow flag
    sub al, 080h
    ret
str_to_float endp

; write float
; eax = float
; overwrite cl
; set OF if float is larger than 2^32
print_float proc
    .if eax == 0
        mov al, '0'
        call writechar
        ret
    .endif

    mov float_register, eax

    ; extract exponent
    and eax, 7F800000h
    shr eax, 23
    sub eax, 127
    ; check if float > 2^32
    .if eax > 32
        ; set overflow flag
        sub al, 080h
        ret
    .endif
    mov cl, al

    ; extract mantissa
    mov eax, float_register
    and eax, 007FFFFFh
    or eax, 00800000h

    ; print integer
    .if cl < 24
        neg cl
        add cl, 23
        shr eax, cl
    .else
        sub cl, 23
        shl eax, cl
    .endif
    call writedec
    mov al, '.'
    call writechar

    ; extract exponent
    mov eax, float_register
    and eax, 7F800000h
    shr eax, 23
    sub eax, 127
    mov cl, al

    ; extract mantissa
    mov eax, float_register
    and eax, 007FFFFFh
    or eax, 00800000h

    ; print fraction
    .if cl > 15
        mov eax, 0
    .else
        ; extract first 8 bits of mantissa
        neg cl
        add cl, 15
        shr eax, cl
        and eax, 000000FFh
    .endif
    ; compute round(mantissa * 0.390625)
    mov float_register, eax
    fild float_register
    mov float_register, 390625
    fild float_register
    fmul
    mov float_register, 1000000
    fild float_register
    fdiv
    fistp float_register
    mov eax, float_register
    ; print an extra 0 before mantissa if not zero and less than ten
    .if eax > 0 && eax < 10
        ; temporarily move eax (al because eax < 10) to ah first
        mov ah, al
        ; print zero
        mov al, '0'
        call writechar
        ; move ah back to eax
        mov al, ah
        mov ah, 0
    .endif
    call writedec
    ret
print_float endp

end main
