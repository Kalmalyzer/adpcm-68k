# IMA ADPCM codec for PC, decoder for Amiga & Atari

This archive contains three things:

* a WAV<->ADPCM codec written in C, both source and executable included
* an ADPCM decoder optimized for 68000
* an ADPCM replayer for Amiga, including a Paula audio driver

The C codec is reference code from Stichting Mathematisch Centrum (see source code for copyright).
The 680x0 specific code has been written by Mikael Kalms (mikael@kalms.org).

#Performance

The 68k decoder decodes approximately 50k samples/second on an 8MHz Atari ST.

The Amiga replay routine will decompress samples during each VBlank, taking typically <5 scanlines on a 68060@50MHz.

##Changelog

v1.0: implemented replay of mono samples

v2.0: implemented replay of stereo samples

v2.1: changed mixahead calculation such that it supports both PAL-nointerlace and PAL-interlace screenmodes
      removed all FPU usage

v2.2: bugfix when reinitializing AdpcmSource

v2.3: Implemented chunk-based decoding for 68k version, plus 8bit output

v2.4: Fixed ridiculous bug in 14bit-output of realtime ADPCM replayer for Amiga. Sometimes, the lower 6 bits would be incorrect!
14bit output sound quality is where it should be now.
