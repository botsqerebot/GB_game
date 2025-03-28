include "include/hardware.inc"
include "src/utils/memcopy.asm"

DEF BRICK_LEFT EQU $05
DEF BRICK_RIGHT EQU $06
DEF BLANK_TILE EQU $08

section "Counter", WRAM0
wFrameCounter: db

section "Input variables", WRAM0
wCurKeys: db
wNewKeys: db

section "Ball Data", WRAM0
wBallMomentumX: db
wBallMomentumY: db

section "GameState", WRAM0
wGameState:: db

section "Header", ROM0[$100]

    jp EntryPoint

    ds $150 - @, 0 ;Make room for header

EntryPoint:
    ;Dont turn off lcd outside of VBlank
WaitVBlank:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank

    ;turn off lcd
    ld a, 0
    ld [rLCDC], a

    ;copy tile data
    ld de, Tiles
    ld hl, $9000
    ld bc, TilesEnd - Tiles
	call Memcopy

    ;copy tilemap
    ld de, Tilemap
    ld hl, $9800
    ld bc, TilemapEnd - Tilemap
	call Memcopy

	; Copy paddle tile
	ld de, Paddle
	ld hl, $8000
	ld bc, PaddleEnd - Paddle
	call Memcopy

	;copy the ball
	ld de, Ball
	ld hl, $8010
	ld bc, BallEnd - Ball
	call Memcopy

	ld a, 0
	ld b, 160
	ld hl, _OAMRAM
ClearOAM:
	ld [hli], a
	dec b
	jp nz, ClearOAM

	;Initilize the padde sprite in OAM
	ld hl, _OAMRAM
	ld a, 128 + 16
	ld [hli], a
	ld a, 16 + 8
	ld [hli], a
	ld a, 0
	ld [hli], a
	ld [hli], a
	;Initilize the ball sprite
	ld a, 100 + 16
	ld [hli], a
	ld a, 32 + 8
	ld [hli], a
	ld a, 1
	ld [hli], a
	ld a, 0
	ld [hli], a

	;the ball starts to go up and left
	ld a, 1
	ld [wBallMomentumX], a
	ld a, -1
	ld [wBallMomentumY], a

    ; turn the sccreen back on 
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ;during the first (blank) frame, initilize display registers
    ld a, %11100100
    ld [rBGP], a
	ld a, %11100100
	ld [rOBP0], a

	;Initilize global variables
	ld a, 0
	ld [wFrameCounter], a
	ld [wCurKeys], a
	ld [wNewKeys], a

Main:
    ;wait untill its not vblank
	ld a, [rLY]
	cp 144
	jp nc, Main
WaitVBlank2:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank2

	;Add the balls momentum to the oam
	ld a, [wBallMomentumX]
	ld b, a
	ld a, [_OAMRAM + 5]
	add a, b
	ld [_OAMRAM + 5], a

	ld a, [wBallMomentumY]
	ld b, a
	ld a, [_OAMRAM + 4]
	add a, b
	ld [_OAMRAM + 4], a

	;check the current keys pressed every frame and move left or right
	call UpdateKeys

	;first check if the left button is pressed
BounceOnBall:
	; Offset the OAM position
	; (8, 16) is (0, 0) in OAM coordinates on the screen
	ld a, [_OAMRAM + 4]
	sub a, 16 + 1
	ld c, a
	ld a, [_OAMRAM + 5]
	sub a, 8
	ld b, a
	call GetTileByPixel ;returns the address in hl
	ld a, [hl]
	call IsWallTile
	jp nz, BounceOnRight
	call CheckAndHandleBrick
	ld a, 1
	ld [wBallMomentumY], a
BounceOnRight:
	ld a, [_OAMRAM + 4]
	sub a, 16
	ld c, a
	ld a, [_OAMRAM + 5]
	sub a, 8 - 1
	ld b, a
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp nz, BounceOnLeft
	call CheckAndHandleBrick
	ld a, -1
	ld [wBallMomentumX], a
BounceOnLeft:
	ld a, [_OAMRAM + 4]
	sub a, 16
	ld c, a
	ld a, [_OAMRAM + 5]
	sub a, 8 + 1
	ld b, a
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp nz, BounceOnBottom
	call CheckAndHandleBrick
	ld a, 1
	ld [wBallMomentumX], a
BounceOnBottom:
	ld a, [_OAMRAM + 4]
	sub a, 16 - 1
	ld c, a
	ld a, [_OAMRAM + 5]
	sub a, 8
	ld b, a
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp nz, BounceDone
	call CheckAndHandleBrick
	ld a, -1
	ld [wBallMomentumX], a
BounceDone:

	;First check if the ball is low enough to hit the paddle
	ld a, [_OAMRAM]
	ld b, a
	ld a, [_OAMRAM + 4]
	add a, 4
	cp a, b
	jp nz, PaddleBounceDone ; If the ball isnt at the same y position as the paddle
	;Compare the x position to check if they are touching
	ld a, [_OAMRAM + 5] ; balls x position
	ld b, a
	ld a, [_OAMRAM + 1] ; paddles position
	sub a, 8
	cp a, b
	jp nc, PaddleBounceDone
	add a, 8 + 16 ; 8 to undo, 16 as the with
	cp a, b
	jp c, PaddleBounceDone

	ld a, -1
	ld [wBallMomentumY], a

PaddleBounceDone:


CheckLeft:
	ld a, [wCurKeys]
	and a, PADF_LEFT
	jp z, CheckRight
Left:
	;move the paddle 1 pixel to the left
	ld a, [_OAMRAM + 1]
	dec a
	;if we have gone all the way to the left and dont want to move
	cp a, 15
	jp z, Main
	ld [_OAMRAM + 1], a
	jp Main

;checking the right button
CheckRight:
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, Main
Right:
	;Move it to the right
	ld a, [_OAMRAM + 1]
	inc a
	;If we are all the way to the right, stop moving
	cp a, 105
	jp z, Main
	ld [_OAMRAM + 1], a
	jp Main


UpdateKeys:
	;Poll half the controller
	ld a, P1F_GET_BTN
	call .onenibble
	ld b, a ; B7 - 4 = 1 ;B3 - 0 = unpressed buttons

	;poll the other half
	ld a, P1F_GET_DPAD
	call .onenibble
	swap a ; A7-4 = unpressed directions ;A3-0 = 1
	xor a, b ;A = pressed buttons + directions
	ld b, a ; B pressed buttons + directions

	;And release the controller
	ld a, P1F_GET_NONE
	ldh [rP1], a

	;combine with previous wCurKeys to make wNewKeys
	ld a, [wCurKeys]
	xor a, b ; A = keys that changed state
	and a, b ; A = keys that changed to pressed
	ld [wNewKeys], a
	ld a, b
	ld [wCurKeys], a
	ret

.onenibble
	ldh [rP1], a ; switch key matrix
	call .knownret ; burn 10 cycles calling to a known ret
	ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
	ldh a, [rP1]
	ldh a, [rP1] ; this read counts
	or a, $F0 ;A7-4 = 1; A3-0 = unpressed keys
.knownret
	ret

; Check if a brick was collided with and breaks it if possible
; @param hl: address of tile
CheckAndHandleBrick:
	ld a, [hl]
	cp a, BRICK_LEFT
	jr nz, CheckAndHandleBrickRight
	; Breack a brick from the left side
	ld [hl], BLANK_TILE
	inc hl
	ld [hl], BLANK_TILE
CheckAndHandleBrickRight:
	cp a, BRICK_RIGHT
	ret nz
	; Breake a brick from the right side
	ld [hl], BLANK_TILE
	dec hl
	ld [hl], BLANK_TILE
	ret

; COnvert a pixel to a tilemap position
; hl = $9800 + X + Y * 32
;@param b: X
;@param c: Y
;@return hl: tile address
GetTileByPixel:
	;first divide by 8 to convert a pixel position to a tile position
	;after we want to multiply by 32 on the Y
	;these opperation cancel out so we only need to mask the Y value
	ld a, c
	and a, %11111000
	ld l, a
	ld h, 0
	;now we have the position * 8 in hl
	add hl, hl ; position * 16
	add hl, hl ; position * 32
	;convert x position to an offset
	ld a, b
	srl a ;a / 2
	srl a ; a / 4
	srl a ; a / 8
	;add the offsets together
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	;add the offset ti the tilemap´s base address
	ld bc, $9800
	add hl, bc
	ret

;@param a: tile ID
;@return z: set if a is wall
IsWallTile:
	cp a, $00
	ret z
	cp a, $01
	ret z
	cp a, $02
	ret z
	cp a, $04
	ret z
	cp a, $05
	ret z
	cp a, $06
	ret z
	cp a, $07
	ret



Paddle:
    dw `13333331
    dw `30000003
    dw `13333331
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
PaddleEnd:

Tiles:
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322222
	dw `33322222
	dw `33322222
	dw `33322211
	dw `33322211
	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11111111
	dw `11111111
	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222333
	dw `22222333
	dw `22222333
	dw `11222333
	dw `11222333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `22222222
	dw `20000000
	dw `20111111
	dw `20111111
	dw `20111111
	dw `20111111
	dw `22222222
	dw `33333333
	dw `22222223
	dw `00000023
	dw `11111123
	dw `11111123
	dw `11111123
	dw `11111123
	dw `22222223
	dw `33333333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `11001100
	dw `11111111
	dw `11111111
	dw `21212121
	dw `22222222
	dw `22322232
	dw `23232323
	dw `33333333
	; Paste your logo here:
    dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222211
	dw `22222211
	dw `22222211
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11111111
	dw `11111111
	dw `11221111
	dw `11221111
	dw `11000011
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11222222
	dw `11222222
	dw `11222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222211
	dw `22222200
	dw `22222200
	dw `22000000
	dw `22000000
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11000011
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11000022
	dw `11222222
	dw `11222222
	dw `11222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222200
	dw `22222200
	dw `22222211
	dw `22222211
	dw `22221111
	dw `22221111
	dw `22221111
	dw `11000022
	dw `00112222
	dw `00112222
	dw `11112200
	dw `11112200
	dw `11220000
	dw `11220000
	dw `11220000
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22000000
	dw `22000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11110022
	dw `11110022
	dw `11110022
	dw `22221111
	dw `22221111
	dw `22221111
	dw `22221111
	dw `22221111
	dw `22222211
	dw `22222211
	dw `22222222
	dw `11220000
	dw `11110000
	dw `11110000
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `22222222
	dw `00000000
	dw `00111111
	dw `00111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `22222222
	dw `11110022
	dw `11000022
	dw `11000022
	dw `00002222
	dw `00002222
	dw `00222222
	dw `00222222
	dw `22222222
	
TilesEnd:

Tilemap:
	db $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0A, $0B, $0C, $0D, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0E, $0F, $10, $11, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $12, $13, $14, $15, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $16, $17, $18, $19, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
TilemapEnd:

Ball:
    dw `00033000
    dw `00322300
    dw `03222230
    dw `03222230
    dw `00322300
    dw `00033000
    dw `00000000
    dw `00000000
BallEnd:


