; Encode hexadecimal digit
; In: A binary digit in the 0..F range
; Out: A ascii digit, capitalized
; Pollutes: F
HEXD:	AND	0xF
	ADD	A,0x90
	DAA
	ADC	A,0x40
	DAA
	SCF
	RET

; Decode hexadecimal digit
; In: A ascii digit
; Out: A binary digit, CF set, if no error
HEXDD:	SUB	"0"
	CCF
	RET	NC
	CP	0xA
	RET	C
	SUB	"A" - "0"
	CCF
	RET	NC
	AND	0xDF
	ADD	0xA
	CP	0x10
	RET

