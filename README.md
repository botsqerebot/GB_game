# GB_game
 I am trying to follow a tutorial on how to make a gameboy game

## To make the game runnable on windows:

```bash
rgbasm -o build/main.o src/main.asm
rgblink -o build/main.gb build/main.o
rgbfix -v -p 0xFF build/main.gb
```

# If you are on mac you will need mamefile installed and just type make in the terminal
