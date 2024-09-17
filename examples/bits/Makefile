PROGS = $(patsubst %.c,%,$(wildcard *.c))

all : $(PROGS)

% : %.c
	gcc -g -o $@ $^

clean:
	rm -rf $(PROGS)
