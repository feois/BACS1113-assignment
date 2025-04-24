include irvine32.inc

ReadConsoleOutputCharacterA PROTO,
    hConsoleOutput:         HANDLE,
    lpCharacter:            PTR BYTE,
    nLength:                DWORD,
    dwReadCoord:            COORD,
    lpNumberOfCharsRead:    PTR DWORD

.data
ASCII_TAB       = 9
ASCII_NEWLINE   = 10
TAB_OFFSET      = 2

console_info    CONSOLE_SCREEN_BUFFER_INFO  <>
stdout_handle   HANDLE                      ?
datetime        SYSTEMTIME                  <>
month_str       BYTE                        "JanFebMarAprMayJunJulAugSepOctNovDec"
system_logo     BYTE                        "Super Banking Calculator", ASCII_TAB, 0

; string buffer
BUFFER_LENGTH   = 10000
buffer          BYTE BUFFER_LENGTH + 1 dup (?)

; constant
float_ten       REAL4 10.0
float_hundred   REAL4 100.0
; generic variable used to store float (in IEEE single-precision format) temporarily
float_register  REAL4 ?

file_register   HANDLE ?

account_filename    BYTE    "accounts", 0
account_backup      BYTE    "accounts.bak", 0
account_buffer      BYTE    BUFFER_LENGTH dup (?)
account_buffer_len  DWORD   0
username            BYTE    BUFFER_LENGTH dup (?), 0
username_length     DWORD   ?
password            BYTE    BUFFER_LENGTH dup (?), 0
password_length     DWORD   ?
MAX_ATTEMPTS        = 3
attempts            DWORD   ?

login_dialog                BYTE "Login/Register", 0
cancel_dialog               BYTE "Enter empty input to exit", 0
username_dialog             BYTE "Username: ", 0
password_dialog             BYTE "Password: ", 0
new_account_dialog          BYTE "This username does not exist, a new account will be created", 0
attempt_dialog_1            BYTE "You can only attempt 3 times! (", 0
attempt_dialog_2            BYTE " more times left)", 0
attempt_fail_dialog         BYTE "You have been temporarily locked out of the system due to too many incorrect password attempts", 0
invalid_account_file_dialog BYTE "Error: Account database is invalid", 0

VALID_INPUT         = 0
INVALID_INPUT       = 1
INPUT_EMPTY         = 2
INPUT_ZERO          = 3
INPUT_OVERFLOW      = 4
INPUT_OUT_OF_RANGE  = 5
input_validity      BYTE VALID_INPUT
nzpi_invalid        BYTE "Invalid input! Please enter a non-zero positive integer", 0
nzpi_empty          BYTE "Please enter a non-zero positive integer", 0
nzpi_overflow       BYTE "Input too large! (Cannot be larger than 4294967295)", 0
nzpf_invalid        BYTE "Invalid input! Please enter a non-zero positive decimal", 0
nzpf_empty          BYTE "Please enter a non-zero positive decimal", 0
nzpf_overflow       BYTE "Input too large! (Cannot be larger than 4294967167)", 0
menu_invalid_input  BYTE "Invalid input!", 0

menu_dialog             BYTE "Main Menu", 0
menu_username_dialog    BYTE "Currently logged in as: ", 0

option_loan     BYTE    "Compute loan EMI (Estimated Monthly Instalment)", 0
option_interest BYTE    "Compute compound interest", 0
option_debt     BYTE    "Compute Debt-to-Interest ratio", 0
option_summary  BYTE    "Summary Report", 0
option_logout   BYTE    "Log out", 0
option_exit     BYTE    "Exit", 0
options         DWORD   offset option_loan,
                        offset option_interest,
                        offset option_debt,
                        offset option_summary,
                        offset option_logout,
                        offset option_exit
option_dialog   BYTE    "Press 1~", '0' + lengthof options, " for the respective option: ", 0

summary_save_dialog         BYTE "Do you want to save the result of this calculation?", 0
summary_overwrite_dialog    BYTE "An existing calculation is already saved, do you want to save by overwriting the existing calculation?", 0
summary_save_yes_dialog     BYTE "Press y/Y to save and return to main menu", 0
summary_save_no_dialog      BYTE "Press n/N to return to main menu without saving", 0
summary_print_dialog        BYTE "Do you want to print the report to a file?", 0
summary_print_yes_dialog    BYTE "Press y/Y to print", 0
summary_print_no_dialog     BYTE "Press n/N to return to main menu", 0
summary_print_file_dialog   BYTE "Save to file (empty input to cancel): ", 0

summary_loan_dialog             BYTE "Loan EMI (Estimated Monthly Instalment):", 0
summary_interest_dialog         BYTE "Compound interest:", 0
summary_debt_dialog             BYTE "Debt-to-Interest ratio", 0
summary_empty_dialog            BYTE "No data", 0
summary_wait_dialog             BYTE "Press any key to return to main menu", 0
summary_print_success_dialog    BYTE "Report was successfully printed!", 0
summary_print_failure_dialog    BYTE "Report failed to be printed!", 0

SUMMARY_STATE_NONE                  = 0
SUMMARY_STATE_PRINT_ASK_FILENAME    = 1
SUMMARY_STATE_PRINT_PROCESS         = 2
SUMMARY_STATE_PRINT_SUCCESS         = 3
SUMMARY_STATE_PRINT_FAILURE         = 4

values_dialog   BYTE "Please enter the following values", 0

loan_p_dialog   BYTE    "Principal: RM ", 0
loan_r_dialog   BYTE    "Monthly interest rate (in %): ", 0
loan_n_dialog   BYTE    "Number of payments: ", 0
loan_p          DWORD   0
loan_r          REAL4   0.0
loan_n          DWORD   0
loan_dialog     BYTE    "Estimated Monthly Instalment: RM ", 0

interest_p_dialog   BYTE    "Principal: RM ", 0
interest_r_dialog   BYTE    "Annual interest rate (in %): ", 0
interest_n_dialog   BYTE    "Compounding frequency per year (e.g. 1: annually, 12: monthly, 52: weekly, 365: daily): ", 0
interest_t_dialog   BYTE    "Time in years: ", 0
interest_p          DWORD   0
interest_r          REAL4   0.0
interest_n          DWORD   0
interest_t          REAL4   0.0
interest_dialog     BYTE    "Final amount: RM ", 0

;HOCHEEHIN
debt_payment_dialog BYTE    "Total monthly debt payment: RM ", 0
gross_income_dialog BYTE    "Gross monthly income: RM ", 0
dti_result_dialog   BYTE    "Debt-to-Income Ratio (rounded): ", 0
dti_approve         BYTE    "Loan approved (DTI <= 36%)", 0
dti_reject          BYTE    "Loan rejected (DTI > 36%)", 0
dti_threshold       REAL4   36.0
debt_payment        DWORD   0
gross_income        DWORD   0

summary_loan_p          DWORD   0
summary_loan_r          REAL4   0.0
summary_loan_n          DWORD   0
summary_loan            REAL4   0.0
summary_interest_p      DWORD   0
summary_interest_r      REAL4   0.0
summary_interest_n      DWORD   0
summary_interest_t      REAL4   0.0
summary_interest        REAL4   0.0
summary_debt_payment    DWORD   0
summary_gross_income    DWORD   0
summary_dti             REAL4   0.0
summary_debt_decision   BYTE    0 ; 0 = approved
summary_state           BYTE    SUMMARY_STATE_NONE

coordinate  COORD   <0, 0>
char_read   DWORD   0

exit_dialog BYTE    "Thank you for using this application", 0

.code
main PROC
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov stdout_handle, eax
    invoke GetConsoleScreenBufferInfo, stdout_handle, offset console_info

main_start:
    ; print login screen
    mov attempts, MAX_ATTEMPTS
    lea edx, login_dialog
    call Clear_And_Print_Header
    lea edx, cancel_dialog
    call WriteString
    call CrLf

    ; ask for username
    lea edx, username_dialog
    call WriteString
    call Read_String_To_Buffer
    jz main_end

    ; copy username from buffer
    mov username_length, ecx
    mov buffer[ecx], 0
    invoke Str_Copy, offset buffer, offset username

    ; open and read account database
    lea edx, account_filename
    call OpenInputFile

    ; check if file not exist
    cmp eax, INVALID_HANDLE_VALUE
    je register
    mov file_register, eax
find_username:
    ; read a line from account database
    mov eax, file_register
    lea edx, account_buffer
    mov ecx, account_buffer_len
    call File_Read_Line_To_Buffer_And_Skip_Line_If_Larger
    mov account_buffer_len, ecx
    jc invalid_account_file
    jo invalid_account_file
    jz register ; reach the end of file already
    dec eax ; ignore new line

    ; check if line is the username we are looking for
    .if eax == username_length
        mov buffer[eax], 0
        invoke Str_Compare, offset buffer, offset username
        je login
    .endif

    ; read another line to skip the password
    mov eax, file_register
    lea edx, account_buffer
    mov ecx, account_buffer_len
    call File_Read_Line_To_Buffer_And_Skip_Line_If_Larger
    mov account_buffer_len, ecx
    jmp find_username
invalid_account_file:
    mov eax, file_register
    call CloseFile
    mov edx, 0
    call Clear_And_Print_Header
    lea edx, invalid_account_file_dialog
    call WriteString
    call CrLf
    exit
register:
    ; ask for password
    lea edx, new_account_dialog
    call WriteString
    call CrLf
    lea edx, password_dialog
    call WriteString
    call Read_String_To_Buffer
    jz main_end

    ; copy password from buffer
    mov password_length, ecx
    mov buffer[ecx], 0
    invoke Str_Copy, offset buffer, offset password

    ; close account database if it exists
    mov eax, file_register
    .if eax != INVALID_HANDLE_VALUE
        call CloseFile
    .endif

    ; append file
    invoke CreateFile, offset account_filename, FILE_APPEND_DATA, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov file_register, eax

    ; write username
    lea edx, username
    mov ecx, username_length
    mov username[ecx], ASCII_NEWLINE
    inc ecx
    call WriteToFile
    mov ecx, username_length
    mov username[ecx], 0

    ; write password
    mov eax, file_register
    lea edx, password
    mov ecx, password_length
    mov password[ecx], ASCII_NEWLINE
    inc ecx
    call WriteToFile
    mov ecx, password_length
    mov password[ecx], 0

    ; close file
    mov eax, file_register
    call CloseFile
    jmp menu
login:
    ; read the password
    mov eax, file_register
    lea edx, account_buffer
    mov ecx, account_buffer_len
    call File_Read_Line_To_Buffer_And_Skip_Line_If_Larger
    mov account_buffer_len, ecx
    jc invalid_account_file
    jz invalid_account_file
    dec eax ; ignore new line

    ; copy password from buffer
    mov password_length, eax
    mov buffer[eax], 0
    invoke Str_Copy, offset buffer, offset password

    ; close database
    mov eax, file_register
    call CloseFile
login_attempt:
    ; print login screen
    lea edx, login_dialog
    call Clear_And_Print_Header
    lea edx, username_dialog
    call WriteString
    lea edx, username
    call WriteString
    call CrLf

    ; check if not first attempt
    .if attempts != MAX_ATTEMPTS
        lea edx, attempt_dialog_1
        call WriteString
        mov eax, attempts
        call WriteDec
        lea edx, attempt_dialog_2
        call WriteString
        call CrLf
    .endif

    ; ask for password
    lea edx, password_dialog
    call WriteString
    call Read_String_To_Buffer

    ; check password
    .if eax == password_length
        mov buffer[eax], 0
        invoke Str_Compare, offset buffer, offset password
        je menu
    .endif

    ; incorrect password
    dec attempts
    jz login_fail
    jmp login_attempt
login_fail:
    mov edx, 0
    call Clear_And_Print_Header
    lea edx, attempt_fail_dialog
    call WriteString
    call CrLf
    exit
menu:
    lea edx, menu_dialog
    call Clear_And_Print_Header
    ; print username
    lea edx, menu_username_dialog
    call WriteString
    lea edx, username
    call WriteString
    call CrLf
    call CrLf
    mov ecx, lengthof options
    mov esi, 0
menu_loop:
    ; print all options
    mov edx, [options + esi * 4]
    inc esi
    mov eax, esi
    call WriteDec
    mov al, ')'
    call WriteChar
    mov al, ' '
    call WriteChar
    call WriteString
    call CrLf
    loop menu_loop
    call CrLf

    ; check for errors
    .if input_validity != VALID_INPUT
        lea edx, menu_invalid_input
        call WriteString
        call CrLf
    .endif
    ; ask for option selection
    lea edx, option_dialog
    call WriteString
    call ReadChar
    ; check input validity
    .if al < '1' || al > '0' + lengthof options
        mov input_validity, INVALID_INPUT
        jmp menu
    .endif
    mov ecx, 0
    mov cl, al
    sub cl, '1'
    mov edx, [options + ecx * type options]
    mov input_validity, VALID_INPUT
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
    lea edx, option_loan
    call Clear_And_Print_Header
    lea edx, values_dialog
    call WriteString
    call CrLf

    ; read principal
    mov eax, loan_p
    lea edx, loan_p_dialog
    call Read_Nzpi
    mov loan_p, eax
    jnc loan
    call CrLf

    ; read rate
    mov eax, loan_r
    lea edx, loan_r_dialog
    call Read_Nzpf
    mov loan_r, eax
    jnc loan
    mov al, '%'
    call WriteChar
    call CrLf

    ; read payment
    mov eax, loan_n
    lea edx, loan_n_dialog
    call Read_Nzpi
    mov loan_n, eax
    jnc loan
    call CrLf

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
    call CrLf
    lea edx, loan_dialog
    call WriteString
    mov eax, float_register
    push eax
    call Print_Float
    call CrLf

    mov eax, summary_loan
    call Ask_Save_Summary
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
    lea edx, option_interest
    call Clear_And_Print_Header
    lea edx, values_dialog
    call WriteString
    call CrLf

    mov eax, interest_p
    lea edx, interest_p_dialog
    call Read_Nzpi
    mov interest_p, eax
    jnc interest
    call CrLf

    mov eax, interest_r
    lea edx, interest_r_dialog
    call Read_Nzpf
    mov interest_r, eax
    jnc interest
    mov al, '%'
    call WriteChar
    call CrLf

    mov eax, interest_n
    lea edx, interest_n_dialog
    call Read_Nzpi
    mov interest_n, eax
    jnc interest
    call CrLf

    mov eax, interest_t
    lea edx, interest_t_dialog
    call Read_Nzpf
    mov interest_t, eax
    jnc interest
    call CrLf

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

    call CrLf
    lea edx, interest_dialog
    call WriteString
    mov eax, float_register
    push eax
    call Print_Float
    call CrLf

    mov eax, summary_interest
    call Ask_Save_Summary
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
    lea edx, option_debt
    call Clear_And_Print_Header
    lea edx, values_dialog
    call WriteString
    call CrLf

    mov eax, debt_payment
    lea edx, debt_payment_dialog
    call Read_Nzpi
    mov debt_payment, eax
    jnc debt
    call CrLf

    mov eax, gross_income
    lea edx, gross_income_dialog
    call Read_Nzpi
    mov gross_income, eax
    jnc debt
    call CrLf

    fild debt_payment
    fidiv gross_income
    fmul float_hundred
    fst float_register

    call CrLf
    lea edx, dti_result_dialog
    call WriteString
    mov eax, float_register
    push eax
    call Print_Float
    mov al, '%'
    call WriteChar
    call CrLf

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
    call WriteString
    call CrLf

    mov eax, summary_dti
    call Ask_Save_Summary
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
    lea edx, option_summary
    call Clear_And_Print_Header

    .if summary_loan != 0
        lea edx, summary_loan_dialog
        call WriteString
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, loan_p_dialog
        call WriteString
        mov eax, summary_loan_p
        call WriteDec
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, loan_r_dialog
        call WriteString
        mov eax, summary_loan_r
        call Print_Float
        mov al, '%'
        call WriteChar
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, loan_n_dialog
        call WriteString
        mov eax, summary_loan_n
        call WriteDec
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, summary_loan_dialog
        call WriteString
        mov al, ' '
        call WriteChar
        mov al, 'R'
        call WriteChar
        mov al, 'M'
        call WriteChar
        mov al, ' '
        call WriteChar
        mov eax, summary_loan
        call Print_Float
        call CrLf
        call CrLf
    .endif

    .if summary_interest != 0
        lea edx, summary_interest_dialog
        call WriteString
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, interest_p_dialog
        call WriteString
        mov eax, summary_interest_p
        call WriteDec
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, interest_r_dialog
        call WriteString
        mov eax, summary_interest_r
        call Print_Float
        mov al, '%'
        call WriteChar
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, interest_n_dialog
        call WriteString
        mov eax, summary_interest_n
        call WriteDec
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, interest_t_dialog
        call WriteString
        mov eax, summary_interest_t
        call Print_Float
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, summary_interest_dialog
        call WriteString
        mov al, ' '
        call WriteChar
        mov al, 'R'
        call WriteChar
        mov al, 'M'
        call WriteChar
        mov al, ' '
        call WriteChar
        mov eax, summary_interest
        call Print_Float
        call CrLf
        call CrLf
    .endif

    .if summary_dti != 0
        lea edx, summary_debt_dialog
        call WriteString
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, debt_payment_dialog
        call WriteString
        mov eax, summary_debt_payment
        call WriteDec
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, gross_income_dialog
        call WriteString
        mov eax, summary_gross_income
        call WriteDec
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        lea edx, dti_result_dialog
        call WriteString
        mov eax, summary_dti
        call Print_Float
        mov al, '%'
        call WriteChar
        call CrLf

        mov al, ASCII_TAB
        call WriteChar
        .if summary_debt_decision == 0
            lea edx, dti_approve
        .else
            lea edx, dti_reject
        .endif
        call WriteString
        call CrLf
        call CrLf
    .endif

    .if summary_state == SUMMARY_STATE_NONE
        .if summary_loan == 0 && summary_interest == 0 && summary_dti == 0
            lea edx, summary_empty_dialog
            call WriteString
            call CrLf
            call CrLf
        .else
            lea edx, summary_print_dialog
            call WriteString
            call CrLf
            lea edx, summary_print_yes_dialog
            call WriteString
            call CrLf
            lea edx, summary_print_no_dialog
            call WriteString
            call CrLf
        ask_print_loop:
            call ReadChar
            .if al == 'y' || al == 'Y'
                mov summary_state, SUMMARY_STATE_PRINT_ASK_FILENAME
                jmp summary
            .elseif al == 'n' || al == 'N'
                jmp menu
            .endif
            jmp ask_print_loop
        .endif
    .elseif summary_state == SUMMARY_STATE_PRINT_ASK_FILENAME
        lea edx, summary_print_file_dialog
        call WriteString
        call Read_String_To_Buffer
        mov buffer[ecx], 0
        lea edx, buffer
        call CreateOutputFile
        mov file_register, eax
        .if eax == INVALID_HANDLE_VALUE
            mov summary_state, SUMMARY_STATE_PRINT_FAILURE
            jmp summary
        .endif
        mov summary_state, SUMMARY_STATE_PRINT_PROCESS
        jmp summary
    .elseif summary_state == SUMMARY_STATE_PRINT_PROCESS
        mov coordinate.x, 0
        mov coordinate.y, 0
    read_screen:
        call Read_Console_To_Buffer
        jz read_screen_end
        jc read_screen_line
        mov eax, file_register
        lea edx, buffer
        call WriteToFile
        jmp read_screen
    read_screen_line:
        mov eax, file_register
        lea edx, buffer
        mov buffer[ecx], ASCII_NEWLINE
        inc ecx
        call WriteToFile
        jmp read_screen
    read_screen_end:
        mov eax, file_register
        call CloseFile
        mov summary_state, SUMMARY_STATE_PRINT_SUCCESS
        jmp summary
    .elseif summary_state == SUMMARY_STATE_PRINT_SUCCESS
        lea edx, summary_print_success_dialog
        call WriteString
        call CrLf
    .elseif summary_state == SUMMARY_STATE_PRINT_FAILURE
        lea edx, summary_print_failure_dialog
        call WriteString
        call CrLf
    .endif

    lea edx, summary_wait_dialog
    call WriteString
    call CrLf
    call ReadChar
    mov summary_state, SUMMARY_STATE_NONE
    jmp menu
main_end:
    mov edx, 0
    call Clear_And_Print_Header

    lea edx, exit_dialog
    call WriteString
    call CrLf

    exit
main ENDP

; clear screen and print logo and time
; edx = header, 0 if no header
; overwrite eax, ecx and edx
Clear_And_Print_Header PROC
    push edx
    call ClrScr
    ; print logo
    lea edx, system_logo
    call WriteString
    ; get time
    lea edx, datetime
    push edx
    call GetLocalTime
    ; print day
    mov ax, datetime.wDay
    call WriteDec
    mov al, ' '
    call WriteChar
    ; print month
    mov dx, datetime.wMonth
    mov ax, dx
    add ax, dx
    add ax, dx
    lea edx, month_str
    lea edx, [edx + eax - 3]
    mov al, [edx]
    call WriteChar
    mov al, [edx + 1]
    call WriteChar
    mov al, [edx + 2]
    call WriteChar
    mov al, ' '
    call WriteChar
    ; print year
    mov ax, datetime.wYear
    call WriteDec
    mov al, ASCII_TAB
    call WriteChar
    ; print hour
    mov ax, datetime.wHour
    call Print_Two_Digits
    mov al, ':'
    call WriteChar
    ; print minute
    mov ax, datetime.wMinute
    call Print_Two_Digits
    mov al, ':'
    call WriteChar
    ; print second
    mov ax, datetime.wSecond
    call Print_Two_Digits

    call CrLf
    call CrLf

    ; print header
    pop edx
    .if edx != 0
        mov ecx, TAB_OFFSET
        .if ecx > 0
            mov al, ASCII_TAB
        tab_offset_loop:
            call WriteChar
            loop tab_offset_loop
        .endif
        call WriteString
        call CrLf
        call CrLf
    .endif

    ret
Clear_And_Print_Header ENDP

; read line (string ends with ASCII_NEWLINE) to the buffer
; eax = file handle
; cl = length of file buffer
; edx = offset of file buffer
; set eax = number of characters read
; set ecx = new length of file buffer
; set OF if line does not end with new line and this is the last line
; set CF if line is longer than buffer (call again to read rest of the line)
; set ZF if nothing to read
File_Read_Line_To_Buffer PROC
    local file_handle: HANDLE, file_buffer: PTR BYTE, file_len: DWORD
    push esi
    push edi

    mov file_handle, eax
    mov file_buffer, edx
    mov file_len, ecx

    ; copy to buffer
    mov esi, 0
    test ecx, ecx
    jz file_buffer_empty
file_copy_to_buffer:
    mov al, [edx + esi]
    mov buffer[esi], al
    inc esi
    loop file_copy_to_buffer

file_buffer_empty:
    mov file_len, 0

    ; read from file
    mov eax, file_handle
    mov ecx, BUFFER_LENGTH
    sub ecx, esi
    lea edx, buffer[esi]
    call ReadFromFile

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

    ; copy to file buffer
buffer_new_line_found:
    inc esi
    pop ecx
    push esi
    mov edi, 0
    sub ecx, esi
    mov file_len, ecx

    .if ecx > 0
        mov edx, file_buffer
    file_copy_from_buffer:
        mov al, buffer[esi]
        mov [edx + edi], al
        inc edi
        inc esi
        loop file_copy_from_buffer
    .endif
    or eax, -1 ; clear CF, OF and ZF
    pop eax

file_read_line_end:
    pop edi
    pop esi
    mov ecx, file_len
    ret
File_Read_Line_To_Buffer ENDP

; same as File_Read_Line_To_Buffer but skip the whole line if it's longer than buffer
; set CF if line skipped
File_Read_Line_To_Buffer_And_Skip_Line_If_Larger PROC
    call File_Read_Line_To_Buffer
    jc file_cf
    ret
file_cf:
    call File_Read_Line_To_Buffer
    jc file_cf
    stc
    ret
File_Read_Line_To_Buffer_And_Skip_Line_If_Larger ENDP

; read string into the buffer
; overwrite eax, edx
; set ecx = length of string (not including 0)
; set ZF if input is empty
Read_String_To_Buffer PROC
    lea edx, buffer
    mov ecx, BUFFER_LENGTH
    call ReadString
    mov ecx, eax
    test ecx, ecx
    ret
Read_String_To_Buffer ENDP

; read console screen into the buffer
; coordinate = coord to start to read from
; overwrite eax
; set coordinate = coord to continue reading
; set ecx = number of characters read
; set ZF if no character read
; set CF if a line is completely read
Read_Console_To_Buffer PROC
    mov eax, 0
    mov ax, console_info.dwSize.x
    sub ax, coordinate.x
    .if ax > BUFFER_LENGTH
        invoke ReadConsoleOutputCharacterA, stdout_handle, offset buffer, BUFFER_LENGTH, coordinate, offset char_read
        add coordinate.x, BUFFER_LENGTH
        mov ecx, char_read
        test ecx, ecx
        clc
    .else
        invoke ReadConsoleOutputCharacterA, stdout_handle, offset buffer, eax, coordinate, offset char_read
        mov coordinate.x, 0
        inc coordinate.y
        mov ecx, char_read
        test ecx, ecx
        stc
    .endif
    ret
Read_Console_To_Buffer ENDP

; read a non-zero positive integer
; eax = current existing nzpi
; edx = string to display
; overwrite ecx, edx
; set eax = non-zero positive integer read, zero if input invalid
; set input_validity
; set CF if current nzpi is non-zero
; set ZF if input invalid
Read_Nzpi PROC
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
            call WriteString
            call CrLf
            mov edx, eax
            mov input_validity, VALID_INPUT
        .endif
        call WriteString
        call Read_String_To_Buffer
        .if ecx == 0
            mov input_validity, INPUT_EMPTY
            jmp nzpi_error
        .endif
        push esi
        mov eax, 0
        mov edx, 0
        mov esi, 0
    Read_Nzpi_loop:
        ; eax *= 10
        mov edx, eax ; edx = eax
        shl eax, 3 ; eax *= 8
        jc Read_Nzpi_overflow
        shl edx, 1 ; edx *= 2
        add eax, edx ; eax += edx
        jc Read_Nzpi_overflow

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
        jc Read_Nzpi_overflow
        inc esi
        loop Read_Nzpi_loop

        ; loop ends
        pop esi
        .if eax == 0
            mov input_validity, INPUT_ZERO
            jmp nzpi_error
        .endif
        ret
    Read_Nzpi_overflow:
        mov input_validity, INPUT_OVERFLOW
        pop esi
    nzpi_error:
        xor eax, eax ; clear eax, CF and set ZF
        ret
    .else
        call WriteString
        call WriteDec
        test eax, eax ; clear CF and ZF
        stc
        ret
    .endif
Read_Nzpi ENDP

; read a non-zero positive float
; eax = current existing nzpf
; edx = string to display
; overwrite ecx, edx
; set eax = non-zero positive float read, zero if input invalid
; set input_validity
; set CF if current nzpf is non-zero
; set ZF if input invalid
Read_Nzpf PROC
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
            call WriteString
            call CrLf
            mov edx, eax
            mov input_validity, VALID_INPUT
        .endif

        call WriteString
        call Read_String_To_Buffer
        .if ecx == 0
            mov input_validity, INPUT_EMPTY
            xor eax, eax ; clear eax, CF and set ZF
            ret
        .endif

        lea edx, buffer
        call Convert_String_To_Float
        jc Read_Nzpf_invalid
        .if eax == 0
            mov input_validity, INPUT_ZERO
            xor eax, eax
            ret
        .endif

        mov edx, eax
        shr edx, 23
        sub dl, 127
        cmp dl, 32
        jge Read_Nzpf_overflow

        test eax, eax ; clear CF and ZF
        ret
    Read_Nzpf_invalid:
        mov input_validity, INVALID_INPUT
        xor eax, eax
        ret
    Read_Nzpf_overflow:
        mov input_validity, INPUT_OVERFLOW
        xor eax, eax
        ret
    .else
        call WriteString
        mov edx, eax
        call Print_Float
        mov eax, edx
        test eax, eax ; clear CF and ZF
        stc
        ret
    .endif
Read_Nzpf ENDP

; repeatedly asks yes or no
; overwrite al
; set ZF if y or Y is pressed
; clear ZF if n or N is pressed
Ask_Confirmation PROC
ask_loop:
    call ReadChar
    .if al == 'y' || al == 'Y'
        test al, al ; clear ZF
        ret
    .elseif al == 'n' || al == 'N'
        xor al, al ; set zf
        ret
    .endif
    jmp ask_loop
Ask_Confirmation ENDP

; asks to save summary or not
Ask_Save_Summary PROC
    call CrLf
    .if eax == 0
        lea edx, summary_save_dialog
    .else
        lea edx, summary_overwrite_dialog
    .endif
    call WriteString
    call CrLf
    lea edx, summary_save_yes_dialog
    call WriteString
    call CrLf
    lea edx, summary_save_no_dialog
    call WriteString
    call CrLf
    call Ask_Confirmation
    ret
Ask_Save_Summary ENDP

; print integer with double digits (prepend 0 to integer less than 10)
; eax = integer
Print_Two_Digits PROC
    .if eax < 10
        mov ah, al
        mov al, '0'
        call WriteChar
        mov al, ah
        mov ah, 0
    .endif
    call WriteDec
    ret
Print_Two_Digits ENDP

; convert string to float
; edx = string offset
; ecx = string length
; overwrite ecx
; set eax = float
; set CF if string is invalid
Convert_String_To_Float PROC
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
Convert_String_To_Float ENDP

; print float always with 2 digit precision (e.g. 1234.56, 1000.01)
; eax = float
; overwrite eax, cl
; set CF if float is larger than 2^32
Print_Float PROC
    .if eax == 0
        mov al, '0'
        call WriteChar
        mov al, '.'
        call WriteChar
        mov al, '0'
        call WriteChar
        call WriteChar
        ret
    .endif

    mov float_register, eax

    ; extract exponent
    shr eax, 23
    sub al, 127

    ; check if float >= 2^32
    cmp al, 32
    jge Print_Float_error

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
    jmp Print_Float_integer
float_is_integer:
    sub cl, 23
    shl eax, cl
    jmp Print_Float_integer
float_integer_zero:
    mov eax, 0
Print_Float_integer:
    call WriteDec
    mov al, '.'
    call WriteChar

    ; print fraction

    ; extract exponent
    mov eax, float_register
    shr eax, 23
    sub al, 127
    mov cl, al
    mov eax, 0

    cmp cl, 15
    jg Print_Float_exponent

    ; extract first 8 bits of mantissa
    neg cl
    add cl, 15
    cmp cl, 24
    jae Print_Float_exponent
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
Print_Float_exponent:
    call Print_Two_Digits
    ret
Print_Float_error:
    stc
    ret
Print_Float ENDP

end main
