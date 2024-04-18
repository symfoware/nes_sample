CL65	= cl65
LD65	= ld65

#-------------------------------------------------------------------------------
ASMSOURCES =	map.asm

OBJECTS	=	$(ASMSOURCES:.asm=.o)
# $(ASMSOURCES:.asm=.o) -> 拡張子変換っぽいmap.oに変換される
#-------------------------------------------------------------------------------
all :
	$(CL65) -t none -o $(OBJECTS) -c $(ASMSOURCES)
	$(LD65) -o map.nes --config map.cfg --obj $(OBJECTS)

clean :
	rm *.o
