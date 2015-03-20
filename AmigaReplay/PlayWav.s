

; Test program, that plays a WAV sample in 14bit mono


BPLX	EQU	320
BPLY	EQU	256
BPLNR	EQU	8
BPLSIZE	EQU	(BPLX*BPLY/8)

ReplayPeriod = 161		; 161 means 22030Hz

	include	hardware/custom.i
	include	hardware/dmabits.i
	include	hardware/intbits.i

	section	code,code

start:

	bsr	takesys

	move.l	#screenmem+7,d0
	andi.b	#$f8,d0
	move.l	d0,screenptrs
	add.l	#BPLSIZE*BPLNR,d0
	move.l	d0,screenptrs+4
	bsr.s	swapscreens


	lea	WAVFile,a0
	move.w	#ReplayPeriod,d0
	bsr	WavSource_Init_16BitMonoInput_14BitMonoOutput

	move.l	#copperlist,cop1lc+$dff000

	move.l	vectorbase,a0
	move.l	$6c(a0),oldlev3
	move.l	#lev3,$6c(a0)

	move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,intena+$dff000

	bsr	PaulaOutput_Start

	bsr	wvbi

	move.w	#0,copjmp1+$dff000

	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_RASTER|DMAF_BLITTER|DMAF_COPPER,dmacon+$dff000


.loop

	bsr	wvbi
	bsr.s	swapscreens

	btst	#6,$bfe001
	bne.s	.loop

	move.l	vectorbase,a0
	move.l	oldlev3,$6c(a0)

	bsr	PaulaOutput_ShutDown

	bsr	restoresys
	rts

swapscreens
	move.l	screenptrs,d0
	move.l	screenptrs+4,d1
	move.l	d0,screenptrs+4
	move.l	d1,screenptrs

	moveq	#BPLNR-1,d1
	lea	copperbpls,a0
.bpl	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.l	#BPLSIZE,d0
	addq.l	#8,a0
	dbf	d1,.bpl
	rts

lev3
	movem.l	d0-d1,-(sp)
	move.w	intreqr+$dff000,d0
	move.w	intenar+$dff000,d1
	and.w	d0,d1
	btst	#INTB_VERTB,d1
	bne.s	.handle_vertb

.lev3_end
	andi.w	#INTF_VERTB|INTF_COPER|INTF_BLIT,d0
	move.w	d0,intreq+$dff000
	movem.l	(sp)+,d0-d1
	rte

.handle_vertb
	movem.l	d0-d7/a0-a6,-(sp)
	addq.l	#1,vbicounter

	bsr	PaulaOutput_VertBCallback

	movem.l	(sp)+,d0-d7/a0-a6
	bra.s	.lev3_end

wvbi	move.l	vbicounter,d0
.loop	cmp.l	vbicounter,d0
	beq.s	.loop
	rts

	include	flowerstartup_devpac.s
	include	WAVSource.s
	include	PaulaOutput.s

	section	data,data


vbicounter dc.l	0

WAVFile
;	incbin	../data/starstruck_22030_mono.wav
	incbin	../data/test.original.wav

	section	data_c,data_c

copperlist
	dc.w	$1001,$fffe
	dc.w	bplcon0,$0211
	dc.w	bplcon1,$0000
	dc.w	bplcon2,$02c0
	dc.w	bplcon3,$0020
	dc.w	bpl1mod,-8
	dc.w	bpl2mod,-8
	dc.w	diwstrt,$2c81
	dc.w	diwstop,$2cc1
	dc.w	ddfstrt,$38
	dc.w	ddfstop,$d0
	dc.w	fmode,$000f
copperbpls
CNTR	SET	0
	REPT	BPLNR*2
	dc.w	bplpt+CNTR,0
CNTR	SET	CNTR+2
	ENDR
copperpal
	ds.l	256*2+(256/32)*2
	dc.l	-2,-2

	section	bss,bss

screenptrs
	ds.l	2

oldlev3	ds.l	1

	section	bss_c,bss_c

screenmem
	ds.b	BPLSIZE*BPLNR*2+8
