
; IMA ADPCM decode routine optimized for 68000
; It takes in a mono datastream encoded to 4-bit entries, and outputs a stream of signed 8-bit or 16-bit samples.
; The data stream can either be decoded all at once, or chunk by chunk. Changing buffer pointers between
;   chunks allows decoding to/from a ringbuffer.
;
; Performance:
; - decodes roughly 50kSamples/second on an 8MHz Atari ST to signed 16bit output format
; - decodes roughly 45kSamples/second on a 7.14MHz A500 to signed 16bit output format
; - decodes roughly 43kSamples/second on a 7.14MHz A500 to signed 8bit output format
;
; Written by: Mikael Kalms, 2009-09-26 / 2017-10-24

		include	ADPCMDecoder68000.i

;-------------------------------------------------------------------------

		section	code,code

;-------------------------------------------------------------------------
; Call this routine once to initialize the tables.
; It must be called before any other ADPCM decoder functions are called.
		
		XDEF	ADPCMDecoder_InitTables
ADPCMDecoder_InitTables
		tst.b	ADPCMInitialized
		bne.s	.initialized
		st	ADPCMInitialized

		movem.l	d2-d4,-(sp)
		
		lea	ADPCMIndexTable,a0
		moveq	#16-1,d0
.index
		move.l	(a0),d1
		lsl.l	#6,d1
		move.l	d1,(a0)+
		dbf	d0,.index
		
		lea	ADPCMStepTable+89*4,a0
		lea	ADPCMStepTable+89*16*4,a1
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

		movem.l	(sp)+,d2-d4
		
.initialized
		rts

;-------------------------------------------------------------------------
; Call these routines to decode an ADPCM-compressed stream.
; It will output a stream of signed 16-bit samples.

;-------------------------------------------------------------------------
; This is a convenience function that can be used to decode an entire
; ADPCM-compressed stream at once.
;
; The input should be d0/2 bytes large.
; The output will be d0*2 bytes large.
;
; in:
; d0.l		num samples (must be even)
; a0		input
; a1		output

		XDEF	ADPCMDecoder_16Bit
ADPCMDecoder_16Bit
		move.l	a2,-(sp)
		sub.w	#ADPCMDecoderState_SIZEOF,sp
		move.l	sp,a2

		move.l	d0,-(sp)
		bsr.s	ADPCMDecoder_16Bit_Init
		move.l	(sp)+,d0

		move.l	a2,a0
		bsr.s	ADPCMDecoder_16Bit_Decode

		add.w	#ADPCMDecoderState_SIZEOF,sp
		move.l	(sp)+,a2
		rts


;------------------------------------------------------------------------------------
; This will initialize the decoder. Call it once before decoding a chunk of a stream.
;
; in:
; a0		input
; a1		output
; a2		decoder state

		XDEF	ADPCMDecoder_16Bit_Init
ADPCMDecoder_16Bit_Init
		move.l	a0,ADPCMDecoderState_ReadPtr(a2)
		move.l	a1,ADPCMDecoderState_WritePtr(a2)
		clr.w	ADPCMDecoderState_Index(a2)
		clr.w	ADPCMDecoderState_ValPred(a2)
		rts

;------------------------------------------------------------------------------------
; This will decode a number of samples from the input stream, to the output stream.
;
; If you want to decode to/from a cyclic buffer, you can change the read/write
;   ptrs within the ADPCMDecoderState structure between calls to ADPCMDecoder_16Bit_Decode.
;
; The input should be d0/2 bytes large.
; The output will be d0*2 bytes large.
;
; in:
; d0.l		num samples (must be even)
; a0		Decoder state

		XDEF	ADPCMDecoder_Decode
ADPCMDecoder_16Bit_Decode
		movem.l	d2-d7/a2-a6,-(sp)

		move.l	d0,d7
		lsr.l	#1,d7
		subq.l	#1,d7

		move.l	ADPCMDecoderState_WritePtr(a0),a1
		move.l	ADPCMDecoderState_ReadPtr(a0),a6
		moveq	#0,d2
		move.w	ADPCMDecoderState_Index(a0),d2
		move.w	ADPCMDecoderState_ValPred(a0),d6
		ext.l	d6
		
		lea	ADPCMIndexTable,a3
		lea	ADPCMStepTable,a2

		moveq	#0,d0
		move.w	#88<<6,d5
		move.l	#-32768,a4
		move.l	#32767,a5
		swap	d7
.samplePair2	swap	d7
.samplePair
		move.b	(a6)+,d0		; 8
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

		move.l	a1,ADPCMDecoderState_WritePtr(a0)
		move.l	a6,ADPCMDecoderState_ReadPtr(a0)
		move.w	d2,ADPCMDecoderState_Index(a0)
		move.w	d6,ADPCMDecoderState_ValPred(a0)

		movem.l	(sp)+,d2-d7/a2-a6
		
		rts


;-------------------------------------------------------------------------
; Call these routines to decode an ADPCM-compressed stream.
; It will output a stream of signed 8-bit samples.

;-------------------------------------------------------------------------
; This is a convenience function that can be used to decode an entire
; ADPCM-compressed stream at once.
;
; The input should be d0/2 bytes large.
; The output will be d0 bytes large.
;
; in:
; d0.l		num samples (must be even)
; a0		input
; a1		output

		XDEF	ADPCMDecoder_8Bit
ADPCMDecoder_8Bit
		move.l	a2,-(sp)
		sub.w	#ADPCMDecoderState_SIZEOF,sp
		move.l	sp,a2

		move.l	d0,-(sp)
		bsr.s	ADPCMDecoder_8Bit_Init
		move.l	(sp)+,d0

		move.l	a2,a0
		bsr.s	ADPCMDecoder_8Bit_Decode

		add.w	#ADPCMDecoderState_SIZEOF,sp
		move.l	(sp)+,a2
		rts


;------------------------------------------------------------------------------------
; This will initialize the decoder. Call it once before decoding a chunk of a stream.
;
; in:
; a0		input
; a1		output
; a2		decoder state

		XDEF	ADPCMDecoder_8Bit_Init
ADPCMDecoder_8Bit_Init
		move.l	a0,ADPCMDecoderState_ReadPtr(a2)
		move.l	a1,ADPCMDecoderState_WritePtr(a2)
		clr.w	ADPCMDecoderState_Index(a2)
		clr.w	ADPCMDecoderState_ValPred(a2)
		rts

;------------------------------------------------------------------------------------
; This will decode a number of samples from the input stream, to the output stream.
;
; If you want to decode to/from a cyclic buffer, you can change the read/write
;   ptrs within the ADPCMDecoderState structure between calls to ADPCMDecoder_8Bit_Decode.
;
; The input should be d0/2 bytes large.
; The output will be d0 bytes large.
;
; in:
; d0.l		num samples (must be even)
; a0		Decoder state

		XDEF	ADPCMDecoder_Decode
ADPCMDecoder_8Bit_Decode
		movem.l	d2-d7/a2-a6,-(sp)

		move.l	d0,d7
		lsr.l	#1,d7
		subq.l	#1,d7

		move.l	ADPCMDecoderState_WritePtr(a0),a1
		move.l	ADPCMDecoderState_ReadPtr(a0),a6
		moveq	#0,d2
		move.w	ADPCMDecoderState_Index(a0),d2
		move.w	ADPCMDecoderState_ValPred(a0),d6
		ext.l	d6
		
		lea	ADPCMIndexTable,a3
		lea	ADPCMStepTable,a2

		moveq	#0,d0
		move.w	#88<<6,d5
		move.l	#-32768,a4
		move.l	#32767,a5
		swap	d7
.samplePair2	swap	d7
.samplePair

		move.b	(a6)+,d0		; 8
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
		move.w	d6,-(sp)		; 8
		move.b	(sp)+,(a1)+		; 12

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
		move.w	d6,-(sp)		; 8
		move.b	(sp)+,(a1)+		; 12

						; = 248 approx

						
		dbf	d7,.samplePair		; 12
		swap	d7
		dbf	d7,.samplePair2

		
		move.l	a1,ADPCMDecoderState_WritePtr(a0)
		move.l	a6,ADPCMDecoderState_ReadPtr(a0)
		move.w	d2,ADPCMDecoderState_Index(a0)
		move.w	d6,ADPCMDecoderState_ValPred(a0)

		movem.l	(sp)+,d2-d7/a2-a6
		
		rts


;-------------------------------------------------------------------------

		section	data,data

;-------------------------------------------------------------------------

ADPCMInitialized dc.b	0

		even

ADPCMIndexTable
		dc.l	-1, -1, -1, -1, 2, 4, 6, 8
		dc.l	-1, -1, -1, -1, 2, 4, 6, 8

ADPCMStepTable
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
	