; Align to 256-byte page boundary
	DEFS	(($ + 0xFF) / 0x100) * 0x100 - $
