; Addresses
BASE_IO         EQU &10000000
PORT_A          EQU &0              ;Data bus
PORT_B          EQU &4
TIMER           EQU &8
TIMER_COMPARE   EQU &C
IRQ_BITS        EQU &18
IRQ_ENABLE      EQU &1C
HALT            EQU &20


FPGA            EQU &20000000

; Port B control
ENABLE          EQU 0b1             ;Active high
RS              EQU 0b10            ;0 = Control, 1 = Data             
RW              EQU 0b100           ;0 = Write,   1 = Read

; Port A control
LCD_BUSY        EQU 0b10000000
CLEAR           EQU 0b10000000

; Keyboard polling time in ms
POLL_TIME       EQU 5

; FPGA
FPGA_DATA       EQU 2
FPGA_CTRL       EQU 3
RAW_1_CTRL      EQU &80
RAW_2_CTRL      EQU &40
RAW_3_CTRL      EQU &20
KEYPAD_CTRL     EQU &1F

; SVC 
MAX_SVC         EQU 3               ;Maximum number of SVCs

; Cursor control
NEXT_LINE       EQU &C0             ;Move to next line
RESET_LOC       EQU &02             ;Move to original location 

; CPSR constants
USER_MODE       EQU &10
SYS_MODE        EQU &1F
IRQ_MODE        EQU &12

CPSR_IRQ        EQU &80
CPSR_MODE       EQU &1F

; IRQ table
TIMER_IRQ       EQU 1

; Boolean
TRUE            EQU 1 
FALSE           EQU 0


ALIGN