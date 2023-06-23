; ******************************************************************
; A simple program for reading from keyboard.
; It polls the keyboard every 5 ms
; ******************************************************************
; Last edited: 09/05/23
; Author: Ghassan Al Kulaibi
; ***************************
                B reset
undef_handler   B undef_handler
                B svc_entry
prefetch_abort  B prefetch_abort
data_abort      B data_abort
                NOP
                B _IRQ 
_FIQ            B _FIQ


reset 

    ADRL SP, svc_stack      ; initiate svc stack

    ; Enter IRQ mode to setup IRQ
    MRS R0, CPSR
    BIC R0, R0, #CPSR_MODE
    ORR R0, R0, #IRQ_MODE
    MSR CPSR_c, R0

    ADRL SP, irq_stack      ; initiate irq stack  

    ; Enable timer compare to interrupt
    MOV R1, #BASE_IO
    LDRB R2, [R1, #IRQ_ENABLE]
    AND  R2, R2, #0             ; Clear
    ORR R2, R2, #TIMER_IRQ
    STRB R2, [R1, #IRQ_ENABLE]

    ; Enable FPGA control
    MOV R0, #FPGA
    AND R1, R1, #0              ; Clear
    ORR R1, R1, #KEYPAD_CTRL            
    STRB R1, [R0, #FPGA_CTRL]      


    ; Enforce entering user mode
    MRS R0, CPSR                        ; Read current status
    BIC R0, R0, #CPSR_MODE+CPSR_IRQ     ; Clear mode field
    ORR R0, R0, #USER_MODE              ; Append User mode     
    MSR CPSR_c, R0                      ; Update CPSR

    ADRL SP, user_stack                 ; initiate user stack


main
    
    
    ; Get cuurent time
    MOV R0, #3
    SVC 3                       ; Returns current time in R1
    ADD R1, R1, #POLL_TIME      ; Interrupt after 5ms

    MOV R0, #2
    ; R1 -> interrupt time
    SVC 2
sim B sim                         ; Simulate running other program aka 



INCLUDE constants.s
INCLUDE irq_handler.s
INCLUDE svc.s

; Stacks
DEFS 60 
    user_stack

DEFS 60
    svc_stack

DEFS 60
    irq_stack
ALIGN
