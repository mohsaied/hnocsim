CC = g++

CFLAGS  = -Wall -g
LDFLAGS = -lm

CFLAGS  += `pkg-config gtk+-2.0 --cflags`
LDFLAGS += `pkg-config gtk+-2.0 --libs`

# the name of the executable
EXE = draw

# the object files generated from cpp files
OBJ = draw.o bgl_graphics.o channel.o router.o

# the source files
SRC = draw.cpp bgl_graphics.cpp channel.cpp router.cpp

#the header files
H = bgl_graphics.h channel.h router.h

$(EXE): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(EXE) $(LDFLAGS)

draw.o: draw.cpp $(H)
	$(CC) -c $(CFLAGS) draw.cpp  $(LDFLAGS)

bgl_graphics.o: bgl_graphics.cpp $(H)
	$(CC) -c  $(CFLAGS) bgl_graphics.cpp $(LDFLAGS)

channel.o: channel.cpp $(H)
	$(CC) -c  $(CFLAGS) channel.cpp $(LDFLAGS)

router.o: router.cpp $(H)
	$(CC) -c  $(CFLAGS) router.cpp $(LDFLAGS)

clean:
	rm -f draw *.o
