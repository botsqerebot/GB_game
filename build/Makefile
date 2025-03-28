# Makefile for GB_game project

ASMDIR = src
BUILDDIR = build
OUTPUT = $(BUILDDIR)/game.gb 

# Source files
SOURCES = $(ASMDIR)/main.asm \
           $(ASMDIR)/include/hardware.inc \
           $(ASMDIR)/utils/memcopy.asm \
           $(ASMDIR)/utils/input.asm \

# Assembler
ASM = rgbds asm

# Build rules
all: $(OUTPUT)

$(OUTPUT): $(SOURCES) $(BUILDDIR)/linkfile.ld
	$(ASM) $(SOURCES) -o $(OUTPUT)

clean:
	rm -f $(OUTPUT)

.PHONY: all clean