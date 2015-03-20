
ADPCM replay routines for 68020+ Amigas
by Mikael Kalms (mikael@kalms.org)

These routines replay IMA ADPCM compressed samples. ADPCM is a good choice for
68020-68060 equipped machines as it has a decent compression ratio, OK sound quality,
and takes just a few % of CPU time to decode.


The sample needs to be converted to the correct frequency before you begin replaying.
In a PAL Amiga, the following relationship holds:
	frequency = 3546895 / period
... and "period" can only be specified in integer steps.

For instance,
frequency 20038.95 Hz <-> period 177
frequency 22030.40 Hz <-> period 161
frequency 28603.99 Hz <-> period 124	(max supported by hardware in PAL resolution)

The screenmode used while replaying must be either PAL-interlace or PAL-nointerlace.
Otherwise mixing and replay will overrun each other.


Usage in four steps:

1) Initialize both the ADPCM mixer and the audio driver

	lea	AdpcmFile,a0
	move.w	#ReplayPeriod,d0
	bsr	AdpcmSource_Init_16BitMonoInput_14BitMonoOutput

2) Call the mixing callback from your VertB interrupt

	bsr	PaulaOutput_VertBCallback
  
3) Once you have activated your VertB interrupt, enable mixing

	bsr	PaulaOutput_Start

4) When it's time to stop playing the sample, stop mixing and silence audio

	bsr	PaulaOutput_ShutDown


