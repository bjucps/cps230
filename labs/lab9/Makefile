boot.img: boot.asm payload.bin
	nasm -fbin -l boot.lst -o boot.img boot.asm

%.bin: %.asm
	nasm -fbin -l $(patsubst %.bin,%.lst,$@) -o $@ $^

clean:
	rm -f boot.img payload.bin *.lst
