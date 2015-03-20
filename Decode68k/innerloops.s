
; These are sketches for some innerloops that might run faster than the default implementation



.samplePair
	move.b	(a0)+,d0		; 8
	move.b	d0,d1			; 4
	and.b	#$f,d1			; 8
	lsr.b	#4,d0			; 16
					; = 36

.firstSample
	add.b	(a1,d0.w),d2		; 16
	spl	d3			; 4
	and.b	d3,d2			; 4
	cmp.b	#88,d2			; 8
	bls.s	.nClamp2		; 12
	moveq	#88,d2
.nClamp2

	lsl.w	#4,d0			; 16
	jmp	.routines(pc,d0.w)	; 16

.routines (16 variants)
	move.w	d7,d4			; 4
	move.w	d4,d0			; 4
	asr.w	#1,d4			; 8
	add.w	d4,d0			; 4
	asr.w	#1,d4			; 8
	add.w	d4,d0			; 4
	asr.w	#1,d4			; 8
	add.w	d4,d0			; 4
	ext.l	d0			; 4
	add.l	d0,d6			; 8
	bra.s	.routineDone		; 12

.routineDone

	cmp.l	#32767,d6		; 12
	ble.s	.nClamp3		; 12
	move.l	#32767,d6
.nClamp3
	cmp.l	#-32768,d6		; 12
	bge.s	.nClamp4		; 12
	move.l	#-32768,d6
.nClamp4

	move.w	d2,d0			; 4
	add.w	d0,d0			; 4
	move.w	(a2,d0.w),d7		; 16

	move.w	d6,(a3)+		; 8
					; = 224 approx

; repeat for value in d1

	dbf	d5,.samplePair		; 12

					; = 500 for a sample pair approx

===============================================================================================0

; full ADPCM

.samplePair
	move.b	(a0)+,d0		; 8
	move.b	d0,d1			; 4
	and.b	#$f,d1			; 8
	lsr.b	#4,d0			; 16
					; = 36

.firstSample
	add.w	d0,d0			; 4
	add.w	d0,d0			; 4
	move.w	d2,d3			; 4
	add.w	d0,d3			; 4

	add.w	(a1,d0.w),d2		; 16
	spl	d4			; 4
	ext.w	d4			; 4
	and.w	d4,d2			; 4
	cmp.w	d5,d2			; 4		; d5 == 88<<6
	bhi.s	.handleIndexClamp	; 8		; clamp index against 88<<6
.indexClampDone

	add.l	(a2,d3.w),d6		; 16
	cmp.l	a4,d6			; 8
	blt.s	.clampMin		; 8
	cmp.l	a5,d6			; 8
	bgt.s	.clampMax		; 8

.outputClampDone
	move.w	d6,(a3)+		; 8

					; = 112 approx

	; repeat for sample in d1

	dbf	d7,.samplePair		; 12

					; = 272 for a sample pair approx

===============================================================================================0

; hacked ADPCM with maxdelta 32k

.samplePair
	move.b	(a0)+,d0		; 8
	move.b	d0,d1			; 4
	and.b	#$f,d1			; 8
	lsr.b	#4,d0			; 16
					; = 36

.firstSample
	add.w	d0,d0			; 4
	move.w	d2,d3			; 4
	add.w	d0,d3			; 4

	add.w	(a1,d0.w),d2		; 16
	spl	d4			; 4
	ext.w	d4			; 4
	and.w	d4,d2			; 4
	cmp.w	d5,d2			; 4		; d5 == 88<<5
	bhi.s	.handleIndexClamp	; 8		; clamp index against 88<<5
.indexClampDone

	add.w	(a2,d3.w),d6		; 16
	bvs.s	.handleOutputClamp	; 8		; redo, clamp against -32k .. +32k
.outputClampDone

	move.w	d6,(a3)+		; 8

					; = 84 approx

	; repeat for sample in d1

	dbf	d7,.samplePair		; 12

					; = 216 for a sample pair approx

===============================================================================================0


