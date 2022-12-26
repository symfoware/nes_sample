CL65	= cl65
LD65	= ld65
VERSION = 9

#-------------------------------------------------------------------------------
CSOURCES =

ASMSOURCES =	sample$(VERSION).asm

OBJECTS	=	$(CSOURCES:.c=.o) $(ASMSOURCES:.asm=.o)

LIBRARIES =
#-------------------------------------------------------------------------------
all :	$(OBJECTS) $(LIBRARIES)
	$(LD65) -o sample$(VERSION).nes --config sample$(VERSION).cfg --obj $(OBJECTS)

.SUFFIXES : .asm .o

.c.o :
	$(CL65) -t none -o $*.o -c -O $*.c

.asm.o :
	$(CL65) -t none -o $*.o -c $*.asm

clean :
	rm -fr *.smc
	rm -fr *.o
