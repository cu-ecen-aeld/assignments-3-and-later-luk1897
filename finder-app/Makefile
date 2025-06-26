CROSS_COMPILE?=
CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -g
TARGET = writer
SRC = writer.c

RM=rm
RFLAGS= -f

all: 
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

clean: 
	$(RM) $(RFLAGS) *.o $(TARGET)