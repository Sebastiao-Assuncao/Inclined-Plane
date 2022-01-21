;===============================================================================
;
;        Inclined-Plane Simulation
;
;===============================================================================

; I/O addresses (ff00h to ffffh)
TERM_WRITE      EQU     FFFEh
TERM_STATE      EQU     FFFDh
TERM_CURSOR     EQU     FFFCh
INT_MASK        EQU     FFFAh
TIMER_STATUS    EQU     FFF7h
TIMER_COUNT     EQU     FFF6h
GSENSOR_X       EQU     FFEBh

; Other constants
SP_ADDRESS      EQU     FDFFh
INT_MASK_VALUE  EQU     8000h

;============== Data Region (starting at address 8000h) ========================
                ORIG    8000h
CURRENT_VEL     WORD    0000
CURRENT_X       WORD    0100h
LAST_CURSOR     WORD    0201h
FULL_LINE       EQU     78d
SECOND_LINE     EQU     0200h
LIMIT_RIGHT     EQU     4F00h
LIMIT_LEFT      EQU     0100h

;-------------- Interrupts -----------------------------------------------------
                ORIG    7FF0h
INT_TIMER:      MVI     R5,1        ;R5 SERVES AS A CONTROL REGISTER
                RTI

;============== Code Region (starting at address 0000h) ========================

                ORIG    0000h
                JMP     Main
				
;-------------- Routines-------------------------------------------------------
;===============================================================================
; START_TIMER: Routine that controls the timer interruptions
;		Input: ---
;		Output: ---
;		Changes: Starts the timer and triggers an interruption every 0.1 seconds
;===============================================================================
START_TIMER:    MVI     R1,1
                MVI     R2,TIMER_COUNT
                STOR    M[R2],R1
                MVI     R1,1
                MVI     R2,TIMER_STATUS
                STOR    M[R2],R1
                JMP     R7
;===============================================================================
; DRAW_MAP: Routine that prints out the map where the ball will move
;		Input: ---
;		Output: ---
;		Changes: Print the map on the terminal and the ball in the first position
;===============================================================================
DRAW_MAP:       DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6], R7
                
                MVI 	R4, TERM_WRITE      
                MVI 	R2, TERM_CURSOR     
                
                ;FIRST AND THIRD LINE
                MVI 	R1, 100h            
                STOR 	M[R2], R1
                JAL     LINE
                MVI     R1, 300h
                STOR 	M[R2], R1
                JAL     LINE
                
                ;SECOND LINE
                MVI     R1, 0200h            
                STOR    M[R2], R1
                MVI     R1, '*'
                STOR    M[R4],R1
                MVI     R1, 024Fh           
                STOR    M[R2], R1
                MVI     R1, '*'
                STOR    M[R4], R1
                
                ;BALL IN THE FIRST POSITION
                MVI     R1,0201h            
                STOR    M[R2],R1            
                MVI     R4, 'o'
                STOR    M[R4], R1
                
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                JMP     R7         				
;===============================================================================
; LINE: Routine that prints out a full line made of asterisks
;		Input: R1 - First position of the line
;		Output: ---
;		Changes: Prints a line on the terminal
;===============================================================================
LINE:           MVI     R5, FULL_LINE

.LOOP:          MVI 	R1, '*'
                STOR 	M[R4],R1
                DEC     R5
                CMP     R5,R4
                BR.P    .LOOP
                
                JMP     R7
;===============================================================================
; NEW_ACL: Routine that updates the value of (aceleration * time) depending on the GSENSOR_X
;		Input: ---
;		Output: R3 - Aceleration * time
;		Changes: ---
;===============================================================================
NEW_ACL:        MVI     R3, GSENSOR_X
                LOAD    R3, M[R3]
                
                NEG     R3        ;GSENSOR RETURNS THE SIMETRIC OF THE ACELERATION

                ;MULTIPLY BY TIME, TIME = 1 IN Q8
                SHRA    R3
                SHRA    R3
                SHRA    R3
                
                JMP     R7        ;RETURNS ACL*T
;===============================================================================
; NEW_VEL: Routine that updates the value of the velocity using (Vn = Vn-1 + Acl*t)
;		Input: R1 - Vn-1 ; R2 - Acl*t
;		Output: R3 - Vn
;		Changes: ---
;===============================================================================
NEW_VEL:        ADD     R3, R2, R1
                JMP     R7
;===============================================================================
; NEW_POS: Routine that updates the value of the position using (Xn = Xn-1 + Vel*t)
;		Input: R1 - Xn-1 ; R2 - Vel
;		Output: R3 - Xn
;		Changes: If there is a rebound, changes current_vel to its simetric
;===============================================================================
NEW_POS:        DEC 	R6
                STOR 	M[R6], R7 
                
                ;MULTIPLY VELOCITY BY TIME, TIME = 1 IN Q8
                SHRA    R2
                SHRA    R2
                SHRA    R2
                
                ADD     R1, R1, R2        ;R1 = CURRENT POSITION (IN Q8)
		
                ;CHECKS REBOUNDS
                MVI     R3, LIMIT_RIGHT
                CMP     R1, R3
                BR.NN    .REBOUND_RIGHT
                MVI     R3, LIMIT_LEFT
                CMP     R1, R3
                BR.N    .REBOUND_LEFT
                BR      .EXIT
                
.REBOUND_RIGHT: ;PLACE POSITION INSIDE LIMITS
                SUB     R1, R1, R3
                SUB     R1, R3, R1

                BR      .UPDATE_VEL
                
.REBOUND_LEFT:  ;PLACE POSITION INSIDE LIMITS
                SUB     R1, R3, R1
                ADD     R1, R3, R1
                
.UPDATE_VEL:    ;VEL AFTER IMPACT = -VEL BEFORE IMPACT
                MVI     R2, CURRENT_VEL
                LOAD    R2, M[R2]
                NEG     R2
                MVI     R3, CURRENT_VEL
                STOR    M[R3], R2
                
.EXIT:          MOV     R3, R1

                LOAD    R7, M[R6]
                INC 	R6
                JMP     R7
;===============================================================================
; DRAW_BALL: Routine that updates the position of the ball on the terminal
;		Input: R1 - Current position of the ball
;		Output: ---
;		Changes: Prints the ball on the terminal, erases the previous one and updates the LAST_CURSOR
;===============================================================================
DRAW_BALL:      DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6], R5
                DEC     R6
                STOR    M[R6], R7
                
                MVI     R4, TERM_WRITE
                MVI     R5, TERM_CURSOR

                ;ERASE THE BALL IN THE PREVIOUS POSITION
                MVI     R2, LAST_CURSOR
                LOAD    R2, M[R2]
                STOR    M[R5],R2
                MVI     R2, ' '            
                STOR    M[R4], R2
                
                JAL     CONVERT_TO_QO         
                MOV     R1, R3
                MVI     R2, SECOND_LINE
                ADD     R1, R2, R1

                ;SAVE POSITION IN LAST CURSOR (TO ERASE IN THE NEXT CICLE)
                MVI     R2, LAST_CURSOR
                STOR    M[R2], R1

                ;DRAW THE BALL IN THE POSITION
                STOR    M[R5],R1
                MVI     R1, 'o'           
                STOR    M[R4], R1
                
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                JMP     R7
;===============================================================================
; CONVERT_TO_Q0: Routine that converts a number in Q8 to its equivalent in Q0
;		Input: R1 - Number to convert
;		Output: R3 - Number converted
;		Changes: ---
;===============================================================================
CONVERT_TO_QO:  MVI     R2, 8
                
.LOOP:          CMP     R2, R0
                BR.Z    .EXIT
                SHRA    R1
                DEC     R2
                BR      .LOOP

.EXIT:          MOV     R3, R1
                JMP     R7
;===============================================================================
;                                MAIN CODE
;===============================================================================
Main:
                MVI     R6, SP_ADDRESS
                MVI     R1, INT_MASK
                MVI     R2, INT_MASK_VALUE
                STOR    M[R1], R2
                ENI     
                
                JAL     DRAW_MAP
                
.LOOP:          JAL     START_TIMER
                
                CMP     R5, R0                
                BR.Z    .LOOP
                
                ;LOOP .UPDATES 8 TIMES TO RETURN THE VALUE OF THE 
                ;POSITION AFTER 1 SECOND CLOSER TO REALITY
                MVI     R4, 8
.UPDATES:       CMP     R4, R0
                BR.Z    .DRAW
                DEC     R4
                
                JAL     NEW_ACL        
                
                ;UPDATES VELOCITY AND STORES IT IN CURRENT_VEL
                MOV     R2, R3        
                MVI     R1, CURRENT_VEL
                LOAD    R1, M[R1]        
                JAL     NEW_VEL       
                MVI     R2, CURRENT_VEL
                STOR    M[R2], R3
                
                ;UPDATES POSITION AND STORES IT IN CURRENT_X
                MOV     R2, R3        
                MVI     R1, CURRENT_X        
                LOAD    R1, M[R1]        
                JAL     NEW_POS       
                MVI     R2, CURRENT_X
                STOR    M[R2], R3
                BR      .UPDATES
                
.DRAW:          MOV     R1, R3       
                JAL     DRAW_BALL
                
                MVI     R5, 0
                BR      .LOOP
                
END:            BR      END                
;===============================================================================
