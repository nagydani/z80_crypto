zxeth.tap:	ethtools.tap loader.tap signer.tap
	cat	loader.tap ethtools.tap signer.tap > zxeth.tap

ethtools.tap:	ethtools.bin
	bin2tap -o ethtools.tap -a 43264 ethtools.bin

ethtools.bin:	ethtools.asm hex.asm tobinary.asm
	z80asm -o ethtools.bin ethtools.asm

clean:
	rm -v ethtools.bin ethtools.tap zxeth.tap
