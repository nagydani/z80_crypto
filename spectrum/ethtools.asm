PRINT_OUT:	EQU	0x09F4
ED_LOOP:	EQU	0x0F38
CHAN_OPEN:	EQU	0x1601
MAKE_ROOM:	EQU	0x1655
STR_DATA1:	EQU	0x1727
SCANNING:	EQU	0x24FB
STK_STO:	EQU	0x2AB2
STK_FETCH:	EQU	0x2BF1
STK_PNTRS:	EQU	0x35BF
CH_TAB:		EQU	0x5C34
ERR_NR:		EQU	0x5C3A
TV_FLAG:	EQU	0x5C3C
CHANS:		EQU	0x5C4F
CURCHL:		EQU	0x5C51
PROG:		EQU	0x5C53
CH_ADD:		EQU	0x5C5D
FLAGS2:		EQU	0x5C6A
ATTR_T:		EQU	0x5C8F

	ORG	43264	; 0xA900
	INCLUDE	"../secp256k1tab.asm"
	INCLUDE	"tobinary.asm"
	DEFS	59994 - $
; Floatingpoint decoding of a
	JP	FPDEC
; Hexadecimal decoding of a$
	JP	STRDEC
; Hasher channel initialization
	JP	INITCH
; Ethereum address capitalization in a$
	JP	ETHADD
; Public key derivation from private key in k$
	JP	PUBKEY
; Passphrase input hidden by stars
	JP	HIDEPW
; ECDSA signing of the hasher state
SIGN:	CALL	ECDSAS
; EIP-2 canonization
	LD	HL,ECDSAM + 0x1F
	BIT	7,(HL)			; not quite perfect, but good in practice
	JR	Z,EIP2			; already EIP-2 compliant
	PUSH	AF			; save V
	LD	B,0x20
TURNS:	LD	A,(HL)
	CPL
	LD	(HL),A
	DEC	L
	DJNZ	TURNS			; complement S
	INC	L
	PUSH	HL			; save ECDSAM
	LD	B,0x20
INCS:	INC	A
	LD	(HL),A
	JR	NZ,ADDQS
	INC	L
	LD	A,(HL)
	DJNZ	INCS			; increment S
ADDQS:	POP	HL			; restore ECDSAM
	CALL	MODADDQ
	POP	HL			; restore V
	LD	A,0x37
	SUB	H			; flip V
EIP2:	LD	HL,STATE0
	SET	5,(HL)
	LD	HL,KECCAKS + 0x61
	LD	(HL),A
	LD	DE,ECDSAM
	CALL	MIRROR
	LD	DE,ECX
	CALL	MIRROR
	LD	(KECCAKP),HL
	JR	RETBAS
MIRROR:	LD	B,0x20
SIGNL1:	LD	A,(DE)
	INC	E
	DEC	L
	LD	(HL),A
	DJNZ	SIGNL1
	RET

; Public key derivation from private key in k$
PUBKEY:	LD	HL,(CH_ADD)
	PUSH	HL
	LD	HL,VARKEY
	LD	(CH_ADD),HL
	CALL	SCANNING
	POP	HL
	LD	(CH_ADD),HL
	CALL	STK_FETCH
	LD	A,B
	OR	A
	RET	NZ
	LD	B,0x40
	LD	A,C
	CP	B
	RET	NZ
	LD	HL,PRIVK + 0x1F
PRIVKL:	LD	A,(DE)
	INC	DE
	CALL	HEXDD
	RET	NC
	RLD
	BIT	0,B
	JR	Z,HEXB
	DEC	HL
HEXB:	DJNZ	PRIVKL
	LD	DE,PRIVK + 0x1F
	CALL	ECGMUL
	LD	HL,ECB
	CALL	MODCAN
	LD	HL,ECB + 0x20
	CALL	MODCAN
	CALL	KECCAKI
	LD	HL,ECB+0x1F
	LD	DE,KECCAKS
	CALL	HASHKC
	LD	L,ECB - 0x100 * (ECB/ 0x100) + 0x3F
	CALL	HASHKC
	LD	(KECCAKP),DE
	CALL	KECCAK
	LD	HL,KECCAKS + 0xC
	LD	(KECCAKP),HL
	LD	HL,STATE0
	SET	5,(HL)
RETBAS:	LD      HL,0x2758
	EXX
	LD	BC,0
	RET

HASHKC:	LD	B,0x20
HASHKL:	LD	A,(HL)
	DEC	L
	LD	(DE),A
	INC	E
	DJNZ	HASHKL
	RET

VAR_FETCH:
	LD	HL,(CH_ADD)
	PUSH	HL
	LD	HL,VARADD
	LD	(CH_ADD),HL
	CALL	SCANNING
	POP	HL
	LD	(CH_ADD),HL
	CALL	STK_FETCH
	LD	A,B
	OR	A
	RET

; Ethereum address checker
; Error codes: 0 OK, 1..40 wrong capitalization, >40 wrong format
ETHADD:	CALL	VAR_FETCH
	JR	NZ,ETHADDE
	DEC	B
	LD	A,C
	CP	0x28
	CALL	Z,ERC55
ETHADDE:PUSH	BC
	CALL	INIT2
	POP	BC
	EXX
	LD	HL,0x2758
	EXX
	RET

; Passphrase input hidden by stars
HIDEPW:	LD	HL,(CURCHL)
	LD	DE,OLD_OUT
	LDI
	LDI
	DEC	HL
PWHIDE:	LD	(HL),PWOUT/0x100
	DEC	HL
	LD	(HL),PWOUT-0x100*(PWOUT/0x100)
	RET
PWOUT:	OR	A
	JR	Z,PWREST
	CP	0x0E
	JR	Z,PWFLASH
	CP	0x80
	JR	Z,PWBLANK
	BIT	7,(IY+ATTR_T-ERR_NR)
	JR	NZ,PWBLANK
	LD	A,"*"
PWBLANK:SCF
OLD_OUT:EQU	$ + 1
PWCTRL:	CALL	PRINT_OUT
	RES	7,(IY+ATTR_T-ERR_NR)
	LD	HL,(CURCHL)
	INC	HL
	JR	PWHIDE
PWFLASH:CALL	PWBLANK
	SET	7,(IY+ATTR_T-ERR_NR)
	RET
PWREST:	LD	HL,(CURCHL)
	LD	DE,(OLD_OUT)
	LD	(HL),E
	INC	HL
	LD	(HL),D
	INC	HL
	XOR	A
	EX	DE,HL
	JP	(HL)

; Channel initialization
INITCH:	LD	A,(ED_LOOP + 3)
	CP	0xF5		; PUSH AF?
	JR	NZ,NOBUG	; ROM bug fixed
	LD	A,WRKRND - INPTR
	LD	(INPTR),A	; Workaround activated
NOBUG:	LD	HL,(CH_TAB)
	LD	A,H
	OR	L
	RET	NZ		; Channel already open
	LD	HL,(PROG)
	DEC	HL
 	LD	BC,STREAME-STREAM
	PUSH	BC
	CALL	MAKE_ROOM
	LD	HL,STREAM+10
	POP	BC
	LDDR
	EX	DE,HL
	LD	DE,(CHANS)
	AND	A
	SBC	HL,DE
	INC	HL
	INC	HL
	LD	(CH_TAB),HL
INIT2:	LD	HL,STATE0
	RES	6,(HL)
INIT3:	RES	5,(HL)
	JR	KECCAKI
WRITE:	LD	HL,STATE0
	BIT	5,(HL)
	CALL	NZ,INIT3
	EXX
	PUSH	BC
	PUSH	DE
	CALL	KECCAKU
	POP	DE
	POP	BC
	EXX
	RET
READ:	LD	HL,STATE0
	BIT	5,(HL)
	PUSH	HL
	CALL	Z,KECCAK
	POP	HL
	SET	5,(HL)
	BIT	3,(IY+TV_FLAG-ERR_NR)
INPTR:	EQU	$ + 1
	JR	NZ,INPUT
	CALL	KECCAKR
	SCF
	RET
WRKRND:	LD	HL,6
	ADD	HL,SP
	LD	(HL),0x48	; Work around BEEPER bug in INPUT
INPUT:	LD	HL,(KECCAKP)
	LD	A,L
	CP	KECCAKS - 0x100 * (KECCAKS / 0x100) + 0x20
	JR	Z,INPUTE
	CP	KECCAKS - 0x100 * (KECCAKS / 0x100) + 0x62
	JR	Z,INPUTE
	LD	A,(STATE0)
	XOR	0x40
	LD	(STATE0),A
	AND	0x40
	LD	A,(HL)
	RRCA
	RRCA
	RRCA
	RRCA
	CALL	Z,KECCAKR
	INCLUDE	"hex.asm"

INPUTE:	CALL	INIT2
	RES	3,(IY+TV_FLAG-ERR_NR)	; Work around another bug in INPUT
	LD	A,0xD
	SCF
	RET

	INCLUDE	"../keccak.asm"
	INCLUDE "../erc55.asm"
	INCLUDE	"../secp256k1.asm"
	INCLUDE "../bigmul.asm"
	INCLUDE	"../ecdsa.asm"
	INCLUDE "../mul8bit.asm"
	INCLUDE "../multab.asm"
STREAM:	DEFW	WRITE
	DEFW	READ
	DEFB	"H"
STATE0:	DEFB	0
STATE1:	DEFB	0
STATE2:	DEFB	0
STATE3:	DEFB	0
	DEFW	STREAME- STREAM
STREAME:EQU	$
VARADD:	DEFM	"A$"
	DEFB	0x0D
VARKEY:	DEFM	"K$"
	DEFB	0x0D
	INCLUDE	"../keccaktab.asm"
KECCAKB:EQU	IOTAT + 0x100
KECCAKS:EQU	KECCAKB + 48
KECCAKP:EQU	KECCAKS + 200
MODINVU:EQU	KECCAKB + 0x100
MODINVV:EQU	MODINVU + 0x22
MODINVD:EQU	MODINVV + 0x22
MODINVA:EQU	MODINVD + 0x20
MODINVUV:EQU	MODINVA + 0x2
ECB:	EQU	MODINVUV + 0x2
PRIVK:	EQU	ECB + 0x40
ECDSAZ:	EQU	PRIVK + 0x20
ECX:	EQU	MODINVU + 0x100
ECY:	EQU	ECX + 0x20
ECV:	EQU	ECY + 0x20
LAM:	EQU	ECX + 0x100
ECW:	EQU	LAM + 0x20
ECDSAM:	EQU	LAM
ECDSAK:	EQU	ECDSAM + 0x100
