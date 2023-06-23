; ******************************************************************
; This is an ARM assembly code for an IRQ handler that 
; reads input from a keypad, identifies which key has been pressed, 
; and prints its ASCII value to an LCD screen. It handles three rows of keys.
; 
; Keypad layout:
;              1 | 2 | 3       
;              4 | 5 | 6    
;              7 | 8 | 9 
;              * | 0 | # 
; 
; Key debouncing is implemented using the software instead of hardware.
; The mechanism is fairly simple:
;           - A key is printed when it`s released.
;           - Only one key is allowed to be printed at a time
; therefore, if you press key x then press key y 
; and release key y then key x subsequently, 
; then only key x will be printed, and y ignored (since x was pressed first).
;
; Polling rate: every 5ms i.e. 200Hz
;
; Known bugs: If you press key x and then press another key z from the same raw
; key x won't be printed until z is released too.
; ******************************************************************
; Last edited: 16/05/23
; Author: Ghassan Al Kulaibi
; ***************************

_IRQ
SUB LR, LR, #4          ; Correct return addr
PUSH {R0-R6, LR}        ; Save working regs
                        ; and return address

MOV R0, #BASE_IO            
LDRB R1, [R0, #IRQ_BITS]
LDRB R2, [R0, #IRQ_ENABLE]
AND R1, R1, R2              ; clear any other interrupt other than 
                            ; the ones allowed

TST R1, #TIMER_IRQ          ; Timer compare 
BICNE R1, R1, #TIMER_IRQ          
STRNEB R1, [R0, #IRQ_BITS]  ; acknowledge interrupt and clear it
BNE keypad_irq

B exit_irq                  ; exit if not timer interrupt


keypad_irq
    ; Scan functions arguments
    MOV R0, #1          ; For calling SVC
    MOV R2, #FALSE      ; For calling SVC 1
    MOV R4, #FPGA       ; To read/write FPGA peripherals
    LDRB R6, c_key      ; last key pressed (0 if none pressed
                        ; or already printed)

    ; If no key is pressed then scan all rows
    CMP R6, #0               
    BLEQ scan_all     

    ; Else scan the raw of the pressed key
    ; To check if it's still pressed or not
    ; If the key is no longer pressed then print it to LCD
    AND R1, R6, #&F0                ; Extract row

    CMP R1, #RAW_1_CTRL             ; Raw 1
    ADRLEQ R3, char_table_1         ; ASCII Table
    ; R1 -> Contains Raw control i.e. &80
    BLEQ scan_raw   

    CMP R1, #RAW_2_CTRL             ; Raw 2
    ADRLEQ R3, char_table_2         ; ASCII Table
    ; R1 -> Contains Raw control i.e. &40
    BLEQ scan_raw

    CMP R1, #RAW_3_CTRL             ; Raw 3
    ADRLEQ R3, char_table_3         ; ASCII Table
    ; R1 -> Contains Raw control i.e. &20
    BLEQ scan_raw

    ; Although the above scan functions corrupt R1
    ; It's guaranteed that the final corruptted value
    ; won't be &40 or &20; 
    ; therefore only one of the scan_raw functions will be called
    B exit_irq


; ***********************************
; It's called when no key is pressed i.e. c_key is 0
; Scan all rows
; Stop scanning and exit irq handler if a pressed key is encountred
; Exit irq handler if no key is pressed
; The follwoing registers are corruptted:
;   R1, R3, R5
scan_all
    ADRLEQ R3, char_table_1 ; ASCII Table
    MOVEQ  R1, #RAW_1_CTRL
    BL scan_raw

    ADRLEQ R3, char_table_2 ; ASCII Table
    MOVEQ  R1, #RAW_2_CTRL
    BL scan_raw

    ADRLEQ R3, char_table_3 ; ASCII Table
    MOVEQ  R1, #RAW_3_CTRL    
    BL scan_raw

    B exit_irq

; ***********************************
; The scan row function has the following
; pseducode:
;    Read keypad 
;    if key is pressed:
;    	if c_key is empty:
;    		store new key to c_key
;       exit IRQ handler i.e. return to user code
;
;    else:
;    	if c_key is not empty:
;    		print c_key
;    		clear c_key	
;   exit
; End pseducode
; 
; It takes the follwoing parameter:
;   R0 ->   1               // for calling print svc
;   R1 ->   Raw control bit // To enable reading key switches
;   R2 ->   False (0)       // for calling print svc
;   R3 ->   ASCII value table
;   R4 ->   FPGA address    // To read/write FPGA peripherals
;   R6 ->   c_key value     // last key pressed
;
; They are not passed in a stack to optimise speed.
;
; The follwoing registers are corruptted:
;   R1, R5
; There's no need to save them unless you want to
; modify the code for handling IRQ 
; such as allowing other peripherals to intterrupt.
; In that case you might need to modifiy the parameters.
; ***********************************
scan_raw
    LDRB R5,[R4, #FPGA_DATA]; Read FPGA data address
    AND R5, R5, #&0F        ; clear control byte
    ORR R5, R5, R1          ; enable to read raw
    STRB R5, [R4, #FPGA_DATA]       

    LDRB R5,[R4, #FPGA_DATA]; Read data address
                            ; In case a key is pressed
    AND R5, R5, #&EF        ; Clear 4th bit since it's undefined

    CMP R5, R1            
    BEQ not_pressed         ; If no key is pressed

    CMP R6, #0              ; else
    STREQB R5, c_key        ; If c_key is empty store the new pressed key
    B exit_irq              

not_pressed
    CMP R6, #0

    ; if c_key is not empty
    ANDNE R1, R6, #&0F      ; get c_key key switch value
    LDRNEB R1, [R3, R1]     ; Convert key to ASCII, R3 ascii table

    ; R0 -> 1
    ; R1 -> ASCII val of key
    ; R2 -> False
    SVCNE 1                 ; Print the key

    MOVNE R1, #0            
    STRNEB R1, c_key        ; clear c_key for next key press

    MOV PC, LR              ; Exit


exit_irq
    
    MOV R0, #3
    SVC 3                   ; Returns current time in R1

    ADD R1, R1, #POLL_TIME  ; Interrupt again after 5ms

    MOV R0, #2
    ; R1 -> interup time
    SVC 2

    POP {R0-R6, PC}^        ; Restore and return


; Although this is the not best ascii maping table
; but it saves us instructions in favour of more memory usage 
char_table_1
DEFB "01407000*"
char_table_2
DEFB "025080000"
char_table_3
DEFB "03609000#"

; last key pressed
c_key DEFB 0

ALIGN