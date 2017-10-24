
		xref	ADPCMDecoder_InitTables

		xref	ADPCMDecoder_16Bit
		xref	ADPCMDecoder_16Bit_Init
		xref	ADPCMDecoder_16Bit_Decode

		xref	ADPCMDecoder_8Bit
		xref	ADPCMDecoder_8Bit_Init
		xref	ADPCMDecoder_8Bit_Decode

			rsreset
ADPCMDecoderState_ReadPtr	rs.l	1
ADPCMDecoderState_WritePtr	rs.l	1
ADPCMDecoderState_Index		rs.w	1
ADPCMDecoderState_ValPred	rs.w	1
ADPCMDecoderState_SIZEOF	rs.b	0

