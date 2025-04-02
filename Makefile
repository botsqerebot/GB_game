# Makefile for GB_game project
#PROJECTNAME = YFFPRO
#SRCDIR = src

ASMDIR := src
BUILDDIR := build
OUTPUT := $(BUILDDIR)/game.gb 
OBJ := $(BUILDDIR)/main.o

# Source files
SOURCES = $(ASMDIR)/main.asm \
           $(ASMDIR)/include/hardware.inc \
           $(ASMDIR)/utils/memcopy.asm \
           $(ASMDIR)/utils/input.asm \
#		   $(ASMDIR)/assets/tiles.asm


# Build rules
all: $(OUTPUT)

$(OUTPUT): $(SOURCES) $(OBJ)
	mkdir -p $(BUILDDIR)
	rgblink -o $(OUTPUT) $(OBJ)
	rgbfix -v $(OUTPUT)

$(BUILDDIR)/main.o: $(ASMDIR)/main.asm
	rgbasm -o $(BUILDDIR)/main.o $(ASMDIR)/main.asm
clean:
	rm -f $(OUTPUT)

.PHONY: all clean