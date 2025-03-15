PROJECT := mygame
SRC := src/main.asm
OBJ := build/main.o
ROM := build/$(PROJECT).gb

all: $(ROM)

$(ROM): $(OBJ)
	rgblink -o $(ROM) $(OBJ)
	rgbfix -v -p 0 $(ROM)
	mgba $(ROM)

build/main.o: $(SRC)
	mkdir -p build
	rgbasm -o $(OBJ) $(SRC)

clean:
	rm -rf build

