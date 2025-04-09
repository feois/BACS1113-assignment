include irvine32.inc

.data
datetime systemtime <>
month_str db "JanFebMarAprMayJunJulAugSepOctNovDec"

; string buffer
BUFFER_LENGTH = 255
buffer db BUFFER_LENGTH + 1 dup (?)

bufferedfile struct
    bf_handle dword ?
    bf_buffer byte BUFFER_LENGTH dup (?)
    bf_len byte 0
bufferedfile ends

; constant
float_ten real4 10.0
float_hundred real4 100.0
; generic variable used to store float (in IEEE single-precision format) temporarily
float_register real4 ?

system_logo db "Super Banking Calculator", 9, 0

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
selected_option dd ?

values_dialog db "Please enter the following values", 0

loan_p_dialog db "Principal: RM ", 0
loan_r_dialog db "Monthly interest rate (in %): ", 0
loan_n_dialog db "Number of payments: ", 0
loan_p dd 0
loan_r real4 0.0
loan_n dd 0
loan_dialog db "Estimated Monthly Instalment: RM ", 0

exit_dialog db "Thank you for using this application", 0

interest_p_dialog db "Principal: RM ", 0
interest_r_dialog db "Interest rate (in %): ", 0
interest_n_dialog db "Compounding frequency per year: ", 0
interest_t_dialog db "Time in years: ", 0
interest_p dd 0
interest_r real4 0.0
interest_n real4 0.0
interest_t real4 0.0
interest_dialog db "Final amount: RM ", 0

;HOCHEEHIN
debt_total_dialog db "Total monthly debt payment: RM ", 0
income_dialog db "Gross monthly income: RM ", 0
dti_result_dialog db "Debt-to-Income Ratio: ", 0
dti_approve       db "Loan approved (DTI <= 36%)", 0
dti_reject        db "Loan rejected (DTI > 36%)", 0
dti_threshold     real4 36.0
debt_total        dd 0.0
income_gross      dd 0.0

.code
main proc
    call clear
login_username:
    ; print dialog
    lea edx, login_dialog
    call writestring

    ; read username
    call read_to_buffer

    .if ecx == 0
        ; empty input
        jmp main_end
    .elseif ecx == sizeof username
        ; check username
        lea edx, username
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

    .if ecx == 0
        ; empty input
        jmp main_end
    .elseif sizeof password
        ; check password
        lea edx, password
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
    mov esi, 0
menu_loop:
    ; print all options
    mov edx, [options + esi * 4]
    inc esi
    mov eax, esi
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
    test eax, eax
    jz menu
    dec eax
    cmp eax, lengthof options
    jae menu
    mov eax, [options + eax * 4]
    mov selected_option, eax
option_selected:
    call clear
    mov edx, selected_option
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
    lea edx, values_dialog
    call writestring
    call crlf

    ; print principal dialog
    lea edx, loan_p_dialog
    call writestring

    .if loan_p == 0
        ; ask for principal
        call readdec
        mov loan_p, eax
        jmp option_selected
    .endif

    mov eax, loan_p
    call writedec
    call crlf

    ; print rate dialog
    lea edx, loan_r_dialog
    call writestring

    .if loan_r == 0
        ; ask for rate
        call read_to_buffer

        ; try convert to float
        lea edx, buffer
        call str_to_float
        jc option_selected
        mov loan_r, eax
        jmp option_selected
    .endif

    mov eax, loan_r
    call print_float
    mov al, '%'
    call writechar
    call crlf

    ; print payment dialog
    lea edx, loan_n_dialog
    call writestring

    .if loan_n == 0
        ; ask for rate
        call readdec
        mov loan_n, eax
        jmp option_selected
    .endif

    mov eax, loan_n
    call writedec
    call crlf

    fld loan_r
    fdiv float_hundred
    ; calculate (1+r)^n
    fild loan_n
    fld1
    fadd st, st(2) ; 1 + r
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
    fxch
    fld st(1)

    ; calculate EMI
    fld1
    fsub ; (1+r)^n - 1
    fxch st(2)
    fimul loan_p ; p * (1+r)^n
    fmul ; p * r * (1+r)^n
    fxch
    fdiv ; p * r * (1+r)^n / ((1+r)^n - 1)
    fstp float_register

    ; print EMI
    call crlf
    lea edx, loan_dialog
    call writestring
    mov eax, float_register
    call print_float
    call crlf

    ; reset data
    mov loan_p, 0
    mov loan_r, 0
    mov loan_n, 0

    jmp wait_input
interest:
    lea edx, values_dialog
    call writestring
    call crlf

    lea edx, interest_p_dialog
    call writestring

    .if interest_p == 0
        call readdec
        mov interest_p, eax
        jmp option_selected
    .endif

    mov eax, interest_p
    call writedec
    call crlf

    lea edx, interest_r_dialog
    call writestring

    .if interest_r == 0
        call read_to_buffer
        lea edx, buffer
        call str_to_float
        jc option_selected
        mov interest_r, eax
        jmp option_selected
    .endif

    mov eax, interest_r
    call print_float
    call crlf

    lea edx, interest_n_dialog
    call writestring

    .if interest_n == 0
        call read_to_buffer
        lea edx, buffer
        call str_to_float
        jc option_selected
        mov interest_n, eax
        jmp option_selected
    .endif

    mov eax, interest_n
    call print_float
    call crlf

    lea edx, interest_t_dialog
    call writestring

    .if interest_t == 0
        call read_to_buffer
        lea edx, buffer
        call str_to_float
        jc option_selected
        mov interest_t, eax
        jmp option_selected
    .endif

    mov eax, interest_t
    call print_float
    call crlf
    call crlf

    fld interest_n
    fmul interest_t
    fld interest_r
    fdiv float_hundred
    fdiv interest_n

    fst float_register
    mov eax, float_register
    call writebin
    call crlf
    call print_float
    call crlf

    fld1
    fadd
    fyl2x
    fld1
    fld st(1)
    fprem
    f2xm1
    fadd
    fscale
    fxch
    fstp st
    fimul interest_p
    fstp float_register

    lea edx, interest_dialog
    call writestring
    mov eax, float_register
    call print_float
    call crlf

    mov interest_p, 0
    mov interest_r, 0
    mov interest_n, 0
    mov interest_t, 0
    jmp wait_input

;HOCHEEHIN
debt:
    lea edx, values_dialog
    call writestring
    call crlf

    lea edx, debt_total_dialog
    call writestring

    .if debt_total == 0
        call readdec
        mov debt_total, eax
        jmp option_selected
    .endif

    mov eax, debt_total
    call writedec
    call crlf

    lea edx, income_dialog
    call writestring

    .if income_gross == 0
        call readdec
        mov income_gross, eax
        jmp option_selected
    .endif

    mov eax, income_gross
    call writedec
    call crlf

    fld debt_total
    fdiv income_gross
    fmul float_hundred
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
    jbe loan_approved
    lea edx, dti_reject
    jmp print_loan_decision
loan_approved:
    lea edx, dti_approve
print_loan_decision:
    call writestring
    call crlf

    mov debt_total, 0
    mov income_gross, 0
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

; clear screen and print logo and time
clear proc
    push eax
    push edx
    mov eax, 0
    call clrscr
    ; print logo
    lea edx, system_logo
    call writestring
    ; get time
    lea edx, datetime
    push edx
    call getlocaltime
    ; print month
    mov dx, datetime.wmonth
    mov ax, dx
    add ax, dx
    add ax, dx
    lea edx, month_str
    lea edx, [edx + eax - 3]
    mov al, [edx]
    call writechar
    mov al, [edx + 1]
    call writechar
    mov al, [edx + 2]
    call writechar
    mov al, ' '
    call writechar
    ; print day
    mov ax, datetime.wday
    call writedec
    mov al, ' '
    call writechar
    ; print year
    mov ax, datetime.wyear
    call writedec
    mov al, 9
    call writechar
    ; print hour
    mov ax, datetime.whour
    call print_double_digits
    mov al, ':'
    call writechar
    ; print minute
    mov ax, datetime.wminute
    call print_double_digits
    mov al, ':'
    call writechar
    ; print second
    mov ax, datetime.wsecond
    call print_double_digits

    call crlf
    call crlf
    pop edx
    pop eax
    ret
clear endp

; read line (string ends with char 10) to a buffer from a bufferedfile
; edx = offset of bufferedfile
; overwrite ecx
; set eax = number of characters read
; set CF if buffer[eax - 1] is not char 10 (file does not end in new line / line longer than buffer, read again to get rest of the line)
; set ZF if nothing to read
file_read_line_to_buffer proc
    push esi
    push edi
    push edx
    assume edx: ptr bufferedfile

    ; copy to buffer
    mov esi, 0
    mov ecx, 0
    mov cl, [edx].bf_len
    test cl, cl
    jz clear_bufferedfile
file_copy_to_buffer:
    mov al, [edx].bf_buffer[esi]
    mov buffer[esi], al
    inc esi
    loop file_copy_to_buffer

clear_bufferedfile:
    mov [edx].bf_len, 0

    ; read from file
    mov eax, [edx].bf_handle
    mov ecx, BUFFER_LENGTH
    sub ecx, esi
    lea edx, buffer[esi]
    call readfromfile
    pop edx

    ; check for new line
    mov ecx, esi
    add ecx, eax
    push ecx
    mov esi, 0
    .if ecx == 0
        pop eax ; set ZF
        test al, al
        jmp file_read_line_end
    .endif
buffer_find_new_line:
    cmp buffer[esi], 10
    je buffer_new_line_found
    inc esi
    loop buffer_find_new_line

    ; no new line
    pop eax
    stc
    jmp file_read_line_end

    ; copy to bufferedfile
buffer_new_line_found:
    inc esi
    pop ecx
    push esi
    mov edi, 0
    sub ecx, esi
    mov [edx].bf_len, cl

    .if ecx > 0
    file_copy_from_buffer:
        mov al, buffer[esi]
        mov [edx].bf_buffer[edi], al
        inc edi
        inc esi
        loop file_copy_from_buffer
    .endif
    or eax, -1 ; clear ZF
    pop eax

file_read_line_end:
    pop edi
    pop esi
    ret
file_read_line_to_buffer endp

; read string into the buffer
; overwrite eax, edx
; set ecx = length of string (not including 0)
read_to_buffer proc
    lea edx, buffer
    mov ecx, BUFFER_LENGTH
    call readstring
    mov ecx, eax
    ret
read_to_buffer endp

; copy buffer to another buffer
; edx = offset of the target buffer
; ecx = number of bytes to copy
; overwrite al
copy_buffer_to proc
    push esi
    mov eax, esi
    mov esi, 0
copy_loop:
    mov al, buffer[esi]
    mov [edx + esi], al
    inc esi
    loop copy_loop
    pop esi
    ret
copy_buffer_to endp

; compare string to buffer
; edx = offset of the string to be compared to
; ecx = number of bytes to compare
; overwrite al, ecx
; set flags same as cmp
buffer_cmp proc
    push esi
    mov esi, 0
buffer_cmp_loop:
    mov al, [edx + esi]
    cmp al, buffer[esi]
    ; jump if different byte
    jne buffer_cmp_end
    inc esi
    loop buffer_cmp_loop
buffer_cmp_end:
    ; set flags again
    cmp al, buffer[esi]
    pop esi
    ret
buffer_cmp endp

; print integer with double digits (add 0 to integer less than 10)
; eax = integer
print_double_digits proc
    .if eax < 10
        mov ah, al
        mov al, '0'
        call writechar
        mov al, ah
        mov ah, 0
    .endif

    call writedec
print_double_digits endp

; convert string to float
; edx = string offset
; ecx = string length
; overwrite ecx
; set eax = float
; set CF if string is invalid
str_to_float proc
    push esi
    push ecx
    ; index
    mov esi, 0
    ; f = 0
    fldz
decimal_loop:
    mov eax, 0
    mov al, [edx + esi]
    inc esi

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
    pop ecx
    pop esi
    ret
fraction:
    ; set index to end of string
    pop esi
    dec ecx

    ; g = 0
    fldz
fraction_loop:
    dec esi
    mov eax, 0
    mov al, [edx + esi]

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
    pop esi
    ret
fraction_error:
    ; pop float
    fstp st
    push ecx
decimal_error:
    ; pop float
    fstp st
    stc
    pop ecx
    pop esi
    ret
str_to_float endp

; print float always with 2 digit precision (e.g. 1234.56, 1000.01)
; eax = float
; overwrite eax, cl
; set CF if float is larger than 2^32
print_float proc
    .if eax == 0
        mov al, '0'
        call writechar
        mov al, '.'
        call writechar
        mov al, '0'
        call writechar
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
    cmp cl, 32
    jae float_integer_zero
    shr eax, cl
    jmp print_float_integer
float_is_integer:
    sub cl, 23
    shl eax, cl
    jmp print_float_integer
float_integer_zero:
    mov eax, 0
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
    cmp cl, 24
    jae print_float_exponent
    mov eax, float_register
    and eax, 007FFFFFh
    or eax, 00800000h
    shr eax, cl
    and eax, 000000FFh

    ; compute round(mantissa * 0.390625 or 100×2^-8)
    mov float_register, eax
    fild float_register
    mov float_register, 390625 ; mantissa *= 390625
    fimul float_register
    mov float_register, 1000000 ; mantissa /= 1000000
    fidiv float_register
    fistp float_register
    mov eax, float_register
print_float_exponent:
    call print_double_digits
    ret
print_float_error:
    stc
    ret
print_float endp

end main
