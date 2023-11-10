COMS = hello.com \
	strbios.com \
	keyboard.com \
	screen/textgraf.com \
	screen/vgagraf.com \
	screen/vgagraf2.com \
	screen/mousepal.com \
	sound/beep.com \
	sound/drbob.com \
	sound/jbond2.com

all: $(COMS)

$(COMS):%.com:%.asm
	nasm -fbin -o $@ $^

clean:
	rm -f $(COMS)
