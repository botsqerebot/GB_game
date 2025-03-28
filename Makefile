# Makefile for GB_game project

ASMDIR := src
BUILDDIR := build
OUTPUT := $(BUILDDIR)/game.gb 
OBJ := $(BUILDDIR)/main.o

# Source files
SOURCES = $(ASMDIR)/main.asm \
           $(ASMDIR)/include/hardware.inc \
           $(ASMDIR)/utils/memcopy.asm \
           $(ASMDIR)/utils/input.asm \


# Build rules
all: $(OUTPUT)

$(OUTPUT): $(SOURCES) $(OBJ)
	mkdir -p $(BUILDDIR)
	rgblink -o $(OUTPUT) $(OBJ)
	rgbfix -v $(OUTPUT)

$(BUILDDIR)/main.o: $(ASMDIR)/main.asm
	mkdir -p $/BUILDDIR
	rgbasm -o $(BUILDDIR)/main.o $(ASMDIR)/main.asm
clean:
	rm -f $(OUTPUT)

.PHONY: all clean