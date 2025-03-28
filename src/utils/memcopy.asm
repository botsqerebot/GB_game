section "Memory Copy Utility", ROM0

;copy bytes from one area to another
;@param de: source
;@param hl: Destination
;param bc: Lenght
Memcopy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret
