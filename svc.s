; ******************************************************************
;                   ******Supervisor Call Functions******
;
; SVC 0: halt a programme, by stoping the processor
;
; SVC 1: would either print an ASCII char or
; perform a cursor control operation. It accepts two arguments:
; R1: it holds the ASCII or cursor control value
; R2: 0/false if R1 is an ASCII char or 1/true for cursor control
;
; SVC 2: Writes to the timer compare register the value passaed in R1
; R1: The value to be written
;
; SVC 3: Read timer (counter) value and return its value in R1 
; R1: Counter current value
;
; Nested SVCs are currently not supported.
; ******************************************************************
; Last edited: 16/05/23
; Author: Ghassan Al Kulaibi
; ***************************

svc_entry
    ; R0 contains the SVC number
    ; R1 contains the first svc argument/return value if required
    ; R2 contains the second SVC argument/return value if required 


    CMP R0, #MAX_SVC
    LDRLS  PC, [PC, R0, LSL #2]     ;PC points to the jump table
    B SVC_00                        ;End program if svc undefined
    jump_table  DEFW SVC_00
                DEFW SVC_01
                DEFW SVC_02
                DEFW SVC_03



SVC_00
    ; End of program or undefiend SVC
    MOV R0, #BASE_IO
    STR R0, [R0, #HALT]
    NOP                 ;For debug, this is end of program

; ******************************************************************
; Accepts two parameters which are placed in R1 and R2
; R1 contains the ASCII value or cursor control
; R2 is whether R1 is ASCII char or cursor control
; If R2 is true then it is a cursor control operation otherwise print
; the ASCII char 
SVC_01    
    PUSH{R0, R3-R4}                 ;Save any used registers
    MOV R0, #BASE_IO      

    LDRB R4, [R0, #PORT_B]      
    ORR R4, R4, #RW             ;Set to read control R/W=1
    BIC R4, R4, #RS             ;Set to control
    STRB R4, [R0, #PORT_B]      

    busy
        ORR R4, R4, #ENABLE         ;Set Enable active
        STRB R4, [R0, #PORT_B]      

        LDRB R3, [R0, #PORT_A]      
        BIC R4, R4, #ENABLE         ;Set Enable inactive
        STRB R4, [R0, #PORT_B]      

        TST R3, #LCD_BUSY           ;Check if LCD is busy (bit 7: low=idle, high=busy)
    BNE busy                    ;If busy, wait until LCD is not busy

    CMP R2, #TRUE               ;check if cursor control or ascii

    BICEQ R4, R4, #RS+RW        ;If cursor control set R/W = 0 and RS=0

    ; For printing ASCII
    BICNE R4, R4, #RW           ;Set to write R/W = 0
    ORRNE R4, R4, #RS           ;Set RS=1

    STRB R4, [R0, #PORT_B]      

    STRB R1, [R0, #PORT_A]      ;R1 contains the char ASCII value / cursor control


    ORR R4, R4, #ENABLE         ;Set Enable active
    STRB R4, [R0, #PORT_B]      

    BIC R4, R4, #ENABLE         ;Set Enable inactive
    STRB R4, [R0, #PORT_B]      

    POP {R0, R3-R4}
    MOVS PC, LR

; ******************************************************************
; Writes to the timer compare register the value passaed in R1
; when the counter matches the compare register there will be interrupt,
; given interrupt is enabled.
SVC_02 
    PUSH {R0, R2}

    MOV R0, #BASE_IO
    
    STRB R1, [R0, #TIMER_COMPARE]

    POP {R0, R2}
    MOVS PC, LR

; ******************************************************************
; Read timer (counter) value and return its value in R1
SVC_03
    PUSH {R0}

    MOV  R0, #BASE_IO
    LDRB R1, [R0, #TIMER]

    POP {R0}
    MOVS PC, LR

ALIGN