# Makefile template for shared library

CC = arm-linux-gnueabi-gcc # C compiler
CFLAGS = -c -fPIC # C flags
LDFLAGS = -shared  # linking flags
RM = rm -f  # rm command
TARGET_LIB = ./lib/libfnvme.so # target lib

SRCS = ./src/libfnvme.c # source files
OBJS = ./libfnvme.o
EXAMPLES_DIR = ./examples
BIN = ./bin

all: lib examples

.PHONY: lib
lib:
	$(CC) $(CFLAGS) -I./include $(SRCS)
	$(CC) $(LDFLAGS) -o $(TARGET_LIB) $(OBJS)
	rm $(OBJS)
	export LD_LIBRARY_PATH=./lib:$\LD_LIBRARY_PATH

#List of examples
.PHONY: examples
examples: test_lib test_str

#Rules for each addon
.PHONY: test_lib
test_nvme:
	$(CC) -I./include -L./lib $(EXAMPLES_DIR)/test_lib.c -lfnvme -o $(BIN)/test_lib

.PHONY: test_str
test_str:
	$(CC) -I./include -L./lib $(EXAMPLES_DIR)/test_str.c -lfnvme -o $(BIN)/test_str

#Clean
.PHONY: clean
clean:
	-${RM} ${TARGET_LIB} ${OBJS} $(SRCS:.c=.d) $(BIN)/*
