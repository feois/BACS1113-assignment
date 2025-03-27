include irvine32.inc
.data
; string buffer
BUFFER_LENGTH = 255
buffer db BUFFER_LENGTH + 1 dup (?)

; constant used in str_to_float
float_ten real4 10.0
; variable used in str_to_float
float_length dd ?
; generic variable used to store float (in IEEE single-precision format) temporarily
float_register real4 ?

system_logo db "Super Banking Calculator©2025", 0

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
option_dialog db "Please select a valid option (1-", '0' + lengthof options, "): ", 0

loan_dialog db "Please enter the following values", 0
loan_p_dialog db "Principal: RM ", 0
loan_r_dialog db "Monthly interest rate (in %): ", 0
loan_n_dialog db "Number of payments: ", 0
loan_principal dd 0
loan_rate real4 0.0
loan_payment dd 0
loan_emi_dialog db "Estimated Monthly Instalment: RM ", 0

exit_dialog db "Thank you for using this application", 0

;HOCHEEHIN
debt_dialog db "Compute Debt-to-Income Ratio", 0
debt_total_dialog db "Total monthly debt payment: RM ", 0
income_dialog db "Gross monthly income: RM ", 0
dti_result_dialog db "Debt-to-Income Ratio: ", 0
dti_approve       db "Loan approved (DTI <= 36%)", 0
dti_reject        db "Loan rejected (DTI > 36%)", 0
dti_threshold     real4 36.0
debt_total        real4 0.0
income_gross      real4 0.0

dti_input_error   db "Invalid input! Please enter a number.", 0
dti_attempt_lock  db "Too many invalid attempts. Returning to menu.", 0
dti_attempt_max   dd 3
dti_attempt_count dd ?

.code
main proc
    call clear
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
    call clear

    ; check attempts
    dec username_attempt
    .if username_attempt == 0
        lea edx, attempt_lock
        call writestring
        call crlf
        exit
    .endif

    lea edx, wrong_username
    call writestring
    mov eax, username_attempt
    call writedec
    lea edx, attempt_str
    call writestring
    call crlf
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
    call clear

    ; check attempts
    dec password_attempt
    .if password_attempt == 0
        call clear
        lea edx, attempt_lock
        call writestring
        call crlf
        exit
    .endif

    lea edx, wrong_password
    call writestring
    mov eax, password_attempt
    call writedec
    lea edx, attempt_str
    call writestring
    call crlf
    jmp login_password
menu:
    call clear

    ; print dialog
    lea edx, menu_dialog
    call writestring
    call crlf
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
    call crlf
    loop menu_loop

    ; ask for option selection
    call crlf
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
    call clear
    call writestring
    call crlf
    call crlf
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
    call crlf

    ; print principal dialog
    lea edx, loan_p_dialog
    call writestring

    .if loan_principal == 0
        ; ask for principal
        call readdec
        cmp eax, 0
        lea edx, option_loan
        je jump_options
        mov loan_principal, eax
    .else
        mov eax, loan_principal
        call writedec
        call crlf
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
        jc jump_options

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
        call crlf
    .endif

    ; print payment dialog
    lea edx, loan_n_dialog
    call writestring

    .if loan_payment == 0
        ; ask for rate
        call readdec
        cmp eax, 0
        lea edx, option_loan
        je jump_options
        mov loan_payment, eax
    .else
        mov eax, loan_payment
        call writedec
        call crlf
    .endif

    ; calculate (1+r)^n
    fild loan_payment
    fld1
    fadd loan_rate ; 1 + r
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
    fsub ; (1+r)^n - 1
    fxch
    fimul loan_principal ; p * (1+r)^n
    fmul loan_rate ; p * r * (1+r)^n
    fxch
    fdiv ; p * r * (1+r)^n / ((1+r)^n - 1)
    fstp float_register

    ; print EMI
    call crlf
    lea edx, loan_emi_dialog
    call writestring
    mov eax, float_register
    call print_float
    call crlf

    ; reset data
    mov loan_principal, 0
    mov loan_rate, 0
    mov loan_payment, 0

    jmp wait_input
interest:

;HOCHEEHIN
debt:
    mov eax, dti_attempt_max
    mov dti_attempt_count, eax

input_debt:
    cmp dti_attempt_count, 0
    jle too_many_attempts

    lea edx, debt_total_dialog
    call writestring
    call read_to_buffer
    lea esi, buffer
    mov ecx, eax
    call str_to_float
    jc invalid_input_debt

    mov debt_total, eax

    fld debt_total
    fldz
    fcomip st, st(1)
    fstp st
    je invalid_input_debt

    jmp input_income

invalid_input_debt:
    dec dti_attempt_count
    lea edx, dti_input_error
    call writestring
    call crlf
    jmp input_debt

input_income:
    cmp dti_attempt_count, 0
    jle too_many_attempts

    lea edx, income_dialog
    call writestring
    call read_to_buffer
    lea esi, buffer
    mov ecx, eax
    call str_to_float
    jc input_income
    mov income_gross, eax

    fld income_gross
    fldz
    fcomip st, st(1)
    fstp st
    je division_error

    fld debt_total
    fdiv income_gross
    fmul float_ten
    fmul float_ten
    fst float_register

    call crlf
    lea edx, dti_result_dialog
    call writestring
    mov eax, float_register
    call print_float
    mov al, '%'
    call writechar
    call crlf

    fld dti_threshold
    fxch
    fcomip st, st(1)
    fstp st
    jbe approved
    lea edx, dti_reject
    jmp print_decision
approved:
    lea edx, dti_approve
print_decision:
    call writestring
    call crlf
    jmp wait_input

invalid_input_income:
    dec dti_attempt_count
    lea edx, dti_input_error
    call writestring
    call crlf
    jmp input_income

too_many_attempts:
    lea edx, dti_attempt_lock
    call writestring
    call crlf
    jmp menu

division_error:
    lea edx, dti_input_error
    call writestring
    call crlf
    jmp input_income
wait_input:
    call crlf
    lea edx, wait_dialog
    call writestring
    call crlf
    call read_to_buffer
    jmp menu
main_end:
    call clear

    lea edx, exit_dialog
    call writestring
    call crlf

    exit
main endp

; clear screen and print logo
; overwrite eax
clear proc
    call clrscr
    mov eax, edx
    lea edx, system_logo
    call writestring
    mov edx, eax
    call crlf
    call crlf
    ret
clear endp

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
; overwrite eax, dx
; set flags same as cmp
buffer_cmp proc
    ; index
    mov eax, 0
buffer_cmp_loop:
    mov dl, [esi + eax]
    add eax, offset buffer
    mov dh, [eax]
    cmp dl, dh
    ; jump if different byte
    jne buffer_cmp_end
    sub eax, offset buffer
    inc eax
    loop buffer_cmp_loop
buffer_cmp_end:
    ; set flags again
    cmp dl, dh
    ret
buffer_cmp endp

; convert string to float
; esi = string
; ecx = string length
; overwrite edx
; set eax = float
; set CF if string is invalid
str_to_float proc
    mov float_length, ecx
    ; index
    mov edx, 0
    ; f = 0
    fldz
decimal_loop:
    mov eax, 0
    mov al, [esi + edx]
    inc edx

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
    fstp float_register
    mov eax, float_register
    ret
fraction:
    ; set index to end of string
    mov edx, float_length
    dec ecx

    ; g = 0
    fldz
fraction_loop:
    dec edx
    mov eax, 0
    mov al, [esi + edx]

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
    fstp float_register
    mov eax, float_register
    ret
fraction_error:
    ; pop float
    fstp st
decimal_error:
    ; pop float
    fstp st
    stc
    ret
str_to_float endp

; print float always with 2 digit precision (e.g. 1234.56, 1000.00) except 0 (which is printed as 0)
; eax = float
; overwrite cl
; set CF if float is larger than 2^32
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
    sub al, 127

    ; check if float >= 2^32
    cmp al, 32
    jg print_float_error

    mov cl, al

    ; extract mantissa
    mov eax, float_register
    and eax, 007FFFFFh
    or eax, 00800000h

    cmp cl, 24
    jge float_is_integer
    ; float is decimal
    neg cl
    add cl, 23
    shr eax, cl
    jmp print_float_integer
float_is_integer:
    sub cl, 23
    shl eax, cl
print_float_integer:
    call writedec
    mov al, '.'
    call writechar

    ; print fraction

    ; extract exponent
    mov eax, float_register
    and eax, 7F800000h
    shr eax, 23
    sub al, 127
    mov cl, al
    mov eax, 0

    cmp cl, 15
    jg print_float_exponent

    ; extract first 8 bits of mantissa
    neg cl
    add cl, 15
    mov eax, float_register
    and eax, 007FFFFFh
    or eax, 00800000h
    shr eax, cl
    and eax, 000000FFh

    ; compute round(mantissa * 0.390625 or 100×2^-8)
    mov float_register, eax
    fild float_register
    mov float_register, 390625 ; mantissa *= 390625
    fild float_register
    fmul
    mov float_register, 1000000 ; mantissa /= 1000000
    fild float_register
    fdiv
    fistp float_register
    mov eax, float_register
print_float_exponent:
    ; print an extra 0 before mantissa if less than ten
    .if eax < 10
        ; temporarily move eax (al because eax < 10) to ah first
        mov ah, al
        ; print zero
        mov al, '0'
        call writechar
        ; move ah back to eax
        mov al, ah
        mov ah, 0
    .endif

    ; print mantissa
    call writedec
    ret
print_float_error:
    stc
    ret
print_float endp

end main
