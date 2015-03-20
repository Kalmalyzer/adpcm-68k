
; IMA ADPCM decode routine optimized for 68000
; It takes in a mono datastream encoded to 4-bit entries, and outputs a stream of signed 16-bit samples.
; Performance: decodes roughly 50kSamples/second on an 8MHz Atari ST
;
; Written by: Mikael Kalms, 2009-09-26


		section	text

;-------------------------------------------------------------------------
; Call this routine once to initialize the tables.
		
adpcmInit
		lea	adpcmIndexTable,a0
		moveq	#16-1,d0
.index
		move.l	(a0),d1
		lsl.l	#6,d1
		move.l	d1,(a0)+
		dbf	d0,.index
		
		lea	adpcmStepTable+89*4,a0
		lea	adpcmStepTable+89*16*4,a1
		moveq	#89-1,d0
.index2
		move.l	-(a0),d1
		moveq	#16-1,d2
.delta
		move.l	d1,d3
		moveq	#0,d4
		btst	#2,d2
		beq.s	.nBit2
		add.l	d3,d4
.nBit2
		asr.l	#1,d3
		btst	#1,d2
		beq.s	.nBit1
		add.l	d3,d4
.nBit1
		asr.l	#1,d3
		btst	#0,d2
		beq.s	.nBit0
		add.l	d3,d4
.nBit0
		asr.l	#1,d3
		add.l	d3,d4
		btst	#3,d2
		beq.s	.nBit3
		neg.l	d4
.nBit3
		move.l	d4,-(a1)
		
		dbf	d2,.delta
		dbf	d0,.index2
		rts

;-------------------------------------------------------------------------
; Call this routine to decode an ADPCM-compressed stream.
; The input should be d0/2 bytes large.
; The output will be d0*2 bytes large.
;
; d0.l numsamples
; a0 input
; a1 output

adpcmDecode
		move.l	d0,d7
		lsr.l	#1,d7
		subq.l	#1,d7

		lea	adpcmIndexTable,a3
		lea	adpcmStepTable,a2

		moveq	#0,d0
		moveq	#0,d2
		moveq	#0,d6
		move.w	#88<<6,d5
		move.l	#-32768,a4
		move.l	#32767,a5
		swap	d7
.samplePair2	swap	d7
.samplePair
		move.b	(a0)+,d0		; 8
		move.w	d0,d1			; 4
		and.b	#$f,d1			; 8
		lsr.b	#4,d0			; 16
						; = 36

.firstSample
		add.b	d0,d0			; 4
		add.b	d0,d0			; 4
		move.w	d2,d3			; 4
		add.w	d0,d3			; 4

		add.w	2(a3,d0.w),d2		; 16
		spl	d4			; 4
		ext.w	d4			; 4
		and.w	d4,d2			; 4
		cmp.w	d5,d2			; 4		; d5 == 88<<6
		bls.s	.indexClamp0Done	; 8 or 12	; clamp index against 88<<6
		move.w	d5,d2
.indexClamp0Done

		add.l	(a2,d3.w),d6		; 16
		cmp.l	a4,d6			; 8
		bge.s	.clampMin0Done		; 8 or 12
		move.l	a4,d6
.clampMin0Done
		cmp.l	a5,d6			; 8
		ble.s	.clampMax0Done		; 8 or 12
		move.l	a5,d6
.clampMax0Done
		move.w	d6,(a1)+		; 8

.secondSample
		add.b	d1,d1			; 4
		add.b	d1,d1			; 4
		move.w	d2,d3			; 4
		add.w	d1,d3			; 4

		add.w	2(a3,d1.w),d2		; 16
		spl	d4			; 4
		ext.w	d4			; 4
		and.w	d4,d2			; 4
		cmp.w	d5,d2			; 4		; d5 == 88<<6
		bls.s	.indexClamp1Done	; 8 or 12	; clamp index against 88<<6
		move.w	d5,d2
.indexClamp1Done

		add.l	(a2,d3.w),d6		; 16
		cmp.l	a4,d6			; 8
		bge.s	.clampMin1Done		; 8 or 12
		move.l	a4,d6
.clampMin1Done
		cmp.l	a5,d6			; 8
		ble.s	.clampMax1Done		; 8 or 12
		move.l	a5,d6
.clampMax1Done
		move.w	d6,(a1)+		; 8

						; = 224 approx

		dbf	d7,.samplePair		; 12
		swap	d7
		dbf	d7,.samplePair2


		rts

		section	data

adpcmIndexTable
	dc.l	-1, -1, -1, -1, 2, 4, 6, 8
	dc.l	-1, -1, -1, -1, 2, 4, 6, 8

adpcmStepTable
	dc.l	7, 8, 9, 10, 11, 12, 13, 14, 16, 17
	dc.l	19, 21, 23, 25, 28, 31, 34, 37, 41, 45
	dc.l	50, 55, 60, 66, 73, 80, 88, 97, 107, 118
	dc.l	130, 143, 157, 173, 190, 209, 230, 253, 279, 307
	dc.l	337, 371, 408, 449, 494, 544, 598, 658, 724, 796
	dc.l	876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066
	dc.l	2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358
	dc.l	5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899
	dc.l	15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767
	ds.l	89*15
	