CROSS_COMPILE?=
CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -g
TARGET = aesdsocket
SRC = aesdsocket.c

RM=rm
RFLAGS= -f

all: 
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

clean: 
	$(RM) $(RFLAGS) *.o $(TARGET)
