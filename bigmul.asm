; Karatsuba multiplication
; In: HL,DE pointers to multiplicands, B: length of multiplicands in bytes, HL' pointer to product + buffer
; Out: HL' pointer to after product (product at HL' - 2*B)
; Pollutes: AF, AF', C, BC', DE', 2*B+1 bytes after HL'
; Note: crossing of page boundaries prohibited!
BIGMUL:	DJNZ	MULBIG
	LD	C,(HL)
	LD	A,(DE)
	LD	B,A
	PUSH	HL
	PUSH	DE
	CALL	MUL8
	LD	A,L
	EXX
	LD	(HL),A
	INC	L
	EXX
	LD	A,H
	EXX
	LD	(HL),A
	INC	L
	EXX
	POP	DE
	POP	HL
	LD	B,1
	RET
MULBIG:	INC	B
	SRL	B
	CALL	BIGMUL
; HL[  X0  ][  X1  ], DE[  Y0  ][  Y1  ], [  X0  *   Y0  ]HL'
	LD	A,L
	ADD	B
	LD	L,A
	LD	A,E
	ADD	B
	LD	E,A
; [  X0  ]HL[  X1  ], [  Y0  ]DE[  Y1  ], [  X0  *   Y0  ]HL'
	CALL	BIGMUL
; [  X0  ]HL[  X1  ], [  Y0  ]DE[  Y1  ], [  X0  *   Y0  ][  X1  *   Y1  ]HL'
	PUSH	DE
	LD	A,L
	SUB	B
	LD	E,A
	LD	D,H
; DE[  X0  ]HL[  X1  ], [  X0  *   Y0  ][  X1  *   Y1  ]HL'
	CALL	BIGADD
; [  X0  ]DE[  X1  ]HL, [  X0  *   Y0  ][  X1  *   Y1  ][X0+X1 ]HL'
	POP	DE
	PUSH	HL
	PUSH	AF	; save carry
	LD	A,E
	SUB	B
	LD	L,A
	LD	H,D
; HL[  Y0  ]DE[  Y1  ], [  X0  *   Y0  ][  X1  *   Y1  ][X0+X1 ]HL'
	CALL	BIGADD
; [  Y0  ]HL[  Y1  ]DE, [  X0  *   Y0  ][  X1  *   Y1  ][X0+X1 ][Y0+Y1 ]HL'
	PUSH	DE
	PUSH	AF	; save carry
	EXX
	PUSH	HL
	EXX
	POP	HL
	LD	A,L
	SUB	A,B
	LD	L,A
	SUB	A,B
	LD	E,A
	LD	D,H
; [  X0  *   Y0  ][  X1  *   Y1  ]DE[X0+X1 ]HL[Y0+Y1 ]HL'
	CALL	BIGMUL
; [  X0  *   Y0  ][  X1  *   Y1  ]DE[X0+X1 ]HL[Y0+Y1 ][(X0+X1)(Y0+Y1)]HL'
	POP	AF	; restore carry
	LD	A,B
	EXX
	LD	(HL),0
; [  X0  *   Y0  ][  X1  *   Y1  ]DE'[X0+X1 ]HL'[Y0+Y1 ][(X0+X1)(Y0+Y1)]HL
	LD	B,A
	JR	NC,MBNC1
	LD	A,L
	SUB	A,B
	LD	L,A
	SUB	A,B
	SUB	A,B
	SUB	A,B
	LD	E,A
	LD	D,H
MBADD0:	LD	A,(DE)
	ADC	A,(HL)
	LD	(HL),A
	INC	L
	INC	E
	DJNZ	MBADD0
; [  X0  *   Y0  ][  X1  *   Y1  ]DE'[X0+X1 ]HL'DE[Y0+Y1 ][(X0+X1)(Y0+Y1)]HL
	LD	A,B
	ADC	A,B
	LD	(HL),A
	EXX
	POP	DE
; [  Y0  ][  Y1  ]DE, [  X0  *   Y0  ][  X1  *   Y1  ][X0+X1 ]HLDE'[Y0+Y1 ][(X0+X1)(Y0+Y1)]HL'
	POP	AF	; restore carry
	JR	NC,MBNC0
	EXX
	INC	(HL)
	EXX
	JR	MBC01
MBNC1:	EXX
	POP	DE
; [  Y0  ][  Y1  ]DE, [  X0  *   Y0  ][  X1  *   Y1  ][X0+X1 ]HLDE'[Y0+Y1 ][(X0+X1)(Y0+Y1)]HL'
	POP	AF	; restore carry
	JR	NC,MBNC0
MBC01:	PUSH	DE
	LD	A,B
	ADD	A,A
	ADD	A,L
	LD	E,A
	LD	D,H
	LD	C,B
	EX	DE,HL
MBC0:	LD	A,(DE)
	ADC	A,(HL)
	LD	(HL),A
	INC	L
	INC	E
	DJNZ	MBC0
	LD	A,(HL)
	ADC	A,B
	LD	(HL),A
	LD	B,C
	POP	DE
MBNC0:	POP	HL
; [  X0  ][  X1  ]HL, [  Y0  ][  Y1  ]DE, [  X0  *   Y0  ][  X1  *   Y1  ][X0+X1 ][Y0+Y1 ][(X0+X1)(Y0+Y1)]HL'
	LD	A,B
	EXX
	LD	C,A
	ADD	A,A
	LD	B,A
	LD	A,L
	SUB	A,B
	LD	E,A
	LD	D,H
; [  X0  ][  X1  ]HL', [  Y0  ][  Y1  ]DE', [  X0  *   Y0  ][  X1  *   Y1  ][X0+X1 ][Y0+Y1 ]DE[(X0+X1)(Y0+Y1)]HL
	SUB	A,B
	SUB	A,B
	SUB	A,B
	LD	L,A
; [  X0  ][  X1  ]HL', [  Y0  ][  Y1  ]DE', HL[  X0  *   Y0  ][  X1  *   Y1  ][X0+X1 ][Y0+Y1 ]DE[(X0+X1)(Y0+Y1)]
MBSUB0:	LD	A,(DE)
	SBC	A,(HL)
	LD	(DE),A
	INC	L
	INC	E
	DJNZ	MBSUB0
	EX	DE,HL
	LD	A,(HL)
	SBC	A,B
	LD	(HL),A
; [  X0  ][  X1  ]HL', [  Y0  ][  Y1  ]DE', [  X0  *   Y0  ]DE[  X1  *   Y1  ][X0+X1 ][Y0+Y1 ][(X0+X1)(Y0+Y1)-X0Y0   ]
	LD	A,C
	ADD	A,A
	LD	B,A
	ADD	A,E
	ADD	A,B
	LD	L,A
	EX	DE,HL
; [  X0  ][  X1  ]HL', [  Y0  ][  Y1  ]DE', [  X0  *   Y0  ]HL[  X1  *   Y1  ][X0+X1 ][Y0+Y1 ]DE[(X0+X1)(Y0+Y1)-X0Y0   ]
MBSUB1:	LD	A,(DE)
	SBC	A,(HL)
	LD	(DE),A
	INC	L
	INC	E
	DJNZ	MBSUB1
	EX	DE,HL
	LD	A,(HL)
	SBC	A,B
	LD	(HL),A
; [  X0  ][  X1  ]HL', [  Y0  ][  Y1  ]DE', [  X0  *   Y0  ][  X1  *   Y1  ]DE[X0+X1 ][Y0+Y1 ][(X0+X1)(Y0+Y1)-X0Y0-X1Y1]
	LD	A,C
	ADD	A,A
	ADD	A,E
	LD	L,A
; [  X0  ][  X1  ]HL', [  Y0  ][  Y1  ]DE', [  X0  *   Y0  ][  X1  *   Y1  ]DE[X0+X1 ][Y0+Y1 ]HL[(X0+X1)(Y0+Y1)-X0Y0-X1Y1]
	LD	A,C
	ADD	A,A
	LD	B,A
	LD	A,E
	SUB	A,B
	SUB	A,C
	LD	E,A
	INC	B
MBADD:	LD	A,(DE)
	ADC	A,(HL)
	LD	(DE),A
	INC	L
	INC	E
	DJNZ	MBADD
	EX	DE,HL
	JR	NC,MBZERO
	LD	E,L
	DEC	L
MBINC:	INC	L
	INC	(HL)
	JR	Z,MBINC
	LD	L,E
MBZERO:	LD	A,L
	ADD	C
	DEC	A
	LD	L,A
	EXX
; [  X0  ][  X1  ]HL, [  Y0  ][  Y1  ]DE, [  X   *   Y                   ]HL'
	SLA	B
	LD	A,L
	SUB	A,B
	LD	L,A
	LD	A,E
	SUB	A,B
	LD	E,A
; HL[  X0  ][  X1  ], DE[  Y0  ][  Y1  ], [  X   *   Y                   ]HL'
	RET

BIGADD:	LD	C,B
BADDL:	LD	A,(DE)
	ADC	A,(HL)
	INC	E
	INC	L
	EXX
	LD	(HL),A
	INC	L
	EXX
	DJNZ	BADDL
	LD	B,C
	RET

