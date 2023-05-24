CC = g++

CFLAGS  = -Wall -g -std=c++11
LDFLAGS = -lm

# the name of the executable
EXE = noc_placer

# the object files generated from cpp files
OBJ = noc_placer.o node.o module.o stopping_buffer.o

# the source files
SRC = noc_placer.cpp node.cpp module.cpp stopping_buffer.cpp

#the header files
H = node.h module.h stopping_buffer.h


$(EXE): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(EXE) $(LDFLAGS)

noc_placer.o: noc_placer.cpp $(H)
	$(CC) -c $(CFLAGS) noc_placer.cpp  $(LDFLAGS)

node.o: node.cpp $(H)
	$(CC) -c  $(CFLAGS) node.cpp $(LDFLAGS)

module.o: module.cpp $(H)
	$(CC) -c  $(CFLAGS) module.cpp $(LDFLAGS)

stopping_buffer.o: stopping_buffer.cpp $(H)
	$(CC) -c  $(CFLAGS) stopping_buffer.cpp $(LDFLAGS)

clean:
	rm -f noc_placer *.o
