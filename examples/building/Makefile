CFLAGS = -Wall -Wextra

all: prog

debug: override CFLAGS += -g
debug: prog

file1.o: file1.c
	gcc $(CFLAGS) -c file1.c

file2.o: file2.c
	gcc $(CFLAGS) -c file2.c

file3.o: file3.c
	gcc $(CFLAGS) -c file3.c

prog: file1.o file2.o file3.o
	gcc $(CFLAGS) -o prog file1.o file2.o file3.o

clean:
	rm -f prog *.o
