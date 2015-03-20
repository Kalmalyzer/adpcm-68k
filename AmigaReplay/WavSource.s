
; This file includes routines for decoding a 16-bit mono RIFF WAV stream to either
;  8-bit or 16-bit mono output. Decoding is done through a callback function that
;  should be called each vblank.
;
; The current version is very crude. It doesn't even parse the WAV header properly!
;  Use it only for testing purposes.

	section	code,code

;------------------------------------------------------------------------------
; in	a0	WAV 16bit mono file
;		d0.w	replay period
; out	a0/a1 stuff to send to PaulaOutput

WavSource_Init_16BitMonoInput_8BitMonoOutput
	add.l	#512,a0	; Skip header (yes, it is variable sized so this is horribly broken code)

	lea	WavSource_16BitMonoInput_8BitMonoOutput_MixState,a1
	move.l	a0,(a1)
	lea	WavSource_16BitMonoInput_8BitMonoOutput_MixSamples,a0
	moveq	#PaulaOutput_Mode_8BitMono,d1
	bsr		PaulaOutput_Init
	rts

;------------------------------------------------------------------------------
; in	a0	WAV 16bit mono file
;		d0.w	replay period
; out	a0/a1 stuff to send to PaulaOutput

WavSource_Init_16BitMonoInput_14BitMonoOutput
	lea	WavSource_16BitMonoInput_14BitMonoOutput_MixState,a1
	move.l	a0,(a1)
	lea	WavSource_16BitMonoInput_14BitMonoOutput_MixSamples,a0
	moveq	#PaulaOutput_Mode_14BitMono,d1
	bsr		PaulaOutput_Init
	rts

;------------------------------------------------------------------------------
; in	d0	number of samples to mix
;	d1	current mix position
;	a0	output samples
;	a4	state

WavSource_16BitMonoInput_8BitMonoOutput_MixSamples
	move.l	a2,-(sp)
	move.l	(a4),a2
.sample
	move.b	1(a2),(a0)+
	addq.l	#2,a2
	subq.l	#1,d0
	bne.s	.sample
	move.l	a2,(a4)
	move.l	(sp)+,a2
	rts

;------------------------------------------------------------------------------
; in	d0	number of samples to mix
;	d1	current mix position
;	a0	output samples
;	a4	state

WavSource_16BitMonoInput_14BitMonoOutput_MixSamples
	move.l	a2,-(sp)
	move.l	(a4),a2
.sample
	move.b	(a2)+,d1
	lsr.b	#2,d1
	move.b	d1,(a1)+
	move.b	(a2)+,(a0)+
	subq.l	#1,d0
	bne.s	.sample
	move.l	a2,(a4)
	move.l	(sp)+,a2
	rts

	section	bss,bss

WavSource_16BitMonoInput_8BitMonoOutput_MixState
	ds.l	1

WavSource_16BitMonoInput_14BitMonoOutput_MixState
	ds.l	1
