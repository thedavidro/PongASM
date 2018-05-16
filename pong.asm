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

; ASCII / ATTR CODES TO DRAW THE BALL
    ASCII_BALL     EQU 02Ah
    ATTR_BALL      EQU 070h

; ASCII / ATTR PALAS
	ASCII_PALAS		EQU 020h
	ATTR_PALA1		EQU 017h
	ATTR_PALA2		EQU 027h

; ASCII / ATTR CODES TO DRAW THE FIELD
    ASCII_FIELD    	EQU 020h
		ATTR_EMPTY   		EQU 000h
    ATTR_FIELD     	EQU 070h
		ATTR_TOP	   		EQU 071h	; Blue on White.
		ATTR_BOTTOM	   	EQU 072h	; Green on White.
		ATTR_LEFT	   		EQU 073h	; Cyan on White.
		ATTR_RIGHT	   	EQU 074h	; Red on White.

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

			CALL INIT_BALL
			CALL INIT_PADDLES

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

      CMP AL, ASCII_UP
      JZ UP1
      CMP AL, ASCII_DOWN
      JZ DOWN1
      CMP AL, ASCII_UP2
      JZ UP2
      CMP AL, ASCII_DOWN2
      JZ DOWN2

      JMP MAIN_LOOP

  MAIN_LOOP_BUT_READCHAR:
      CALL READ_CHAR
      JMP MAIN_LOOP


  UP1:
	  ; Mirar si encima hay pared (field)
	  MOV DH, [PAD1_ROW]
	  MOV DL, [PAD1_COL]
	  DEC DH				; Apunta encima
	  CALL MOVE_CURSOR
	  CALL READ_SCREEN_CHAR
      CMP AH, ATTR_TOP
      JZ END_KEY

      ; Borrar parte de abajo (+)
      MOV DH, [PAD1_ROW]
	  MOV DL, [PAD1_COL]
	  INC DH
	  INC DH
	  INC DH
	  INC DH
	  INC DH
	  CALL MOVE_CURSOR
	  MOV AL, ASCII_FIELD
	  MOV BL, ATTR_EMPTY
	  CALL PRINT_CHAR_ATTR

	  ; Modificar valor
	  DEC [PAD1_ROW]
      JMP END_KEY

  DOWN1:
	  ; Mirar si debajo hay pared (field)
	  MOV DH, [PAD1_ROW]
	  MOV DL, [PAD1_COL]
	  INC DH
	  INC DH
	  INC DH
	  INC DH
	  INC DH
	  INC DH 				; Apunta debajo
	  CALL MOVE_CURSOR
	  CALL READ_SCREEN_CHAR
      CMP AH, ATTR_BOTTOM
      JZ END_KEY

      ; Borrar parte de arriba (-)
	  MOV DH, [PAD1_ROW]
	  MOV DL, [PAD1_COL]
	  CALL MOVE_CURSOR
	  MOV AL, ASCII_FIELD
	  MOV BL, ATTR_EMPTY
	  CALL PRINT_CHAR_ATTR

	  ; Modificar valores
      INC [PAD1_ROW]
      JMP END_KEY

  UP2:
	  ; Mirar si encima hay pared (field)
	  MOV DH, [PAD2_ROW]
	  MOV DL, [PAD2_COL]
	  DEC DH				; Apunta encima
	  CALL MOVE_CURSOR
	  CALL READ_SCREEN_CHAR
      CMP AH, ATTR_TOP
      JZ END_KEY

      ; Borrar parte de abajo (+)
      MOV DH, [PAD2_ROW]
	  MOV DL, [PAD2_COL]
	  INC DH
	  INC DH
	  INC DH
	  INC DH
	  INC DH
	  CALL MOVE_CURSOR
	  MOV AL, ASCII_FIELD
	  MOV BL, ATTR_EMPTY
	  CALL PRINT_CHAR_ATTR

	  ; Modificar valor
      DEC [PAD2_ROW]
      JMP END_KEY

  DOWN2:
	  ; Mirar si debajo hay pared (field)
	  MOV DH, [PAD2_ROW]
	  MOV DL, [PAD2_COL]
	  INC DH
	  INC DH
	  INC DH
	  INC DH
	  INC DH
	  INC DH 				; Apunta debajo
	  CALL MOVE_CURSOR
	  CALL READ_SCREEN_CHAR
      CMP AH, ATTR_BOTTOM
      JZ END_KEY

      ; Borrar parte de arriba (-)
	  MOV DH, [PAD2_ROW]
	  MOV DL, [PAD2_COL]
	  CALL MOVE_CURSOR
	  MOV AL, ASCII_FIELD
	  MOV BL, ATTR_EMPTY
	  CALL PRINT_CHAR_ATTR

	  ; Modificar valores
      INC [PAD2_ROW]
      JMP END_KEY

  END_KEY:
	  ; Pintar Pala1
	  MOV DH, [PAD1_ROW]
	  MOV DL, [PAD1_COL]
	  CALL MOVE_CURSOR
	  MOV AL, ASCII_PALAS
	  MOV BL, ATTR_PALA1
	  CALL PRINT_CHAR_ATTR
	  INC DH
	  CALL MOVE_CURSOR
	  CALL PRINT_CHAR_ATTR
	  INC DH
	  CALL MOVE_CURSOR
	  CALL PRINT_CHAR_ATTR
	  INC DH
	  CALL MOVE_CURSOR
	  CALL PRINT_CHAR_ATTR
	  INC DH
	  CALL MOVE_CURSOR
	  CALL PRINT_CHAR_ATTR
	  INC DH
	  CALL MOVE_CURSOR
	  CALL PRINT_CHAR_ATTR

	  ; Pintar Pala2
	  MOV DH, [PAD2_ROW]
	  MOV DL, [PAD2_COL]
	  CALL MOVE_CURSOR
	  MOV AL, ASCII_PALAS
	  MOV BL, ATTR_PALA2
	  CALL PRINT_CHAR_ATTR
	  INC DH
	  CALL MOVE_CURSOR
	  CALL PRINT_CHAR_ATTR
	  INC DH
	  CALL MOVE_CURSOR
	  CALL PRINT_CHAR_ATTR
	  INC DH
	  CALL MOVE_CURSOR
	  CALL PRINT_CHAR_ATTR
	  INC DH
	  CALL MOVE_CURSOR
	  CALL PRINT_CHAR_ATTR
	  INC DH
	  CALL MOVE_CURSOR
	  CALL PRINT_CHAR_ATTR


      JMP MAIN_LOOP

  END_PROG:
      CALL RESTORE_TIMER_INTERRUPT
      CALL SHOW_CURSOR
			LEA AX, SCORE1_STR
			MOV BL, 1
      CALL PRINT_SCORE_STRING
			MOV AX, [SCORE1]
      CALL PRINT_SCORE
			LEA AX, SCORE2_STR
			MOV BL, 2
			CALL PRINT_SCORE_STRING
			MOV AX, [SCORE2]
      CALL PRINT_SCORE
      CALL PRINT_PLAY_AGAIN_STRING

      CALL READ_CHAR

      CMP AL, ASCII_YES_UPPERCASE
      JZ MAIN_GO
      CMP AL, ASCII_YES_LOWERCASE
      JZ MAIN_GO

	  ; Print Missatge d'autors:
	  CALL PRINT_AUTHORS_STRING

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

    ;MOV [INC_ROW], 0
    ;MOV [INC_COL], 0

    ;MOV [DIV_SPEED], 10

    ;MOV [NUM_TILES], 0

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
; Draws the rectangular field of the game. Also draws with different colors for interactivity.
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
;   Attribute: ATTR_FIELD, ATTR_TOP, ATTR_BOTTOM, ATTR_LEFT, ATTR_RIGHT
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

    MOV DL, FIELD_C2	 	; Right Column.
  UP_DOWN_SCREEN_LIMIT:
    MOV DH, FIELD_R1		; Top Row.
    CALL MOVE_CURSOR
	MOV BL, ATTR_TOP
    CALL PRINT_CHAR_ATTR

    MOV DH, FIELD_R2		; Bottom Row
    CALL MOVE_CURSOR
	MOV BL, ATTR_BOTTOM
    CALL PRINT_CHAR_ATTR

    DEC DL
    CMP DL, FIELD_C1		; Left Column
    JNS UP_DOWN_SCREEN_LIMIT

    MOV DH, FIELD_R2		; Bottom Row
  LEFT_RIGHT_SCREEN_LIMIT:
    MOV DL, FIELD_C1		; Left Column
    CALL MOVE_CURSOR
	MOV BL, ATTR_LEFT
    CALL PRINT_CHAR_ATTR

    MOV DL, FIELD_C2		; Right Column
    CALL MOVE_CURSOR
	MOV BL, ATTR_RIGHT
    CALL PRINT_CHAR_ATTR

    DEC DH
    CMP DH, FIELD_R1		; Top Row
    JNS LEFT_RIGHT_SCREEN_LIMIT

    POP DX
    POP BX
    POP AX
    RET

DRAW_FIELD       ENDP

; ****************************************
; Prints the ball, at the current cursor position
; Entry:
;
; Returns:
;
; Modifies:
;
; Uses:
;   character: ASCII_BALL
;   attribute: ATTR_BALL
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC PRINT_BALL
PRINT_BALL PROC NEAR

    PUSH AX
    PUSH BX
    MOV AL, ASCII_BALL
    MOV BL, ATTR_BALL
    CALL PRINT_CHAR_ATTR

    POP BX
    POP AX
    RET

PRINT_BALL        ENDP

; ****************************************
; Prints the ball, at the current cursor position
; Entry:
;
; Returns:
;
; Modifies:
;
; Uses:
;   character: ASCII_BALL
;   attribute: ATTR_BALL
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC PRINT_EMPTY
PRINT_EMPTY PROC NEAR

    PUSH AX
    PUSH BX
    MOV AL, ASCII_FIELD
    MOV BL, ATTR_EMPTY
    CALL PRINT_CHAR_ATTR

    POP BX
    POP AX
    RET

PRINT_EMPTY        ENDP

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
; Initializes Paddles' Position.
; Entry:
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses:
;   Screen size: SCREEN_MAX_ROWS, SCREEN_MAX_COLS
; Calls:
;		-
; ****************************************
PUBLIC INIT_PADDLES
INIT_PADDLES	PROC NEAR

      PUSH AX
      PUSH BX
      PUSH CX
      PUSH DX

			MOV [PAD1_COL], 3

			MOV [PAD2_COL], SCREEN_MAX_COLS
			SUB [PAD2_COL], 4

			MOV AH, 0
			MOV AL, SCREEN_MAX_ROWS
			MOV BL, 2h
			DIV BL
			MOV [PAD1_ROW], AL
			MOV [PAD2_ROW], AL

      POP DX
      POP CX
      POP BX
      POP AX
	RET

INIT_PADDLES		ENDP

; ****************************************
; Initializes Ball Position.
; Entry:
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses:
;   Screen size: SCREEN_MAX_ROWS, SCREEN_MAX_COLS
; Calls:
;		-
; ****************************************
PUBLIC INIT_BALL
INIT_BALL	PROC NEAR

      PUSH AX
      PUSH BX
      PUSH CX
      PUSH DX

			MOV AH, 0
			MOV AL, SCREEN_MAX_ROWS
			MOV DL, 2
			DIV DL
			MOV [BALL_ROW], AL

			MOV AH, 0
			MOV AL, SCREEN_MAX_COLS
			DIV DL
			MOV [BALL_COL], AL

      POP DX
      POP CX
      POP BX
      POP AX
	RET

INIT_BALL		ENDP

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
;   AX: pointer to string
;		BL: vertical offset.
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

		PUSH AX
		PUSH BX
    PUSH CX
    PUSH DX

    CALL GET_CURSOR_PROP  ; Get cursor size
    MOV DH, FIELD_R2
		ADD DH, BL
    MOV DL, FIELD_C1
    CALL SET_CURSOR_PROP

    MOV DX, AX
    CALL PRINT_STRING

    POP CX
    POP DX
		POP BX
		POP AX
    RET

PRINT_SCORE_STRING       ENDP

; ****************************************
; Print the authors string, starting in the cursor
; (FIELD_C1, FIELD_R2) coordinate
; Entry:
;   DX: pointer to string
; Returns:
;   -
; Modifies:
;   -
; Uses:
;   AUTHORS_STR
;   FIELD_C1
;   FIELD_R2
; Calls:
;   GET_CURSOR_PROP
;   SET_CURSOR_PROP
;   PRINT_STRING
; ****************************************
PUBLIC PRINT_AUTHORS_STRING
PRINT_AUTHORS_STRING PROC NEAR

    PUSH CX
    PUSH DX

    CALL GET_CURSOR_PROP  ; Get cursor size
    MOV DH, FIELD_R2+1
    MOV DL, FIELD_C1
    CALL SET_CURSOR_PROP

    LEA DX, AUTHORS_STR
    CALL PRINT_STRING

    POP CX
    POP DX
    RET

PRINT_AUTHORS_STRING       ENDP

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
;   - AX: Score
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
    ;MOV AX, [SCORE1] 	;	THIS NEEDS TO BE CHANGED !!!
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
		PUSH BX
		PUSH CX
		PUSH DX

    ; Do nothing if game is stopped
    CMP [START_GAME], TRUE
    JNZ END_ISR

		; Increment INC_COUNT and check if ball position must be updated (INT_COUNT == DIV_COUNT)
    INC [INT_COUNT]
    MOV AL, [INT_COUNT]
    CMP [DIV_SPEED], AL
    JNZ END_ISR
    MOV [INT_COUNT], 0
		INC [NUM_TILES]
		MOV AH, 0
		MOV AL, [NUM_TILES_INC_SPEED]
		DIV [DIV_SPEED]
		CMP AL, [NUM_TILES]
		JNZ COLLISIONS
		MOV [NUM_TILES], 0
		DEC [DIV_SPEED]
		CMP [DIV_SPEED], 2
		JNL COLLISIONS
		MOV [DIV_SPEED], 2

COLLISIONS:

		; Check Collisions:
		MOV DH, [BALL_ROW]
		MOV DL, [BALL_COL]
		ADD DH, [INC_ROW]
		ADD DL, [INC_COL]
		CALL MOVE_CURSOR
		CALL READ_SCREEN_CHAR
			; AH now stores the read attribute.

		CMP AH, ATTR_TOP
		JZ COLLIDE_TOP

		CMP AH, ATTR_BOTTOM
		JZ COLLIDE_BOTTOM

		CMP AH, ATTR_LEFT
		JZ END_PONG

		CMP AH, ATTR_RIGHT
		JZ END_PONG

		CMP AH, ATTR_PALA1
		JZ PALA1

		CMP AH, ATTR_PALA2
		JZ PALA2

		JMP CONTINUE

COLLIDE_TOP:
		INC [INC_ROW]
		INC [INC_ROW]
		JMP CONTINUE

COLLIDE_BOTTOM:
		DEC [INC_ROW]
		DEC [INC_ROW]
		JMP CONTINUE

PALA1:
		INC [SCORE1]
		INC [INC_COL]
		INC [INC_COL]
		JMP CONTINUE

PALA2:
		INC [SCORE2]
		DEC [INC_COL]
		DEC [INC_COL]
		JMP CONTINUE

CONTINUE:
	; Ball Movement
		MOV DH, [BALL_ROW]
		MOV DL, [BALL_COL]
		CALL MOVE_CURSOR
		CALL PRINT_EMPTY

		ADD DH, [INC_ROW]
		ADD DL, [INC_COL]
		CALL MOVE_CURSOR
		CALL PRINT_BALL
		MOV [BALL_ROW], DH
		MOV [BALL_COL], DL

    JMP END_ISR

END_PONG:
      MOV [END_GAME], TRUE

END_ISR:

			POP DX
			POP CX
			POP BX
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
    INC_ROW DB 1
    INC_COL DB 1

	; PADDLE #1 coordinates
	PAD1_ROW DB SCREEN_MAX_ROWS/2
	PAD1_COL DB 3

	; PADDLE #2 coordinates
	PAD2_ROW DB SCREEN_MAX_ROWS/2
	PAD2_COL DB SCREEN_MAX_COLS-4

	; PADDLE TMPS
	PAD1_TMP DB 0
	PAD2_TMP DB 0

	; BALL coordinates
	BALL_ROW DB SCREEN_MAX_ROWS/2
	BALL_COL DB SCREEN_MAX_COLS/2

	SCORE1 DW 0
	SCORE2 DW 0

    NUM_TILES_INC_SPEED DB 60   ; THE SPEED IS INCREASED EVERY 'NUM_TILES_INC_SPEED'
		NUM_TILES DB 0

    DIV_SPEED DB 6             ; THE SNAKE SPEED IS THE (INTERRUPT FREQUENCY) / DIV_SPEED
    INT_COUNT DB 0              ; 'INT_COUNT' IS INCREASED EVERY INTERRUPT CALL, AND RESET WHEN IT ACHIEVES 'DIV_SPEED'

    START_GAME DB 0             ; 'MAIN' sets START_GAME to '1' when a key is pressed
    END_GAME DB 0               ; 'NEW_TIMER_INTERRUPT' sets END_GAME to '1' when a condition to end the game happens

    SCORE1_STR           DB "Player 1 score is $"
		SCORE2_STR           DB " Player 2 score is $"
    PLAY_AGAIN_STR      DB ". Do you want to play again? (Y/N)$"
	AUTHORS_STR			DB "David Recuenco, Alex Weiland, Fonaments de Computadors, ENTI, 2018$"

DATA_SEG	ENDS

		END MAIN
