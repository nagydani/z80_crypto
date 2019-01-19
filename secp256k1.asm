; Modular multiplication
; In: HL,DE pointers to multiplicands, HL' pointer to product + buffer
; Out: HL pointer to after product (product at HL - 0x20)
; Pollutes: AF, AF', BC, BC', DE, HL'= original HL, DE'= original DE
MODMUL:	LD	B,0x20
	CALL	BIGMUL
	EXX
	LD	B,0x20
	LD	A,L
	SUB	A,B
	LD	E,A
	LD	D,H
	SUB	A,B
	LD	L,A
	CALL	MODADDX
	LD	A,C
	ADD	A,0x20
	LD	L,A
	CALL	MODDOUB
	LD	A,0x2F
MODMULL:EX	AF,AF'
	LD	L,C
	CALL	MODDOUB
	EX	AF,AF'
	ADD	A,A
	JR	NC,MODMULN
	EX	AF,AF'
	LD	A,C
	SUB	A,0x20
	LD	L,A
	LD	E,C
	CALL	MODADD
	LD	A,C
	ADD	0x20
	LD	C,A
	EX	AF,AF'
MODMULN:JR	NZ,MODMULL
	LD	A,E
	SUB	A,0x20
	LD	E,A
	LD	A,0x17
MODSHL:	EX	AF,AF'
	LD	L,E
	CALL	MODDOUB
	EX	AF,AF'
	DEC	A
	JR	NZ,MODSHL
	LD	A,E
	SUB	A,0x20
	LD	L,A
; Modular addition/accumulation
; In: HL pointer to 32-byte accumulator, DE pointer to 32-byte number to add
; Pollutes: AF, BC, E, L
MODADD:	LD	B,0x20
MODADDX:LD	C,L
	AND	A
MADDL:	LD	A,(DE)
	ADC	A,(HL)
	LD	(HL),A
	INC	L
	INC	E
	DJNZ	MADDL
	RET	NC
MODCORR:LD	L,C
; Subtract P
; In: HL pointer to 32-byte accumulator, B = 0
; Out: CF set, if carry
MODSUBP:LD	A,(HL)
	ADD	A,0xD1
	LD	(HL),A
	INC	L
	LD	A,(HL)
	ADC	A,0x03
	LD	(HL),A
	INC	L
	LD	A,(HL)
	ADC	A,B
	LD	(HL),A
	INC	L
	LD	A,(HL)
	ADC	A,B
	LD	(HL),A
	INC	L
	INC	B
	LD	A,(HL)
	ADC	A,B
	LD	(HL),A
	RET	NC
	INC	L
	LD	B,0x1B
MINCL:	INC	(HL)
	RET	NZ
	INC	L
	DJNZ	MINCL
	SCF
	RET

; Modular subtraction/accumulation
; In: DE pointer to 32-byte accumulator, HL pointer to 32-byte number to subtract
; Pollutes: AF, BC, E, L
MODSUB:	LD	B,0x20
MODSUBX:LD	C,L
	AND	A
MSUBL:	LD	A,(DE)
	SBC	A,(HL)
	LD	(DE),A
	INC	L
	INC	E
	DJNZ	MSUBL
	RET	NC
; Add P
; In: HL pointer to 32-byte accumulator, B = 0
; Out: CF set, if NO carry
MODADDP:LD	A,(HL)
	SUB	A,0xD1
	LD	(HL),A
	INC	L
	LD	A,(HL)
	SBC	A,0x03
	LD	(HL),A
	INC	L
	LD	A,(HL)
	SBC	A,B
	LD	(HL),A
	INC	L
	LD	A,(HL)
	SBC	A,B
	LD	(HL),A
	INC	L
	INC	B
	LD	A,(HL)
	SBC	A,B
	LD	(HL),A
	RET	NC
	INC	L
	LD	B,0x1B
MDECL:	DEC	(HL)
	RET	P
	INC	L
	DJNZ	MDECL
	SCF
	RET
; Modular doubling
; In: HL pointer to 32-byte number to double
; Pollutes: AF, BC, L
MODDOUB:LD	B,0x20
MODDBX:	LD	C,L
	OR	A
MODDBL:	RL	(HL)
	INC	L
	DJNZ	MODDBL
	JR	C,MODCORR
	RET

; Modular inverse
; In: HL pointer to 32-byte number to invert (X) , DE pointer to result
MODINV:	LD	(MODINVA),DE
	LD	DE,MODINVU
	; U := X
	LD	BC,0x20
	LD	A,C
	LD	(DE),A
	INC	E
	LDIR
	EX	DE,HL
	LD	(HL),B
	LD	L,MODINVU - 0x100 * (MODINVU / 0x100) + 1
	SCF
	BIT	0,(HL)
	; If X is even, U := X + P
	CALL	Z,MODADDP
	JR	C,MODINV0
	INC	(HL)
	LD	L,MODINVU - 0x100 * (MODINVU / 0x100)
	CALL	MODINVN
	; A := 0
MODINV0:LD	HL,(MODINVA)
	LD	E,L
	LD	D,H
	INC	E
	LD	C,0x1F
	LD	(HL),B
	LDIR
	; V := P
	LD	HL,MODP
	LD	DE,MODINVV
	LD	C,7
	LDIR
	LD	L,E
	LD	H,D
	DEC	L
	LD	C,0x1A
	LDIR
	EX	DE,HL
	LD	(HL),C
	; D = P - 1
	LD	DE,MODINVD + 0x1F
	DEC	L
	LD	C,0x20
	LDDR
	EX	DE,HL
	INC	L
	DEC	(HL)
	; while V != 1
MODINVL:LD	HL,MODINVV
	CALL	MODINVN
	LD	A,1
	CP	B
	JR	NZ,MODINVC
	INC	L
	CP	(HL)
	JR	NZ,MODINVC
	RET
	; while U > V
MODINVC:LD	DE,MODINVU
	LD	A,(DE)
	LD	HL,MODINVV
	LD	B,(HL)
	CP	B
	JR	C,MODINVS	; U < V
	JR	NZ,MODINVW	; V < U
	LD	B,A
	ADD	A,L
	LD	L,A
	LD	A,B
	ADD	A,E
	LD	E,A
MODINVX:LD	A,(DE)
	CP	(HL)
	JR	C,MODINVS
	JR	NZ,MODINVW
	DEC	E
	DEC	L
	DJNZ	MODINVX
	; U := U - V
MODINVW:LD	E,MODINVU - 0x100 * (MODINVU / 0x100)
	LD	L,MODINVV - 0x100 * (MODINVV / 0x100)
	CALL	MODINVE
	LD	(MODINVUV),HL
	; D := (D + A) mod P
	LD	L, MODINVD - 0x100 * (MODINVD / 0x100)
	LD	DE,(MODINVA)
	CALL	MODADD
	; If D is odd, D := D + P
	CALL	MODINV5
	JR	MODINVC
	; V := V - U
MODINVS:LD	DE,MODINVV
	LD	HL,MODINVU	; MAY BE UNNECESSARY
	CALL	MODINVE
	LD	(MODINVUV),HL
	; A := (A + D) mod P
	LD	HL,(MODINVA)
	LD	DE,MODINVD
	CALL	MODADD
	; If A is odd, A := A + P
	CALL	MODINV5
	JP	MODINVL

; Repeat {If DA is odd {DA := DA + P}; DA := DA / 2; UV := UV / 2} while UV is even
MODINV5:LD	L,C
	BIT	0,(HL)
	SCF
	LD	B,0
	CALL	NZ,MODADDP
	CCF
	EX	AF,AF'	; save carry
	LD	A,C
	ADD	A,0x1F
	LD	L,A
	EX	AF,AF'	; restore carry
	; DA := DA / 2
MODINVR:LD	B,0x20
MODINVH:RR	(HL)
	DEC	L
	DJNZ	MODINVH
	; UV : = UV / 2
	LD	HL,(MODINVUV)
	LD	A,(HL)
	LD	B,A
	ADD	A,L
	LD	L,A
MODINV6:RR	(HL)
	DEC	L
	DJNZ	MODINV6
	INC	L
	BIT	0,(HL)
	JR	Z,MODINV5
	DEC	L
	JR	MODINVN

; Long subtraction
; In: DE pointer to minuend, HL pointer to subtrahend
; Output: HL pointer to difference in place of minuend
; Pollutes: AF, BC, DE
MODINVE:LD	A,(DE)
	LD	C,E
	LD	B,A
	AND	A
MODINVY:INC	E
	INC	L
	LD	A,(DE)
	SBC	A,(HL)
	LD	(DE),A
	DJNZ	MODINVY
	LD	E,C
	EX	DE,HL
; Normalize U or V
; In: HL pointer to U or V to be normalized
; Pollutes: A, BC
MODINVN:LD	A,(HL)
	LD	C,L
	LD	B,A
	ADD	A,L
	LD	L,A
	XOR	A
MOVINV1:CP	(HL)
	JR	NZ,MOVINV2
	DEC	L
	DJNZ	MOVINV1
MOVINV2:LD	L,C
	LD	(HL),B
	RET

MODP:	DEFB	0x20, 0x2F, 0xFC, 0xFF, 0xFF, 0xFE, 0xFF
