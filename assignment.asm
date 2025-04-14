include irvine32.inc

.data
ASCII_TAB = 9
ASCII_NEWLINE = 10
TAB_OFFSET = 2

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

system_logo db "Super Banking Calculator", ASCII_TAB, 0

account_filename db "accounts", 0
account_backup db "accounts.bak", 0
account_file bufferedfile <?>
username db BUFFER_LENGTH dup (?), 0
username_length db ?
password db BUFFER_LENGTH dup (?), 0
password_length db ?
MAX_ATTEMPTS = 3
attempts dd ?

login_dialog db TAB_OFFSET dup (ASCII_TAB), "Login/Register", 0
cancel_dialog db "Enter empty input to exit", 0
username_dialog db "Username: ", 0
password_dialog db "Password: ", 0
new_account_dialog db "This username does not exist, a new account will be created", 0
attempt_dialog_1 db "You can only attempt 3 times! (", 0
attempt_dialog_2 db " more times left)", 0
attempt_fail_dialog db "You have been temporarily locked out of the system due to too many incorrect password attempts", 0
invalid_account_file_dialog db "Error: Account database is invalid", 0

VALID_INPUT = 0
INVALID_INPUT = 1
INPUT_EMPTY = 2
INPUT_ZERO = 3
INPUT_OVERFLOW = 4
input_validity db VALID_INPUT
nzpi_invalid db "Invalid input! Please enter a non-zero positive integer", 0
nzpi_empty db "Please enter a non-zero positive integer", 0
nzpi_overflow db "Input too large!", 0
nzpf_invalid db "Invalid input! Please enter a non-zero positive decimal", 0
nzpf_empty db "Please enter a non-zero positive decimal", 0
nzpf_overflow db "Input too large!", 0

menu_dialog db TAB_OFFSET dup (ASCII_TAB), "Main Menu", 0
menu_username_dialog db "Currently logged in as: ", 0

option_loan db "Compute loan", 0
option_interest db "Compute compound interest", 0
option_debt db "Compute Debt-to-Interest ratio", 0
option_logout db "Log out", 0
option_exit db "Exit", 0
options dd offset option_loan, offset option_interest, offset option_debt, offset option_logout, offset option_exit
option_dialog db "Please select a valid option (1-", '0' + lengthof options, "): ", 0
selected_option dd ?

wait_dialog db "Press Enter to continue", 0

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
main_start:
    ; print login screen
    mov attempts, MAX_ATTEMPTS
    call clear
    lea edx, login_dialog
    call writestring
    call crlf
    call crlf
    lea edx, cancel_dialog
    call writestring
    call crlf

    ; ask for username
    lea edx, username_dialog
    call writestring
    call read_string_with_buffer
    jz main_end

    ; copy username from buffer
    mov username_length, cl
    lea edx, username
    call copy_buffer_to
    mov eax, 0
    mov al, username_length
    mov username[eax], 0

    ; open and read account database
    lea edx, account_filename
    call openinputfile

    ; check if file not exist
    cmp eax, INVALID_HANDLE_VALUE
    je register
    mov account_file.bf_handle, eax
find_username:
    ; read a line from account database
    lea edx, account_file
    call file_read_line_fit_buffer
    jc invalid_account_file
    jo invalid_account_file
    jz register ; reach the end of file already
    dec eax ; ignore new line

    ; check if line is the username we are looking for
    mov ecx, 0
    mov cl, username_length
    .if eax == ecx
        lea edx, username
        call buffer_cmp
        je login
    .endif

    ; read another line to skip the password
    lea edx, account_file
    call file_read_line_fit_buffer
    jmp find_username
invalid_account_file:
    mov eax, account_file.bf_handle
    call closefile
    call clear
    lea edx, invalid_account_file_dialog
    call writestring
    call crlf
    exit
register:
    ; ask for password
    lea edx, new_account_dialog
    call writestring
    call crlf
    lea edx, password_dialog
    call writestring
    call read_string_with_buffer
    jz main_end

    ; copy password from buffer
    mov password_length, cl
    lea edx, password
    call copy_buffer_to

    ; close account database if it exists
    mov eax, account_file.bf_handle
    .if eax != INVALID_HANDLE_VALUE
        call closefile
    .endif

    ; reopen account database
    lea edx, account_filename
    call openinputfile
    .if eax == INVALID_HANDLE_VALUE ; account database does not exist
        lea edx, account_filename
        call createoutputfile
        mov account_file.bf_handle, eax
    .else
        mov account_file.bf_handle, eax

        ; copy to backup
        lea edx, account_backup
        call createoutputfile
        push eax
        mov edx, account_file.bf_handle
        call copy_file
        pop eax
        call closefile
        mov eax, account_file.bf_handle
        call closefile

        ; copy from backup
        lea edx, account_backup
        call openinputfile
        push eax
        lea edx, account_filename
        call createoutputfile
        mov account_file.bf_handle, eax
        pop edx
        push edx
        call copy_file

        ; close backup database
        pop eax
        call closefile
    .endif

    ; write username
    mov eax, account_file.bf_handle
    lea edx, username
    mov ecx, 0
    mov cl, username_length
    mov username[ecx], ASCII_NEWLINE
    inc ecx
    call writetofile
    mov ecx, 0
    mov cl, username_length
    mov username[ecx], 0

    ; write password
    mov eax, account_file.bf_handle
    lea edx, password
    mov ecx, 0
    mov cl, password_length
    mov password[ecx], ASCII_NEWLINE
    inc ecx
    call writetofile
    mov ecx, 0
    mov cl, username_length
    mov password[ecx], 0

    ; close file
    mov eax, account_file.bf_handle
    call closefile
    jmp menu
login:
    ; read the password
    lea edx, account_file
    call file_read_line_fit_buffer
    jc invalid_account_file
    jz invalid_account_file
    dec eax ; ignore new line

    ; copy password from buffer
    mov password_length, al
    lea edx, password
    mov ecx, eax
    call copy_buffer_to

    ; close database
    mov eax, account_file.bf_handle
    call closefile
login_attempt:
    ; print login screen
    call clear
    lea edx, login_dialog
    call writestring
    call crlf
    call crlf
    lea edx, username_dialog
    call writestring
    lea edx, username
    call writestring
    call crlf

    ; check if not first attempt
    .if attempts != MAX_ATTEMPTS
        lea edx, attempt_dialog_1
        call writestring
        mov eax, attempts
        call writedec
        lea edx, attempt_dialog_2
        call writestring
        call crlf
    .endif

    ; ask for password
    lea edx, password_dialog
    call writestring
    call read_string_with_buffer

    ; check password
    mov ecx, 0
    mov cl, password_length
    .if eax == ecx
        lea edx, password
        call buffer_cmp
        je menu
    .endif

    ; incorrect password
    dec attempts
    jz login_fail
    jmp login_attempt
login_fail:
    call clear
    lea edx, attempt_fail_dialog
    call writestring
    call crlf
    exit
menu:
    call clear
    ; print dialog
    lea edx, menu_dialog
    call writestring
    call crlf
    call crlf
    lea edx, menu_username_dialog
    call writestring
    lea edx, username
    call writestring
    call crlf
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
    mov input_validity, VALID_INPUT
option_selected:
    call clear
    mov al, ASCII_TAB
    call writechar
    call writechar
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
    cmp edx, offset option_logout
    je main_start
    cmp edx, offset option_exit
    je main_end
loan:
    lea edx, values_dialog
    call writestring
    call crlf

    ; read principal
    mov eax, loan_p
    lea edx, loan_p_dialog
    call read_nzpi
    mov loan_p, eax
    jnc option_selected
    call crlf

    ; read rate
    mov eax, loan_r
    lea edx, loan_r_dialog
    call read_nzpf
    mov loan_r, eax
    jnc option_selected
    mov al, '%'
    call writechar
    call crlf

    ; read payment
    mov eax, loan_n
    lea edx, loan_n_dialog
    call read_nzpi
    mov loan_n, eax
    jnc option_selected
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

    mov eax, interest_p
    lea edx, interest_p_dialog
    call read_nzpi
    mov interest_p, eax
    jnc option_selected
    call crlf

    mov eax, interest_r
    lea edx, interest_r_dialog
    call read_nzpf
    mov interest_r, eax
    jnc option_selected
    mov al, '%'
    call writechar
    call crlf

    mov eax, interest_n
    lea edx, interest_n_dialog
    call read_nzpf
    mov interest_n, eax
    jnc option_selected
    call crlf

    mov eax, interest_t
    lea edx, interest_t_dialog
    call read_nzpf
    mov interest_t, eax
    jnc option_selected
    call crlf

    fld interest_n
    fmul interest_t
    fld interest_r
    fdiv float_hundred
    fdiv interest_n

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

    call crlf
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
    call read_string_with_buffer
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
    ; print day
    mov ax, datetime.wday
    call writedec
    mov al, ' '
    call writechar
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
    ; print year
    mov ax, datetime.wyear
    call writedec
    mov al, ASCII_TAB
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

; read line (string ends with ASCII_NEWLINE) to the buffer from a bufferedfile
; edx = offset of bufferedfile
; overwrite ecx
; set eax = number of characters read
; set OF if line does not end with new line and this is the last line
; set CF if line is longer than buffer (call again to read rest of the line)
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
        pop eax
        test cl, cl ; set ZF
        jmp file_read_line_end
    .endif
buffer_find_new_line:
    cmp buffer[esi], ASCII_NEWLINE
    je buffer_new_line_found
    inc esi
    loop buffer_find_new_line

    ; no new line
    pop eax
    .if eax == BUFFER_LENGTH
        or eax, 0 ; clear CF, OF and ZF
        stc
    .else
        or eax, 0 ; clear CF, OF and ZF
        mov cl, 7Fh
        inc cl ; set OF
    .endif
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
    or eax, -1 ; clear CF, OF and ZF
    pop eax

file_read_line_end:
    pop edi
    pop esi
    ret
file_read_line_to_buffer endp

; same as file_read_line_to_buffer but skip the whole line if it's longer than buffer
; set CF if line skipped
file_read_line_fit_buffer proc
    call file_read_line_to_buffer
    jc file_cf
    ret
file_cf:
    call file_read_line_to_buffer
    jc file_cf
    stc
    ret
file_read_line_fit_buffer endp

; eax = handle of the file to write to
; edx = handle of the file to read from
copy_file proc
    local from, to
    mov from, edx
    mov to, eax
    mov eax, edx
    mov ecx, BUFFER_LENGTH
    lea edx, buffer
    call readfromfile
    .while eax != 0
        lea edx, buffer
        mov ecx, eax
        mov eax, to
        call writetofile
        mov eax, from
        mov ecx, BUFFER_LENGTH
        lea edx, buffer
        call readfromfile
    .endw
    ret
copy_file endp

; read string into the buffer
; overwrite eax, edx
; set ecx = length of string (not including 0)
; set ZF if input is empty
read_string_with_buffer proc
    lea edx, buffer
    mov ecx, BUFFER_LENGTH
    call readstring
    mov ecx, eax
    test ecx, ecx
    ret
read_string_with_buffer endp

; read a non-zero positive integer
; eax = current existing nzpi
; edx = string to display
; overwrite ecx, edx
; set eax = non-zero positive integer read, zero if input invalid
; set input_validity
; set CF if current nzpi is non-zero
; set ZF if input invalid
read_nzpi proc
    .if eax == 0
        .if input_validity != VALID_INPUT
            mov eax, edx
            .if input_validity == INVALID_INPUT
                lea edx, nzpi_invalid
            .elseif input_validity == INPUT_EMPTY
                lea edx, nzpi_empty
            .elseif input_validity == INPUT_ZERO
                lea edx, nzpi_invalid
            .elseif input_validity == INPUT_OVERFLOW
                lea edx, nzpi_overflow
            .endif
            call writestring
            call crlf
            mov edx, eax
            mov input_validity, VALID_INPUT
        .endif
        call writestring
        call read_string_with_buffer
        .if ecx == 0
            mov input_validity, INPUT_EMPTY
            jmp nzpi_error
        .endif
        push esi
        mov eax, 0
        mov edx, 0
        mov esi, 0
    read_nzpi_loop:
        ; eax *= 10
        mov edx, eax ; edx = eax
        shl eax, 3 ; eax *= 8
        jc read_nzpi_overflow
        shl edx, 1 ; edx *= 2
        add eax, edx ; eax += edx
        jc read_nzpi_overflow

        ; read next char
        mov edx, 0
        mov dl, buffer[esi]
        .if dl < '0' || dl > '9'
            mov input_validity, INVALID_INPUT
            pop esi
            jmp nzpi_error
        .endif
        sub dl, '0'
        add eax, edx
        jc read_nzpi_overflow
        inc esi
        loop read_nzpi_loop

        ; loop ends
        pop esi
        .if eax == 0
            mov input_validity, INPUT_ZERO
            jmp nzpi_error
        .endif
        ret
    read_nzpi_overflow:
        mov input_validity, INPUT_OVERFLOW
        pop esi
    nzpi_error:
        xor eax, eax ; clear eax, CF and set ZF
        ret
    .else
        call writestring
        call writedec
        test eax, eax ; clear CF and ZF
        stc
        ret
    .endif
read_nzpi endp

; read a non-zero positive float
; eax = current existing nzpf
; edx = string to display
; overwrite ecx, edx
; set eax = non-zero positive float read, zero if input invalid
; set input_validity
; set CF if current nzpf is non-zero
; set ZF if input invalid
read_nzpf proc
    .if eax == 0
        .if input_validity != VALID_INPUT
            mov eax, edx
            .if input_validity == INVALID_INPUT
                lea edx, nzpf_invalid
            .elseif input_validity == INPUT_EMPTY
                lea edx, nzpf_empty
            .elseif input_validity == INPUT_ZERO
                lea edx, nzpf_invalid
            .elseif input_validity == INPUT_OVERFLOW
                lea edx, nzpf_overflow
            .endif
            call writestring
            call crlf
            mov edx, eax
            mov input_validity, VALID_INPUT
        .endif

        call writestring
        call read_string_with_buffer
        .if ecx == 0
            mov input_validity, INPUT_EMPTY
            xor eax, eax ; clear eax, CF and set ZF
            ret
        .endif

        lea edx, buffer
        call str_to_float
        jc read_nzpf_invalid
        .if eax == 0
            mov input_validity, INPUT_ZERO
            xor eax, eax
            ret
        .endif

        mov edx, eax
        shr edx, 23
        sub dl, 127
        cmp dl, 32
        jge read_nzpf_overflow

        test eax, eax ; clear CF and ZF
        ret
    read_nzpf_invalid:
        mov input_validity, INVALID_INPUT
        xor eax, eax
        ret
    read_nzpf_overflow:
        mov input_validity, INPUT_OVERFLOW
        xor eax, eax
        ret
    .else
        call writestring
        mov edx, eax
        call print_float
        mov eax, edx
        test eax, eax ; clear CF and ZF
        stc
        ret
    .endif
read_nzpf endp

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
    dec esi
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
    ret
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
    shr eax, 23
    sub al, 127

    ; check if float >= 2^32
    cmp al, 32
    jge print_float_error

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
