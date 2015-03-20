
#ifndef Endian_h
#define Endian_h

#include "Types.h"

inline u16 endianSwap16L(u16 x)
{
	return x;
}

inline u16 endianSwap16B(u16 x)
{
	return ((x >> 8) & 0x00ff) | ((x << 8) & 0xff00);
}

inline u32 endianSwap32L(u32 x)
{
	return x;
}

inline u32 endianSwap32B(u32 x)
{
	return (endianSwap16B(x & 0x000ffff) << 16) | (endianSwap16B(x >> 16));
}

inline u8 endianReadU8Little(const u8* pos)
{
	return *pos;
}

inline u8 endianReadU8Big(const u8* pos)
{
	return *pos;
}

inline u16 endianReadU16Little(const u16* pos)
{
	return endianSwap16L(*pos);
}

inline u16 endianReadU16Big(const u16* pos)
{
	return endianSwap16B(*pos);
}

inline u32 endianReadU32Little(const u32* pos)
{
	return endianSwap32L(*pos);
}

inline u32 endianReadU32Big(const u32* pos)
{
	return endianSwap32B(*pos);
}

inline void endianWriteU8Little(u8* pos, u8 value)
{
	*pos = value;
}

inline void endianWriteU8Big(u8* pos, u8 value)
{
	*pos = value;
}

inline void endianWriteU16Little(u16* pos, u16 value)
{
	*pos = endianSwap16L(value);
}

inline void endianWriteU16Big(u16* pos, u16 value)
{
	*pos = endianSwap16B(value);
}

inline void endianWriteU32Little(u32* pos, u32 value)
{
	*pos = endianSwap32L(value);
}

inline void endianWriteU32Big(u32* pos, u32 value)
{
	*pos = endianSwap32B(value);
}



#endif
