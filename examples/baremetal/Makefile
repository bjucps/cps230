COMS = hello.com \
	strbios.com

all: $(COMS)

$(COMS):%.com:%.asm
	nasm -fbin -o $@ $^

clean:
	rm -f $(COMS)
