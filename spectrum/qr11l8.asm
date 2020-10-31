; see https://github.com/leiradel/qrc1

; ------------------------------------------------------------------------
; Macros for some undocumented Z80 instructions.
; ------------------------------------------------------------------------

addixl: macro
    db $dd
    add a, l
endm

ldixh_a: macro
    db $dd
    ld h, a
endm

decixh: macro
    db $dd
    dec h
endm

decixl: macro
    db $dd
    dec l
endm


QR11L8:	ld	hl, qstr
	ld	(CH_ADD), hl
	call	SCANNING
	call	STK_FETCH
	ld	a, b
	or	c
	jp	z, REPORT_A
	ld	hl, -322
	add	hl, bc
	jp	c, REPORT_A
	; save difference
	push	hl
	ld	hl, qrc11_message + 1
	ld	(hl), c
	inc	hl
	ex	de, hl
	push	bc
	ldir
	pop	bc

; qrc11_message contains a $40 byte followed by the message length followed
; by the message (maximum 251 bytes).
qrc11_encmessage:
    ; ------------------------------------------------------------------------
    ; Encode the message.
    ; ------------------------------------------------------------------------

    ; Insert the high nibble of the length
    ld hl, qrc11_message + 1
    ld a, b

    ; Shift the message to the right by four bits.
    inc bc
    inc c
    dec c
    jr z, qrc11_shift_msg
    inc b

qrc11_shift_msg:
        rrd
        inc hl
    dec c
    jr nz, qrc11_shift_msg
    djnz qrc11_shift_msg

    ; A has the low nibble of the last message byte, shift it to the high
    ; nibble and set the low nibble to 0, which is the end of message mark.
    ld (hl), 0
    rrd
    inc hl

    ; restore difference
    pop bc
    inc bc

    ; Pad the rest of the message with $ec and $11.
    ld a, b
    or c
    jr z, qrc11_no_padding
    ld a, $11
qrc11_pad_msg:
        xor $fd
        ld (hl), a
	inc bc
	ld a, b
	or c
	ld a, (hl)
        inc hl
    jr nz,qrc11_pad_msg

qrc11_no_padding:

    ; ------------------------------------------------------------------------
    ; Calculate the message ECC.
    ; ------------------------------------------------------------------------

    ; Copy each block of the original encoded message to the target buffer,
    ; the ECC evaluation will overwrite it so we need to restore it at the end.
    ld hl, qrc11_block1
    ld de, qrc11_b1
    ld bc, 81
    call qrc11_l_ecc

    ld hl, qrc11_block2
    ld de, qrc11_b2
    ld bc, 81
    call qrc11_l_ecc

    ld hl, qrc11_block3
    ld de, qrc11_b3
    ld bc, 81
    call qrc11_l_ecc

    ld hl, qrc11_block4
    ld de, qrc11_b4
    ld bc, 81
    call qrc11_l_ecc

    ; ------------------------------------------------------------------------
    ; Interleave message and ecc blocks.
    ; ------------------------------------------------------------------------

qrc11_interleave:
    ld hl, qrc11_b1
    ld de, qrc11_message
    ld a, 101
qrc11_intl:
    ldi
    ld bc, 81 + 20 - 1
    add hl, bc
    ldi
    ld c, 81 + 20 - 1
    add hl, bc
    ldi
    ld c, 81 + 20 - 1
    add hl, bc
    ldi
    ld bc, qrc11_b1_ecc - qrc11_b4_ecc
    add hl, bc
    dec a
    jr nz, qrc11_intl

    ; ------------------------------------------------------------------------
    ; Display QR code with checkerboard mask.
    ; ------------------------------------------------------------------------

    ld hl, qrc11_map
    ld c, 61
qrc11_d1:
        ld b, 61
qrc11_d2:   push bc
            ld e, (hl)
            inc hl
            ld d, (hl)
            inc hl
            ld a, e
            and 7
            srl d
            rr e
            srl d
            rr e
            srl d
            rr e
            ld bc, qrc11_message
            ex de, hl
            add hl, bc
            ex de, hl
            ld b, a
            ld a, (de)
            inc b
qrc11_d3:       rlca
                djnz qrc11_d3
            pop bc
            xor b
            xor c
            rrca
            call nc, qrc11_module
            djnz qrc11_d2
        dec c
        jr nz, qrc11_d1
    ret


    ; ------------------------------------------------------------------------
    ; Calculate the block ECC.
    ; ------------------------------------------------------------------------

qrc11_l_ecc:
    ; Save block parameters for restoring
    push hl
    push de
    push bc
    ; Save message block length for later
    push bc
    ; Save message block address for later
    push de
    ldir
    ; Zero the 20 bytes where the ECC will be stored.
    xor a
    ld b, 20
qrc11_zero_ecc:
        ld (de), a
        inc de
    djnz qrc11_zero_ecc

    ; HL is the polynomial A.
    pop hl

    ; IXL is the outer loop counter (i) for the length of A.
    pop ix
qrc11_loop_i:
        ; Save HL as it'll be incremented in the inner loop.
        push hl

        ; Save A[i] in B to be used inside the inner loop.
        ld b, (hl)

        ; DE is the polynomial B.
        ld de, qrc11_l_ecc_poly

        ; Evaluate the inner loop count limit.
        ld a, 21
	addixl
        dec a

        ; IXH is inner loop counter (j) up to length(A) - i.
	ldixh_a

qrc11_loop_j:
            ; A is B[j]
            ld a, (de)

            ; Save DE as we'll use D and E in the gf_mod loop.
            push de

            ; D is A[i], E is the gf_mod result.
            ld d, b
            ld e, 0

            ; A is x, D is y, E is r, C is a scratch register.
            jr qrc11_test_y

qrc11_xor_res:
                ; y had the 0th bit set, r ^= x.
                ld c, a
                xor e
                ld e, a
                ld a, c
qrc11_dont_xor:
                ; x <<= 1, set carry if x >= 256.
                add a, a
                jr nc, qrc11_test_y

                    ; x was >= 256, xor it with the module.
                    xor 285 - 256
qrc11_test_y:
                ; y >>= 1, update r if the 0th bit is set, end the loop if
                ; it's zero.
                srl d
                jr c, qrc11_xor_res
                jr nz, qrc11_dont_xor

            ; A[i + j] ^= gf_mod(...)
            ld a, (hl)
            xor e
            ld (hl), a

            ; Restore DE.
            pop de

            ; Update HL and DE to point to the next bytes of A and B.
            inc hl
            inc de

        ; Inner loop test.
	decixh

        jr nz, qrc11_loop_j

        ; Restore HL since it was changed in the inner loop, and make it point
        ; to the next byte in A.
        pop hl
        inc hl

    ; Outer loop test.
    decixl
    jr nz, qrc11_loop_i

    ; Restore the original encoded message, since the loops above zero it.
    pop bc
    pop de
    pop hl
    ldir
    ret


; The ECC version 11 level L polynomial.
qrc11_l_ecc_poly:
    db 1, 152, 185, 240, 5, 111, 99, 6, 220, 112, 150, 69, 36, 187, 22, 228
    db 198, 121, 121, 165, 174
    ds 81

; The message, it'll be encoded in place.
qrc11_message:
qrc11_block1:
    db $40
    db 0   ; Message length
    ds 79  ; Message source
qrc11_block2:
    ds 81  ; Message source
qrc11_block3:
    ds 81  ; Message source
qrc11_block4:
    ds 81  ; Message source

; Extra space for encoded message
    ds 20 * 4

; Fidex white and black modules
    db $40

qrc11_b1:
    ds 81  ; Message target
qrc11_b1_ecc:
    ds 20  ; Computed ECC
qrc11_b2:
    ds 81  ; Message target
qrc11_b2_ecc:
    ds 20  ; Computed ECC
qrc11_b3:
    ds 81  ; Message target
qrc11_b3_ecc:
    ds 20  ; Computed ECC
qrc11_b4:
    ds 81  ; Message target
qrc11_b4_ecc:
    ds 20  ; Computed ECC

qrc11_module:
	push	bc
	push	hl
	sla	b
	sla	c
	ld	a, 189
	sub	b
	ld	b, c
	ld	c, a
	ld	a, 49
	add	a, b
	ld	b, a
	push	bc
	call	PLOT_SUB
	pop	bc
	inc	b
	push	bc
	call	PLOT_SUB
	pop	bc
	inc	c
	push	bc
	call	PLOT_SUB
	pop	bc
	dec	b
	call	PLOT_SUB
	pop	hl
	pop	bc
	ret

qstr:	db	"q$", 13

qrc11_map:
	incbin	"v11l.bin"
