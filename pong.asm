; * David Recuenco & Alex Weiland, 2018 (ENTI-UB)

; *************************************************************************
; Our data section. Here we declare our strings for our console message
; *************************************************************************

SGROUP 		GROUP 	CODE_SEG, DATA_SEG
			ASSUME 	CS:SGROUP, DS:SGROUP, SS:SGROUP

    TRUE  EQU 1
    FALSE EQU 0

; EXTENDED ASCII CODES
    ASCII_SPECIAL_KEY EQU 00

    ASCII_UP          EQU 077h ; 'w'
    ASCII_DOWN        EQU 073h ; 's'
    
    ASCII_UP2         EQU 06Fh ; 'o'
    ASCII_DOWN2       EQU 06Ch ; 'l'

    ASCII_QUIT        EQU 071h ; 'q'

; ASCII / ATTR CODES TO DRAW THE SNAKE
    ASCII_SNAKE     EQU 02Ah
    ATTR_SNAKE      EQU 070h

; ASCII / ATTR CODES TO DRAW THE FIELD
    ASCII_FIELD    EQU 020h
    ATTR_FIELD     EQU 070h

    ASCII_NUMBER_ZERO EQU 030h

; CURSOR
    CURSOR_SIZE_HIDE EQU 02607h  ; BIT 5 OF CH = 1 MEANS HIDE CURSOR
    CURSOR_SIZE_SHOW EQU 00607h

; ASCII
    ASCII_YES_UPPERCASE      EQU 059h
    ASCII_YES_LOWERCASE      EQU 079h
    
; COLOR SCREEN DIMENSIONS IN NUMBER OF CHARACTERS
    SCREEN_MAX_ROWS EQU 25
    SCREEN_MAX_COLS EQU 80

; FIELD DIMENSIONS
    FIELD_R1 EQU 1
    FIELD_R2 EQU SCREEN_MAX_ROWS-2
    FIELD_C1 EQU 1
    FIELD_C2 EQU SCREEN_MAX_COLS-2

; *************************************************************************
; Our executable assembly code starts here in the .code section
; *************************************************************************
CODE_SEG	SEGMENT PUBLIC
			ORG 100h

MAIN 	PROC 	NEAR

  MAIN_GO:

      CALL REGISTER_TIMER_INTERRUPT

      CALL INIT_GAME
      CALL INIT_SCREEN
      CALL HIDE_CURSOR
      CALL DRAW_FIELD

      MOV DH, SCREEN_MAX_ROWS/2
      MOV DL, SCREEN_MAX_COLS/2
      
      CALL MOVE_CURSOR
      
  MAIN_LOOP:
      CMP [END_GAME], TRUE
      JZ END_PROG

      ; Check if a key is available to read
      MOV AH, 0Bh
      INT 21h
      CMP AL, 0
      JZ MAIN_LOOP

      ; A key is available -> read
      CALL READ_CHAR      

      ; End game?
      CMP AL, ASCII_QUIT
      JZ END_PROG
      
      ; Is it an special key?
      CMP AL, ASCII_SPECIAL_KEY
      JZ MAIN_LOOP_BUT_READCHAR
      
      ; The game is on!
      MOV [START_GAME], TRUE

      CMP AL, ASCII_RIGHT
      JZ RIGHT_KEY
      CMP AL, ASCII_LEFT
      JZ LEFT_KEY
      CMP AL, ASCII_UP
      JZ UP_KEY
      CMP AL, ASCII_DOWN
      JZ DOWN_KEY

      JMP MAIN_LOOP

MAIN_LOOP_BUT_READCHAR:
      CALL READ_CHAR
      JMP MAIN_LOOP


  RIGHT_KEY:
      MOV [INC_COL], 1
      MOV [INC_ROW], 0
      JMP END_KEY

  LEFT_KEY:
      MOV [INC_COL], -1
      MOV [INC_ROW], 0
      JMP END_KEY

  UP_KEY:
      MOV [INC_COL], 0
      MOV [INC_ROW], -1
      JMP END_KEY

  DOWN_KEY:
      MOV [INC_COL], 0
      MOV [INC_ROW], 1
      JMP END_KEY
      
  END_KEY:
      JMP MAIN_LOOP

  END_PROG:
      CALL RESTORE_TIMER_INTERRUPT
      CALL SHOW_CURSOR
      CALL PRINT_SCORE_STRING
      CALL PRINT_SCORE
      CALL PRINT_PLAY_AGAIN_STRING
      
      CALL READ_CHAR

      CMP AL, ASCII_YES_UPPERCASE
      JZ MAIN_GO
      CMP AL, ASCII_YES_LOWERCASE
      JZ MAIN_GO

	INT 20h		

MAIN	ENDP	

; ****************************************
; Reset internal variables
; Entry: 
;   
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   INC_ROW memory variable
;   INC_COL memory variable
;   DIV_SPEED memory variable
;   NUM_TILES memory variable
;   START_GAME memory variable
;   END_GAME memory variable
; Calls:
;   -
; ****************************************
                  PUBLIC  INIT_GAME
INIT_GAME         PROC    NEAR

    MOV [INC_ROW], 0
    MOV [INC_COL], 0

    MOV [DIV_SPEED], 10

    MOV [NUM_TILES], 0
    
    MOV [START_GAME], FALSE
    MOV [END_GAME], FALSE

    RET
INIT_GAME	ENDP	

; ****************************************
; Reads char from keyboard
; If char is not available, blocks until a key is pressed
; The char is not output to screen
; Entry: 
;
; Returns:
;   AL: ASCII CODE
;   AH: ATTRIBUTE
; Modifies:
;   
; Uses: 
;   
; Calls:
;   
; ****************************************
PUBLIC  READ_CHAR
READ_CHAR PROC NEAR

    MOV AH, 8
    INT 21h

    RET
      
READ_CHAR ENDP


; ****************************************
; Read character and attribute at cursor position, page 0
; Entry: 
;
; Returns:
;   AL: ASCII CODE
;   AH: ATTRIBUTE
; Modifies:
;   
; Uses: 
;   
; Calls:
;   int 10h, service AH=8
; ****************************************
PUBLIC READ_SCREEN_CHAR                 
READ_SCREEN_CHAR PROC NEAR

    PUSH BX

    MOV AH, 8
    XOR BH, BH
    INT 10h

    POP BX
    RET
      
READ_SCREEN_CHAR  ENDP

; ****************************************
; Draws the rectangular field of the game
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   Coordinates of the rectangle: 
;    left - top: (FIELD_R1, FIELD_C1) 
;    right - bottom: (FIELD_R2, FIELD_C2)
;   Character: ASCII_FIELD
;   Attribute: ATTR_FIELD
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC DRAW_FIELD
DRAW_FIELD PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX

    MOV AL, ASCII_FIELD
    MOV BL, ATTR_FIELD

    MOV DL, FIELD_C2
  UP_DOWN_SCREEN_LIMIT:
    MOV DH, FIELD_R1
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    MOV DH, FIELD_R2
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    DEC DL
    CMP DL, FIELD_C1
    JNS UP_DOWN_SCREEN_LIMIT

    MOV DH, FIELD_R2
  LEFT_RIGHT_SCREEN_LIMIT:
    MOV DL, FIELD_C1
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    MOV DL, FIELD_C2
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    DEC DH
    CMP DH, FIELD_R1
    JNS LEFT_RIGHT_SCREEN_LIMIT
                 
    POP DX
    POP BX
    POP AX
    RET

DRAW_FIELD       ENDP

; ****************************************
; Prints a new tile of the snake, at the current cursos position
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   character: ASCII_SNAKE
;   attribute: ATTR_SNAKE
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC PRINT_SNAKE
PRINT_SNAKE PROC NEAR

    PUSH AX
    PUSH BX
    MOV AL, ASCII_SNAKE
    MOV BL, ATTR_SNAKE
    CALL PRINT_CHAR_ATTR
      
    POP BX
    POP AX
    RET

PRINT_SNAKE        ENDP     

; ****************************************
; Prints character and attribute in the 
; current cursor position, page 0 
; Keeps the cursor position
; Entry: 
;   AL: ASCII to print
;   BL: ATTRIBUTE to print
; Returns:
;   
; Modifies:
;   
; Uses: 
;
; Calls:
;   int 10h, service AH=9
; Nota:
;   Compatibility problem when debugging
; ****************************************
PUBLIC PRINT_CHAR_ATTR
PRINT_CHAR_ATTR PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX

    MOV AH, 9
    MOV BH, 0
    MOV CX, 1
    INT 10h

    POP CX
    POP BX
    POP AX
    RET

PRINT_CHAR_ATTR        ENDP     

; ****************************************
; Prints character and attribute in the 
; current cursor position, page 0 
; Cursor moves one position right
; Entry: 
;    AL: ASCII code to print
; Returns:
;   
; Modifies:
;   
; Uses: 
;
; Calls:
;   int 21h, service AH=2
; ****************************************
PUBLIC PRINT_CHAR
PRINT_CHAR PROC NEAR

    PUSH AX
    PUSH DX

    MOV AH, 2
    MOV DL, AL
    INT 21h

    POP DX
    POP AX
    RET

PRINT_CHAR        ENDP     

; ****************************************
; Set screen to mode 3 (80x25, color) and 
; clears the screen
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   Screen size: SCREEN_MAX_ROWS, SCREEN_MAX_COLS
; Calls:
;   int 10h, service AH=0
;   int 10h, service AH=6
; ****************************************
PUBLIC INIT_SCREEN
INIT_SCREEN	PROC NEAR

      PUSH AX
      PUSH BX
      PUSH CX
      PUSH DX

      ; Set screen mode
      MOV AL,3
      MOV AH,0
      INT 10h

      ; Clear screen
      XOR AL, AL
      XOR CX, CX
      MOV DH, SCREEN_MAX_ROWS
      MOV DL, SCREEN_MAX_COLS
      MOV BH, 7
      MOV AH, 6
      INT 10h
      
      POP DX      
      POP CX      
      POP BX      
      POP AX      
	RET

INIT_SCREEN		ENDP

; ****************************************
; Hides the cursor 
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=1
; ****************************************
PUBLIC  HIDE_CURSOR
HIDE_CURSOR PROC NEAR

      PUSH AX
      PUSH CX
      
      MOV AH, 1
      MOV CX, CURSOR_SIZE_HIDE
      INT 10h

      POP CX
      POP AX
      RET

HIDE_CURSOR       ENDP

; ****************************************
; Shows the cursor (standard size)
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=1
; ****************************************
PUBLIC SHOW_CURSOR
SHOW_CURSOR PROC NEAR

    PUSH AX
    PUSH CX
      
    MOV AH, 1
    MOV CX, CURSOR_SIZE_SHOW
    INT 10h

    POP CX
    POP AX
    RET

SHOW_CURSOR       ENDP

; ****************************************
; Get cursor properties: coordinates and size (page 0)
; Entry: 
;   -
; Returns:
;   (DH, DL): coordinates -> (row, col)
;   (CH, CL): cursor size
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=3
; ****************************************
PUBLIC GET_CURSOR_PROP
GET_CURSOR_PROP PROC NEAR

      PUSH AX
      PUSH BX

      MOV AH, 3
      XOR BX, BX
      INT 10h

      POP BX
      POP AX
      RET
      
GET_CURSOR_PROP       ENDP

; ****************************************
; Set cursor properties: coordinates and size (page 0)
; Entry: 
;   (DH, DL): coordinates -> (row, col)
;   (CH, CL): cursor size
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=2
; ****************************************
PUBLIC SET_CURSOR_PROP
SET_CURSOR_PROP PROC NEAR

      PUSH AX
      PUSH BX

      MOV AH, 2
      XOR BX, BX
      INT 10h

      POP BX
      POP AX
      RET
      
SET_CURSOR_PROP       ENDP

; ****************************************
; Move cursor to coordinate
; Cursor size if kept
; Entry: 
;   (DH, DL): coordinates -> (row, col)
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   GET_CURSOR_PROP
;   SET_CURSOR_PROP
; ****************************************
PUBLIC MOVE_CURSOR
MOVE_CURSOR PROC NEAR

      PUSH DX
      CALL GET_CURSOR_PROP  ; Get cursor size
      POP DX
      CALL SET_CURSOR_PROP
      RET

MOVE_CURSOR       ENDP

; ****************************************
; Moves cursor one position to the right
; If the column limit is reached, the cursor does not move
; Cursor size if kept
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   SCREEN_MAX_COLS
; Calls:
;   GET_CURSOR_PROP
;   SET_CURSOR_PROP
; ****************************************
PUBLIC  MOVE_CURSOR_RIGHT
MOVE_CURSOR_RIGHT PROC NEAR

    PUSH CX
    PUSH DX

    CALL GET_CURSOR_PROP
    ADD DL, 1
    CMP DL, SCREEN_MAX_COLS
    JZ MOVE_CURSOR_RIGHT_END
    
    CALL SET_CURSOR_PROP

  MOVE_CURSOR_RIGHT_END:
    POP DX
    POP CX
    RET

MOVE_CURSOR_RIGHT       ENDP

; ****************************************
; Print string to screen
; The string end character is '$'
; Entry: 
;   DX: pointer to string
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   SCREEN_MAX_COLS
; Calls:
;   INT 21h, service AH=9
; ****************************************
PUBLIC PRINT_STRING
PRINT_STRING PROC NEAR

    PUSH DX
      
    MOV AH,9
    INT 21h

    POP DX
    RET

PRINT_STRING       ENDP

; ****************************************
; Print the score string, starting in the cursor
; (FIELD_C1, FIELD_R2) coordinate
; Entry: 
;   DX: pointer to string
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   SCORE_STR
;   FIELD_C1
;   FIELD_R2
; Calls:
;   GET_CURSOR_PROP
;   SET_CURSOR_PROP
;   PRINT_STRING
; ****************************************
PUBLIC PRINT_SCORE_STRING
PRINT_SCORE_STRING PROC NEAR

    PUSH CX
    PUSH DX

    CALL GET_CURSOR_PROP  ; Get cursor size
    MOV DH, FIELD_R2+1
    MOV DL, FIELD_C1
    CALL SET_CURSOR_PROP

    LEA DX, SCORE_STR
    CALL PRINT_STRING

    POP CX
    POP DX
    RET

PRINT_SCORE_STRING       ENDP

; ****************************************
; Print the score string, starting in the
; current cursor coordinate
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   PLAY_AGAIN_STR
;   FIELD_C1
;   FIELD_R2
; Calls:
;   PRINT_STRING
; ****************************************
PUBLIC PRINT_PLAY_AGAIN_STRING
PRINT_PLAY_AGAIN_STRING PROC NEAR

    PUSH DX

    LEA DX, PLAY_AGAIN_STR
    CALL PRINT_STRING

    POP DX
    RET

PRINT_PLAY_AGAIN_STRING       ENDP

; ****************************************
; Prints the score of the player in decimal, on the screen, 
; starting in the cursor position
; NUM_TILES range: [0, 9999]
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   NUM_TILES memory variable
; Calls:
;   PRINT_CHAR
; ****************************************
PUBLIC PRINT_SCORE
PRINT_SCORE PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; 1000'
    MOV AX, [NUM_TILES]
    XOR DX, DX
    MOV BX, 1000
    DIV BX            ; DS:AX / BX -> AX: quotient, DX: remainder
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    ; 100'
    MOV AX, DX        ; Remainder
    XOR DX, DX
    MOV BX, 100
    DIV BX            ; DS:AX / BX -> AX: quotient, DX: remainder
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    ; 10'
    MOV AX, DX          ; Remainder
    XOR DX, DX
    MOV BX, 10
    DIV BX            ; DS:AX / BX -> AX: quotient, DX: remainder
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    ; 1'
    MOV AX, DX
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    POP DX
    POP CX
    POP BX
    POP AX
    RET   
         
PRINT_SCORE        ENDP

; ****************************************
; Game timer interrupt service routine
; Called 18.2 times per second by the operating system
; Calls previous ISR
; Manages the movement of the snake: 
;   position, direction, speed, length, display, collisions
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
;   START_GAME memory variable
;   END_GAME memory variable
;   INT_COUNT memory variable
;   DIV_SPEED memory variable
;   INC_COL memory variable
;   INC_ROW memory variable
;   ATTR_SNAKE constant
;   NUM_TILES memory variable
;   NUM_TILES_INC_SPEED
; Calls:
;   MOVE_CURSOR
;   READ_SCREEN_CHAR
;   PRINT_SNAKE
; ****************************************
PUBLIC NEW_TIMER_INTERRUPT
NEW_TIMER_INTERRUPT PROC NEAR

    ; Call previous interrupt
    PUSHF
    CALL DWORD PTR [OLD_INTERRUPT_BASE]

    PUSH AX

    ; Do nothing if game is stopped
    CMP [START_GAME], TRUE
    JNZ END_ISR

    ; Increment INC_COUNT and check if worm position must be updated (INT_COUNT == DIV_COUNT)
    INC [INT_COUNT]
    MOV AL, [INT_COUNT]
    CMP [DIV_SPEED], AL
    JNZ END_ISR
    MOV [INT_COUNT], 0

    ; Load worm coordinates
    ADD DL, [INC_COL]
    ADD DH, [INC_ROW]

    ; Move snake on the screen
    CALL MOVE_CURSOR

    ; Check if snake collided with the field or with himself
    CALL READ_SCREEN_CHAR
    CMP AH, ATTR_SNAKE
    JZ END_SNAKES

    ; Increment the length of the snake
    INC [NUM_TILES]
    CALL PRINT_SNAKE

    ; Check if it is time to increase the speed of the snake
    CMP [DIV_SPEED], 1
    JZ END_ISR
    MOV AX, [NUM_TILES]
    DIV [NUM_TILES_INC_SPEED]
    CMP AH, 0                 ; REMAINDER
    JNZ END_ISR
    DEC [DIV_SPEED]

    JMP END_ISR
      
END_SNAKES:
      MOV [END_GAME], TRUE
      
END_ISR:

      POP AX
      IRET

NEW_TIMER_INTERRUPT ENDP
                 
; ****************************************
; Replaces current timer ISR with the game timer ISR
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
;   NEW_TIMER_INTERRUPT memory variable
; Calls:
;   int 21h, service AH=35 (system interrupt 08)
; ****************************************
PUBLIC REGISTER_TIMER_INTERRUPT
REGISTER_TIMER_INTERRUPT PROC NEAR

        PUSH AX
        PUSH BX
        PUSH DS
        PUSH ES 

        CLI                                 ;Disable Ints
        
        ;Get current 01CH ISR segment:offset
        MOV  AX, 3508h                      ;Select MS-DOS service 35h, interrupt 08h
        INT  21h                            ;Get the existing ISR entry for 08h
        MOV  WORD PTR OLD_INTERRUPT_BASE+02h, ES  ;Store Segment 
        MOV  WORD PTR OLD_INTERRUPT_BASE, BX  ;Store Offset

        ;Set new 01Ch ISR segment:offset
        MOV  AX, 2508h                      ;MS-DOS serivce 25h, IVT entry 01Ch
        MOV  DX, offset NEW_TIMER_INTERRUPT ;Set the offset where the new IVT entry should point to
        INT  21h                            ;Define the new vector

        STI                                 ;Re-enable interrupts

        POP  ES                             ;Restore interrupts
        POP  DS
        POP  BX
        POP  AX
        RET      

REGISTER_TIMER_INTERRUPT ENDP

; ****************************************
; Restore timer ISR
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
; Calls:
;   int 21h, service AH=25 (system interrupt 08)
; ****************************************
PUBLIC RESTORE_TIMER_INTERRUPT
RESTORE_TIMER_INTERRUPT PROC NEAR

      PUSH AX                             
      PUSH DS
      PUSH DX 

      CLI                                 ;Disable Ints
        
      ;Restore 08h ISR
      MOV  AX, 2508h                      ;MS-DOS service 25h, ISR 08h
      MOV  DX, WORD PTR OLD_INTERRUPT_BASE
      MOV  DS, WORD PTR OLD_INTERRUPT_BASE+02h
      INT  21h                            ;Define the new vector

      STI                                 ;Re-enable interrupts

      POP  DX                             
      POP  DS
      POP  AX
      RET    
      
RESTORE_TIMER_INTERRUPT ENDP

CODE_SEG 	ENDS

DATA_SEG	SEGMENT	PUBLIC
			
    OLD_INTERRUPT_BASE    DW  0, 0  ; Stores the current (system) timer ISR address

    ; (INC_ROW. INC_COL) may be (-1, 0, 1), and determine the direction of movement of the snake
    INC_ROW DB 0    
    INC_COL DB 0

    NUM_TILES DW 0              ; SNAKE LENGTH
    NUM_TILES_INC_SPEED DB 20   ; THE SPEED IS INCREASED EVERY 'NUM_TILES_INC_SPEED'
    
    DIV_SPEED DB 10             ; THE SNAKE SPEED IS THE (INTERRUPT FREQUENCY) / DIV_SPEED
    INT_COUNT DB 0              ; 'INT_COUNT' IS INCREASED EVERY INTERRUPT CALL, AND RESET WHEN IT ACHIEVES 'DIV_SPEED'

    START_GAME DB 0             ; 'MAIN' sets START_GAME to '1' when a key is pressed
    END_GAME DB 0               ; 'NEW_TIMER_INTERRUPT' sets END_GAME to '1' when a condition to end the game happens

    SCORE_STR           DB "Your score is $"
    PLAY_AGAIN_STR      DB ". Do you want to play again? (Y/N)$"
    
DATA_SEG	ENDS

		END MAIN