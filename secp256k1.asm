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
; Out: CF set, if NO carry
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
	AND	A
	INC	L
	LD	B,0x1B
MINCL:	INC	(HL)
	RET	NZ
	INC	L
	DJNZ	MINCL
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

; Canonize modular number
; In: HL pointer to END of 32-byte number to canonize
; Pollutes: AF, BC, DE, HL
MODCAN:	LD	B,0x1B
	LD	A,0xFF
MODCANL:CP	(HL)
	RET	NZ
	DEC	L
	DJNZ	MODCANL
	LD	DE,MODP+5
	LD	B,5
MODCANC:LD	A,(DE)
	CP	(HL)
	JR	C,MODCAND
	DEC	L
	DEC	DE
	DJNZ	MODCANC
	INC	L
	JR	MODSUBP
MODCAND:LD	A,L
	SUB	B
	LD	L,A
	INC	L
	LD	B,0
	JR	MODSUBP

; EC add
; In: HL point A, DE point B
ECADD:	PUSH	DE	; B
	PUSH	HL	; A
	EX	DE,HL	; HL points to B
	LD	DE,ECX
	LD	BC,0x40
	LDIR	; ECX = BX, ECY = BY
	POP	HL	; A
	PUSH	HL	; A
	LD	DE,ECX
	CALL	MODSUB	; ECX = BX - AX
	POP	HL	; A
	PUSH	HL	; A
	LD	BC,0x20
	ADD	HL,BC	; B
	LD	DE,ECY
	CALL	MODSUB	; ECY = BY - AY
	LD	HL,ECX
	LD	DE,ECV
	PUSH	DE
	CALL	MODINV	; ECV = MODINV(BX - AX)
	LD	HL,LAM
	EXX
	POP	DE	; DE = MODINV(BX - AX)
	LD	HL,ECY	; HL = BY - AY
	CALL	MODMUL
	POP	HL
	POP	DE
	JR	ECINT
; EC doubling
; In: HL pointer to point to double
; Out: doubled at ECX,ECY
ECDOUB:	PUSH	HL	; AX
	LD	D,H
	LD	E,L
	EXX
	LD	HL,ECV
	EXX
	CALL	MODMUL	; ECV = AX * AX
	LD	HL,ECV
	LD	DE,ECX
	LD	BC,0x20
	PUSH	BC
	PUSH	DE	; ECX
	PUSH	HL	; ECV
	LDIR		; ECX = AX * AX
	POP	HL	; ECV
	PUSH	HL	; ECV
	CALL	MODDOUB ; ECV = 2 * AX * AX
	POP	DE	; ECV
	POP	HL	; ECX
	CALL	MODADD	; ECX = 3 * AX * AX
	POP	BC	; 0x20
	POP	HL	; AX
	PUSH	HL	; AX
	ADD	HL,BC	; AY
	LD	DE,ECY
	PUSH	DE	; ECY
	LDIR		; ECY = AY
	POP	HL	; ECY
	PUSH	HL	; ECY
	CALL	MODDOUB	; ECY = 2 * AY
	POP	HL	; ECY
	LD	DE, ECV
	PUSH	DE	; ECV
	CALL	MODINV	; ECV = MODINV(2 * AY)
	LD	HL,LAM
	EXX
	POP	HL	; ECV
	LD	DE,ECX
	CALL	MODMUL	; LAM = 3 * AX * AX * MODINV(2 * AY)
	POP	HL	; AX
	LD	D,H
	LD	E,L
; EC intersection
; In: HL pointer to A, DE pointer to B, slope in LAM
; Out: intersection pointed by ECX
ECINT:	PUSH	HL	; AX
	PUSH	DE	; BX
	EXX
	LD	HL,ECX
	PUSH	HL	; ECX
	EXX
	LD	HL,LAM
	LD	DE,LAM
	CALL	MODMUL	; ECX = LAM * LAM
	POP	DE	; ECX
	POP	HL	; BX
	PUSH	DE	; ECX
	CALL	MODSUB	; ECX = LAM * LAM - BX
	POP	DE	; ECX
	POP	HL	; AX
	PUSH	HL	; AX
	CALL	MODSUB	; ECX = (LAM * LAM - BX - AX)
	LD	HL,ECY
	EXX
	POP	HL	; AX
	LD	DE,ECW
	LD	BC,0x20
	LDIR		; ECW = AX
	PUSH	HL	; AY
	LD	HL,ECX
	LD	DE,ECW
	PUSH	DE	; ECW
	CALL	MODSUB	; ECW = AX - ECX
	POP	DE	; ECW
	LD	HL,LAM
	CALL	MODMUL	; ECY = LAM * (AX - ECX)
	LD	DE,ECY
	POP	HL	; AY
	; ECY = LAM * (AX - ECX) - AY
; Modular subtraction/accumulation
; In: DE pointer to 32-byte accumulator, HL pointer to 32-byte number to subtract
; Pollutes: AF, BC, E, L
MODSUB:	LD	B,0x20
	LD	C,E
	AND	A
MSUBL:	LD	A,(DE)
	SBC	A,(HL)
	LD	(DE),A
	INC	L
	INC	E
	DJNZ	MSUBL
	RET	NC
	LD	H,D
	LD	L,C
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
	AND	A
	INC	L
	LD	B,0x1B
MDECL:	DEC	(HL)
	RET	P
	INC	L
	DJNZ	MDECL
	SCF
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
	LD	L,MODINVU - 0x100 * (MODINVU / 0x100)
	INC	(HL)
	LD	L,MODINVU - 0x100 * (MODINVU / 0x100) + 0x21
	INC	(HL)
	; A := 0
MODINV0:LD	HL,(MODINVA)
	LD	E,L
	LD	D,H
	INC	E
	LD	BC,0x1F
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
	LD	D,H
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
	LD	H,D
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
MODINV1:CP	(HL)
	JR	NZ,MODINV2
	DEC	L
	DJNZ	MODINV1
MODINV2:LD	L,C
	LD	(HL),B
	RET

MODP:	DEFB	0x20, 0x2F, 0xFC, 0xFF, 0xFF, 0xFE, 0xFF

; EC point multiplication
; In: HL - EC point to multiply, DE - last (most significant) byte of index
ECMUL:	PUSH	DE
	PUSH	HL
	LD	DE,ECB
	LD	BC,0x40
	LDIR
	POP	HL
	POP	DE
	LD	BC,0x0080
ECMULL:	LD	A,(DE)
	AND	C
	JR	NZ,ECMULS
	RRC	C
	JR	NC,ECMULB
	DEC	DE
ECMULB:	DJNZ	ECMULL
	RET

ECMULX:	PUSH	HL
	PUSH	BC
	PUSH	DE
	LD	HL,ECB
	CALL	ECDOUB
	CALL	ECMULC
	POP	DE
	POP	BC
	POP	HL
	LD	A,(DE)
	AND	C
	JR	Z,ECMULS
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	DE,ECB
	CALL	ECADD
	CALL	ECMULC
	POP	HL
	POP	DE
	POP	BC
ECMULS:	RRC	C
	JR	NC,ECMULW
	DEC	DE
ECMULW:	DJNZ	ECMULX
	RET
ECMULC:	LD	HL,ECX
	LD	DE,ECB
	LD	BC,0x40
	LDIR
	RET
