COMS = hello.com \
	strbios.com \
	textgraf.com \
	vgagraf.com \
	vgagraf2.com \
	mousepal.com

all: $(COMS)

$(COMS):%.com:%.asm
	nasm -fbin -o $@ $^

clean:
	rm -f $(COMS)
