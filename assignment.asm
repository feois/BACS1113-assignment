include irvine32.inc

ReadConsoleOutputCharacterA proto,
    hConsoleOutput: handle,
    lpCharacter: ptr byte,
    nLength: dword,
    dwReadCoord: coord,
    lpNumberOfCharsRead: PTR dword

.data
ASCII_TAB = 9
ASCII_NEWLINE = 10
TAB_OFFSET = 2

console_info console_screen_buffer_info <>
stdout_handle handle ?
datetime systemtime <>
month_str db "JanFebMarAprMayJunJulAugSepOctNovDec"
system_logo db "Super Banking Calculator", ASCII_TAB, 0

; string buffer
BUFFER_LENGTH = 255
buffer db BUFFER_LENGTH + 1 dup (?)

bufferedfile struct
    bf_handle handle ?
    bf_buffer byte BUFFER_LENGTH dup (?)
    bf_len byte 0
bufferedfile ends

; constant
float_ten real4 10.0
float_hundred real4 100.0
; generic variable used to store float (in IEEE single-precision format) temporarily
float_register real4 ?

handle_register1 handle ?
handle_register2 handle ?

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
INPUT_OUT_OF_RANGE = 5
input_validity db VALID_INPUT
nzpi_invalid db "Invalid input! Please enter a non-zero positive integer", 0
nzpi_empty db "Please enter a non-zero positive integer", 0
nzpi_overflow db "Input too large!", 0
nzpf_invalid db "Invalid input! Please enter a non-zero positive decimal", 0
nzpf_empty db "Please enter a non-zero positive decimal", 0
nzpf_overflow db "Input too large!", 0
menu_invalid_input db "Invalid input!", 0

menu_dialog db TAB_OFFSET dup (ASCII_TAB), "Main Menu", 0
menu_username_dialog db "Currently logged in as: ", 0

option_loan db "Compute loan EMI (Estimated Monthly Instalment)", 0
option_interest db "Compute compound interest", 0
option_debt db "Compute Debt-to-Interest ratio", 0
option_summary db "Summary Report", 0
option_logout db "Log out", 0
option_exit db "Exit", 0
options dd offset option_loan, offset option_interest, offset option_debt, offset option_summary, offset option_logout, offset option_exit
option_dialog db "Press 1~", '0' + lengthof options, " for the respective option: ", 0
selected_option dd ?

summary_save_dialog db "Do you want to save the result of this calculation?", 0
summary_save_yes_dialog db "Press y/Y to save and return to main menu", 0
summary_save_no_dialog db "Press n/N to return to main menu without saving", 0
summary_print_dialog db "Do you want to print the report to a file?", 0
summary_print_yes_dialog db "Press y/Y to print", 0
summary_print_no_dialog db "Press n/N to return to main menu", 0
summary_print_file_dialog db "Save to file (empty input to cancel): ", 0

summary_loan_dialog db "Loan EMI (Estimated Monthly Instalment):", 0
summary_interest_dialog db "Compound interest:", 0
summary_debt_dialog db "Debt-to-Interest ratio", 0
summary_empty_dialog db "No data", 0
summary_wait_dialog db "Press any key to return to main menu", 0
summary_print_success_dialog db "Report was successfully printed!", 0
summary_print_failure_dialog db "Report failed to be printed!", 0

SUMMARY_STATE_NONE = 0
SUMMARY_STATE_PRINT_ASK_FILENAME = 1
SUMMARY_STATE_PRINT_PROCESS = 2
SUMMARY_STATE_PRINT_SUCCESS = 3
SUMMARY_STATE_PRINT_FAILURE = 4

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
interest_r_dialog db "Annual interest rate (in %): ", 0
interest_n_dialog db "Compounding frequency per year (e.g. 1: annually, 12: monthly, 52: weekly, 365: daily): ", 0
interest_t_dialog db "Time in years: ", 0
interest_p dd 0
interest_r real4 0.0
interest_n dd 0
interest_t real4 0.0
interest_dialog db "Final amount: RM ", 0

;HOCHEEHIN
debt_payment_dialog db      "Total monthly debt payment: RM ", 0
gross_income_dialog       db      "Gross monthly income: RM ", 0
dti_result_dialog   db      "Debt-to-Income Ratio (rounded): ", 0
dti_approve         db      "Loan approved (DTI <= 36%)", 0
dti_reject          db      "Loan rejected (DTI > 36%)", 0
dti_threshold       real4   36.0
debt_payment        dd      0
gross_income        dd      0

summary_loan_p dd 0
summary_loan_r real4 0.0
summary_loan_n dd 0
summary_loan real4 0.0
summary_interest_p dd 0
summary_interest_r real4 0.0
summary_interest_n dd 0
summary_interest_t real4 0.0
summary_interest real4 0.0
summary_debt_payment dd 0
summary_gross_income dd 0
summary_dti real4 0.0
summary_debt_decision db 0 ; 0 = approved
summary_state db SUMMARY_STATE_NONE

coordinate coord <0, 0>
char_read dd 0

.code
main proc
main_start:
    invoke getstdhandle, STD_OUTPUT_HANDLE
    mov stdout_handle, eax
    invoke getconsolescreenbufferinfo, stdout_handle, offset console_info

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
    mov buffer[ecx], 0
    invoke str_copy, offset buffer, offset username

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
        mov buffer[eax], 0
        invoke str_compare, offset buffer, offset username
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
    mov buffer[ecx], 0
    invoke str_copy, offset buffer, offset password

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
    mov buffer[eax], 0
    invoke str_copy, offset buffer, offset password

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
        mov buffer[eax], 0
        invoke str_compare, offset buffer, offset password
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
    call crlf

    ; check for errors
    .if input_validity != VALID_INPUT
        lea edx, menu_invalid_input
        call writestring
        call crlf
    .endif
    ; ask for option selection
    lea edx, option_dialog
    call writestring
    call readchar
    ; check input validity
    .if al < '1' || al > '0' + lengthof options
        mov input_validity, INVALID_INPUT
        jmp menu
    .endif
    mov edx, 0
    mov dl, al
    sub dl, '1'
    mov eax, [options + edx * type options]
    mov selected_option, eax
    mov input_validity, VALID_INPUT
option_selected:
    call clear
    mov ecx, TAB_OFFSET
    test ecx, ecx
    jz tab_offset_loop_end
    mov al, ASCII_TAB
tab_offset_loop:
    call writechar
    loop tab_offset_loop
tab_offset_loop_end:
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
    cmp edx, offset option_summary
    je summary
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
    push eax
    call print_float
    call crlf

    call ask_summary_save
    jz loan_reset
    mov eax, loan_p
    mov summary_loan_p, eax
    mov eax, loan_r
    mov summary_loan_r, eax
    mov eax, loan_n
    mov summary_loan_n, eax
    pop eax
    mov summary_loan, eax
loan_reset:
    mov loan_p, 0
    mov loan_r, 0
    mov loan_n, 0
    jmp menu
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
    call read_nzpi
    mov interest_n, eax
    jnc option_selected
    call crlf

    mov eax, interest_t
    lea edx, interest_t_dialog
    call read_nzpf
    mov interest_t, eax
    jnc option_selected
    call crlf

    fild interest_n
    fmul interest_t
    fld interest_r
    fdiv float_hundred
    fidiv interest_n

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
    push eax
    call print_float
    call crlf

    call ask_summary_save
    jz interest_reset
    mov eax, interest_p
    mov summary_interest_p, eax
    mov eax, interest_r
    mov summary_interest_r, eax
    mov eax, interest_n
    mov summary_interest_n, eax
    mov eax, interest_t
    mov summary_interest_t, eax
    pop eax
    mov summary_interest, eax
interest_reset:
    mov interest_p, 0
    mov interest_r, 0
    mov interest_n, 0
    mov interest_t, 0
    jmp menu

;HOCHEEHIN
debt:
    lea edx, values_dialog
    call writestring
    call crlf

    mov eax, debt_payment
    lea edx, debt_payment_dialog
    call read_nzpi
    mov debt_payment, eax
    jnc option_selected
    call crlf

    mov eax, gross_income
    lea edx, gross_income_dialog
    call read_nzpi
    mov gross_income, eax
    jnc option_selected
    call crlf

    fild debt_payment
    fidiv gross_income
    fmul float_hundred
    fst float_register

    call crlf
    lea edx, dti_result_dialog
    call writestring
    mov eax, float_register
    push eax
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
    mov summary_debt_decision, 1
    jmp print_loan_decision
loan_approved:
    mov summary_debt_decision, 0
    lea edx, dti_approve
print_loan_decision:
    call writestring
    call crlf

    call ask_summary_save
    jz debt_reset
    mov eax, debt_payment
    mov summary_debt_payment, eax
    mov eax, gross_income
    mov summary_gross_income, eax
    pop eax
    mov summary_dti, eax
debt_reset:
    mov debt_payment, 0
    mov gross_income, 0
    jmp menu
summary:
    .if summary_loan != 0
        lea edx, summary_loan_dialog
        call writestring
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, loan_p_dialog
        call writestring
        mov eax, summary_loan_p
        call writedec
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, loan_r_dialog
        call writestring
        mov eax, summary_loan_r
        call print_float
        mov al, '%'
        call writechar
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, loan_n_dialog
        call writestring
        mov eax, summary_loan_n
        call writedec
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, summary_loan_dialog
        call writestring
        mov al, ' '
        call writechar
        mov al, 'R'
        call writechar
        mov al, 'M'
        call writechar
        mov al, ' '
        call writechar
        mov eax, summary_loan
        call print_float
        call crlf
        call crlf
    .endif

    .if summary_interest != 0
        lea edx, summary_interest_dialog
        call writestring
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, interest_p_dialog
        call writestring
        mov eax, summary_interest_p
        call writedec
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, interest_r_dialog
        call writestring
        mov eax, summary_interest_r
        call print_float
        mov al, '%'
        call writechar
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, interest_n_dialog
        call writestring
        mov eax, summary_interest_n
        call writedec
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, interest_t_dialog
        call writestring
        mov eax, summary_interest_t
        call print_float
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, summary_interest_dialog
        call writestring
        mov al, ' '
        call writechar
        mov al, 'R'
        call writechar
        mov al, 'M'
        call writechar
        mov al, ' '
        call writechar
        mov eax, summary_interest
        call print_float
        call crlf
        call crlf
    .endif

    .if summary_dti != 0
        lea edx, summary_debt_dialog
        call writestring
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, debt_payment_dialog
        call writestring
        mov eax, summary_debt_payment
        call writedec
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, gross_income_dialog
        call writestring
        mov eax, summary_gross_income
        call writedec
        call crlf

        mov al, ASCII_TAB
        call writechar
        lea edx, dti_result_dialog
        call writestring
        mov eax, summary_dti
        call print_float
        mov al, '%'
        call writechar
        call crlf

        mov al, ASCII_TAB
        call writechar
        .if summary_debt_decision == 0
            lea edx, dti_approve
        .else
            lea edx, dti_reject
        .endif
        call writestring
        call crlf
        call crlf
    .endif

    .if summary_state == SUMMARY_STATE_NONE
        .if summary_loan == 0 && summary_interest == 0 && summary_dti == 0
            lea edx, summary_empty_dialog
            call writestring
            call crlf
            call crlf
        .else
            lea edx, summary_print_dialog
            call writestring
            call crlf
            lea edx, summary_print_yes_dialog
            call writestring
            call crlf
            lea edx, summary_print_no_dialog
            call writestring
            call crlf
        ask_print_loop:
            call readchar
            .if al == 'y' || al == 'Y'
                mov summary_state, SUMMARY_STATE_PRINT_ASK_FILENAME
                jmp option_selected
            .elseif al == 'n' || al == 'N'
                jmp menu
            .endif
            jmp ask_print_loop
        .endif
    .elseif summary_state == SUMMARY_STATE_PRINT_ASK_FILENAME
        lea edx, summary_print_file_dialog
        call writestring
        call read_string_with_buffer
        mov buffer[ecx], 0
        lea edx, buffer
        call createoutputfile
        mov handle_register1, eax
        .if eax == INVALID_HANDLE_VALUE
            mov summary_state, SUMMARY_STATE_PRINT_FAILURE
            jmp option_selected
        .endif
        mov summary_state, SUMMARY_STATE_PRINT_PROCESS
        jmp option_selected
    .elseif summary_state == SUMMARY_STATE_PRINT_PROCESS
        mov coordinate.x, 0
        mov coordinate.y, 0
    read_screen:
        call read_console
        jz read_screen_end
        jc read_screen_line
        mov eax, handle_register1
        lea edx, buffer
        call writetofile
        jmp read_screen
    read_screen_line:
        mov eax, handle_register1
        lea edx, buffer
        mov buffer[ecx], ASCII_NEWLINE
        inc ecx
        call writetofile
        jmp read_screen
    read_screen_end:
        mov eax, handle_register1
        call closefile
        mov summary_state, SUMMARY_STATE_PRINT_SUCCESS
        jmp option_selected
    .elseif summary_state == SUMMARY_STATE_PRINT_SUCCESS
        lea edx, summary_print_success_dialog
        call writestring
        call crlf
    .elseif summary_state == SUMMARY_STATE_PRINT_FAILURE
        lea edx, summary_print_failure_dialog
        call writestring
        call crlf
    .endif

    lea edx, summary_wait_dialog
    call writestring
    call crlf
    call readchar
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

; read console screen into the buffer
; coordinate = coord to start to read from
; overwrite eax
; set coordinate = coord to continue reading
; set ecx = number of characters read
; set ZF if no character read
; set CF if a line is completely read
read_console proc
    mov eax, 0
    mov ax, console_info.dwSize.x
    sub ax, coordinate.x
    .if ax > BUFFER_LENGTH
        invoke readconsoleoutputcharactera, stdout_handle, offset buffer, BUFFER_LENGTH, coordinate, offset char_read
        add coordinate.x, BUFFER_LENGTH
        mov ecx, char_read
        test ecx, ecx
        clc
    .else
        invoke readconsoleoutputcharactera, stdout_handle, offset buffer, eax, coordinate, offset char_read
        mov coordinate.x, 0
        inc coordinate.y
        mov ecx, char_read
        test ecx, ecx
        stc
    .endif
    ret
read_console endp

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

; repeatedly asks yes or no
; overwrite al
; set ZF if y or Y is pressed
; clear ZF if n or N is pressed
ask_yes_no proc
ask_loop:
    call readchar
    .if al == 'y' || al == 'Y'
        test al, al ; clear ZF
        ret
    .elseif al == 'n' || al == 'N'
        xor al, al ; set zf
        ret
    .endif
    jmp ask_loop
ask_yes_no endp

; asks to save summary or not
ask_summary_save proc
    call crlf
    lea edx, summary_save_dialog
    call writestring
    call crlf
    lea edx, summary_save_yes_dialog
    call writestring
    call crlf
    lea edx, summary_save_no_dialog
    call writestring
    call crlf
    call ask_yes_no
    ret
ask_summary_save endp

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
