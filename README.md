# IMA ADPCM codec for PC, decoder for Amiga & Atari

This archive contains three things:

1) a WAV<->ADPCM codec written in C, both source and executable included
2) an ADPCM decoder optimized for 68000
3) an ADPCM replayer for Amiga, including a Paula audio driver

The C codec is reference code from Stichting Mathematisch Centrum (see source code for copyright).
The 680x0 specific code has been written by Mikael Kalms (mikael@kalms.org).

#Performance

The 68k decoder decodes approximately 50k samples/seconds on an Atari ST.

The Amiga replay routine will decompress samples during each VBlank, taking typically <5 scanlines on a 68060@50MHz.

##Changelog

v1.0: implemented replay of mono samples

v2.0: implemented replay of stereo samples

v2.1: changed mixahead calculation such that it supports both PAL-nointerlace and PAL-interlace screenmodes
      removed all FPU usage
