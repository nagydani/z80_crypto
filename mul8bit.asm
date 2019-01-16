; 8 x 8 to 16 bit multiplication
; In: B, C multiplicands
; Out: HL product
; Pollutes: AF, F', BC, DE

MUL8:	LD	H,MULTAB/0x100
	LD	A,B
	ADD	A,C
	RRA
	LD	L,A
	LD	E,(HL)
	INC	H
	LD	D,(HL)
	PUSH	DE
	LD	A,B
	SUB	A,C
	JR	NC,NOSWAP
	NEG
	LD	C,B
	AND	A
NOSWAP:	RRA
	LD	L,A
	EX	AF,AF'	; SAVE CARRY
	LD	D,(HL)
	DEC	H
	LD	E,(HL)
	POP	HL
	AND	A
	SBC	HL,DE
	EX	AF,AF'	; LOAD CARRY
	RET	NC
	LD	B,0
	ADD	HL,BC
	RET
	INCLUDE "multab.asm"
