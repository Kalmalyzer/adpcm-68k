
// Example program for encoding/decoding .WAV <-> .ADPCM
//

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "codec.h"

#include "Endian.h"

#pragma warning (disable : 4996)

enum
{
	RIFF_ID	= 'RIFF',
	WAVE_ID	= 'WAVE',
	FMT_ID	= 'fmt ',
	DATA_ID	= 'data'
};

typedef struct RIFFHeaderTag
{
	u32	RiffId;
	u32	Size;
	u32	WaveId;
} RIFFHeader;

typedef struct FMTHeaderTag
{
	u32	FmtId;
	u32	ChunkSize;
	u16	Format;
	u16	NumChannels;
	u32	SamplesPerSec;
	u32	AvgBytesPerSec;
	u16	BlockAlign;
	u16	BitsPerSample;
} FMTHeader;

typedef struct DATAHeaderTag
{
	u32	DataId;
	u32	ChunkSize;
} DATAHeader;




bool encode(char* inFileName, char* outFileName)
{
	FILE* f = fopen(inFileName, "rb");
	fseek(f, 0, SEEK_END);
	int inFileSize = ftell(f);
	fseek(f, 0, SEEK_SET);
	u8* inFileBuf = (u8*) malloc(inFileSize);
	fread(inFileBuf, 1, inFileSize, f);
	fclose(f);

	RIFFHeader* riffHeader = (RIFFHeader*) inFileBuf;

	if (endianReadU32Big(&riffHeader->RiffId) != RIFF_ID)
		return false;
	if (endianReadU32Big(&riffHeader->WaveId) != WAVE_ID)
		return false;

	int waveSize = endianReadU32Little(&riffHeader->Size) - 4;

	FMTHeader* fmtHeader = 0;
	DATAHeader* dataHeader = 0;

	u8* data = (u8*) (riffHeader + 1);
	while (waveSize && !(fmtHeader && dataHeader))
	{
		u32 id = endianReadU32Big((u32*) data);
		if (id == FMT_ID)
			fmtHeader = (FMTHeader*) data;
		else if (id == DATA_ID)
			dataHeader = (DATAHeader*) data;

		u32 chunkSize = endianReadU32Little((u32*) (data + 4));
		data += chunkSize + 8;
		waveSize -= chunkSize + 8;
	}

	if (!(fmtHeader && dataHeader))
		return false;

	if (endianReadU16Little(&fmtHeader->BitsPerSample) != 16
		|| endianReadU16Little(&fmtHeader->NumChannels) != 1
		|| endianReadU16Little(&fmtHeader->Format) != 1)
		return false;

	s16* samples = (s16*) (dataHeader + 1);
	u32 numSamples = endianReadU32Little(&dataHeader->ChunkSize) / 2;

	u8* adpcmData = (u8*) malloc(numSamples / 2);

	CodecState state;
	memset(&state, 0, sizeof(state));
	encode(&state, samples, numSamples, adpcmData);

	FILE* outputFile = fopen(outFileName, "wb");
	fwrite(adpcmData, 1, numSamples / 2, outputFile);
	fclose(outputFile);

	return true;
}

bool decode(char* inFileName, char* outFileName)
{
	FILE* f = fopen(inFileName, "rb");
	fseek(f, 0, SEEK_END);
	int inFileSize = ftell(f);
	fseek(f, 0, SEEK_SET);
	u8* inFileBuf = (u8*) malloc(inFileSize);
	fread(inFileBuf, 1, inFileSize, f);
	fclose(f);

	int numSamples = inFileSize * 2;

	int outBufferSize = sizeof(RIFFHeader) + sizeof(FMTHeader) + sizeof(DATAHeader) + numSamples * 2;

	u8* outFileBuf = (u8*) malloc(outBufferSize);

	RIFFHeader* riffHeader = (RIFFHeader*) outFileBuf;

	endianWriteU32Big(&riffHeader->RiffId, RIFF_ID);
	endianWriteU32Little(&riffHeader->Size, outBufferSize - sizeof(RIFFHeader) + 4);
	endianWriteU32Big(&riffHeader->WaveId, WAVE_ID);

	FMTHeader* fmtHeader = (FMTHeader*) (riffHeader + 1);

	endianWriteU32Big(&fmtHeader->FmtId, FMT_ID);
	endianWriteU32Little(&fmtHeader->ChunkSize, sizeof(FMTHeader) - 8);
	endianWriteU16Little(&fmtHeader->Format, 1);
	endianWriteU16Little(&fmtHeader->NumChannels, 1);
	endianWriteU32Little(&fmtHeader->SamplesPerSec, 44100);
	endianWriteU32Little(&fmtHeader->AvgBytesPerSec, 44100 * 2);
	endianWriteU16Little(&fmtHeader->BlockAlign, 2);
	endianWriteU16Little(&fmtHeader->BitsPerSample, 16);

	DATAHeader* dataHeader = (DATAHeader*) (fmtHeader + 1);

	endianWriteU32Big(&dataHeader->DataId, DATA_ID);
	endianWriteU32Little(&dataHeader->ChunkSize, numSamples * 2);
	
	CodecState state;
	memset(&state, 0, sizeof(state));
	decode68000(&state, inFileBuf, numSamples, (s16*) (dataHeader + 1));

	FILE* outputFile = fopen(outFileName, "wb");
	fwrite(outFileBuf, 1, outBufferSize, outputFile);
	fclose(outputFile);

	return true;
}

int main(int argc, char** argv)
{
	if (argc != 4)
	{
		printf("Usage: <encode|decode> <input file> <output file>\n");
		return 0;
	}

	initDecode68000();

	if (!stricmp(argv[1], "encode"))
	{
		bool success = encode(argv[2], argv[3]);
		printf("%s\n", success ? "success" : "fail");
	}
	else if (!stricmp(argv[1], "decode"))
	{
		bool success = decode(argv[2], argv[3]);
		printf("%s\n", success ? "success" : "fail");
	}
	else
	{
		printf("bad args\n");
	}

	return 0;
}