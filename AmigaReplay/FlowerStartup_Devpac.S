*****************************************
* $VER:flowerstartup.s v2.0             *
* coded by nemo/factor                  *
*               ---                     *
* a system friendly os-shut-down and    *
* os-open-up routine...                 *
*                                       *
* flowerstartup now supports icons!     *
* set the "iconstartup" to enable this  *
* feature! note that asm-one can not    *
* handle this feature when running your *
* code from asm-one, so enable this     *
* at the final assembling of your code. *
*                                       *
* have fun!                             *
*                                       *
* nEMo/FaCTor                           *
*****************************************

	section	code,code

;----------------------------------------
iconstartup	equ	1	;1 before the final assembling!
;----------------------------------------
takesys:
        movea.l 4.w,a6
	move.l	a6,execbase
	ifne	iconstartup
	suba.l	a1,a1
	jsr	-294(a6)		;FindTask()
	move.l	d0,a4			;spara task-address

	tst.l	$ac(a4)			;från shell/cli??!!
	bne.s	.cli

	lea.l	$5c(a4),a0		;hämta meddelande-port
	jsr	-384(a6)		;WaitPort()
	lea.l	$5c(a4),a0
	jsr	-372(a6)		;GetMsg()
	move.l	d0,msg
	endc

.cli	jsr     -132(a6)                ;Forbid()

	lea.l   gfxname,a1
	moveq.l #39,d0
        jsr     -552(a6)                ;OpenLibrary()
	move.l  d0,gfxbase
	beq.s	.liberr

	lea.l   dosname,a1
	moveq.l #39,d0
        jsr     -552(a6)                ;OpenLibrary()
	move.l  d0,dosbase
	bne.s	.libok
.liberr
	move.l	#nolib,errormessptr
        bra.w   display_error

.libok	move.l  gfxbase,a6
	move.l  $22(a6),wb_view
	move.l  $26(a6),wb_copper

	jsr     -228(a6)                ;WaitBlit()
	jsr     -456(a6)                ;OwnBlitter()

	suba.l  a1,a1
        jsr     -222(a6)                ;LoadView() (Nolla!)
        jsr     -270(a6)                ;WaitTof()
        jsr     -270(a6)                ;WaitTof()

        movea.l execbase,a6
        moveq.l #0,d0
        btst    #0,297(a6)              ;68010+??!
        beq.w   .68000

        lea.l   vbr_exception,a5        ;peka på exception-rutinen...
        jsr     -30(a6)                 ;supervisor state

.68000  move.l  d0,vectorbase           ;spara vectorbasen...

        lea.l   $dff000,a6
        move.w  $002(a6),d0             ;intenar till d0
        or.w    #$8000,d0               ;sätt top-bit
        move.w  d0,old_dmacon

        move.w  $010(a6),d0             ;adkconr till d0
        or.w    #$8000,d0               ;sätt top-bit
        move.w  d0,old_adkcon

        move.w  $01c(a6),d0
        or.w    #$c000,d0               ;sätt de två översta bitarna!
        move.w  d0,old_intena

.1	btst    #0,$005(a6)
        beq.s   .1
.2	btst    #0,$005(a6)
        bne.s   .2

        move.l  #$7fff7fff,d0
        move.l  d0,$09a(a6)             ;stäng av intena/intreq
        move.w  d0,$09e(a6)             ;stäng av adkcon
        move.w  d0,$096(a6)             ;stäng av dmacon
        move.w  #0,$180(a6)             ;nolla bakgrundsfärgen...
        bset    #1,$bfe001              ;slå av ljudfiltret!
        moveq.l #0,d0			;inga felflaggor!
        rts
;----------------------------------------
restoresys:
        lea.l   $dff000,a6

        btst    #7,$002(a6)
.tst    btst    #7,$002(a6)
        bne.s   .tst

        move.w  old_dmacon,$096(a6)
        move.w  old_intena,$09a(a6)
        move.w  old_adkcon,$09e(a6)

        move.l  wb_copper,$dff080       ;sätt gammal system-copperlista!
        move.w  d0,$088(a6)

        movea.l gfxbase,a6
        move.l  wb_view,a1
        jsr     -222(a6)                ;LoadView()
        jsr     -270(a6)                ;WaitTof()
        jsr     -270(a6)                ;WaitTof()

        jsr     -462(a6)                ;DisOwnBlit()

        movea.l a6,a1
        movea.l execbase,a6
        jsr     -414(a6)                ;CloseLibrary()
	move.l	dosbase,a1
        jsr     -414(a6)                ;CloseLibrary()

        jsr     -138(a6)		;Permit()

	ifne	iconstartup
	tst.l	msg			;fick jag ett message?
	beq.s	.exit
	jsr	-132(a6)		;Forbid()
	move.l	msg,a1
	jsr	-378(a6)		;ReplyMsg()
	endc
.exit	moveq.l	#0,d0
	rts
;----------------------------------------
vbr_exception:
;	movec   vbr,d0
	dc.l    $4e7a0801	;'movec vbr,d0' i ren maskinkod...
        rte
;----------------------------------------
display_error:
	move.l	execbase,a6
	lea.l	intname,a1
	moveq.l	#0,d0
	jsr	-552(a6)
	move.l	d0,a6
	beq.s	.fuckup			;arghH!! total fuckup!

	moveq.l	#0,d0
	moveq	#20,d1
	move.l	errormessptr,a0
	jsr	-90(a6)			;DisplayAlert()

	move.l	execbase,a6
	move.l	gfxbase,d0
	beq.s	.nlib1
	move.l	d0,a1
	jsr	-414(a6)		;CloseLibrary()
.nlib1
	move.l	dosbase,d0
	beq.s	.nlib2
	move.l	d0,a1
	jsr	-414(a6)		;CloseLibrary()
.nlib2

.fuckup	moveq.l #1,d0                   ;sätt en felflagga!
        rts
;----------------------------------------
intname:	dc.b	'intuition.library',0
gfxname:        dc.b    'graphics.library',0
dosname:        dc.b    'dos.library',0
		even
execbase:	dc.l	0
gfxbase:        dc.l    0
dosbase:        dc.l    0
old_dmacon:     dc.w    0
old_adkcon:     dc.w    0
old_intena:     dc.w    0
vectorbase:     dc.l    0	;«=- mkt viktig vid interrupts!!
wb_view:        dc.l    0
wb_copper:      dc.l    0
errormessptr:	dc.l	0
		ifne	iconstartup
msg:		dc.l	0
		endc

nolib:		dc.w	10
		dc.b	12
		dc.b	'Could not open required library -- '
		dc.b	'press mousebutton to quit',0
		even
;----------------------------------------
