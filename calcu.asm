.model small
.stack 100h

.data
    op1 db 12 dup('$')
    op2 db 12 dup('$')
    resultStr db 12 dup('$')

    msg1 db 'Base(b/h/d): $'
    msg2 db 'Operande 1: $'
    msg3 db 'Operande 2: $'
    msg4 db 'Operation: $'
    msgRes db 'Resultats: $'
    msgBIN db 'Bin: $'
    msgDEC db 'Dec: $'
    msgHEX db 'Hex: $'
    msgERR db 'Div par 0!$'
    msgFlags db 'Flags: ZF:$'
    msgSF db ' SF:$'
    msgCF db ' CF:$'
    msgOF db ' OF:$'
    msgZero db '0', '$'
    newline db 0Dh, 0Ah, '$'
    msgTitle db 'BIMO CALCULATOR', '$'  ; Added title message

    base db ?
    oper db ?

    val1 dw ?
    val2 dw ?
    res dw ?
    
    ; Variables pour le positionnement du curseur dans la zone noire
    currentRow db 3    ; Ligne initiale dans la zone noire (ajust? par rapport ? la position absolue)
    currentCol db 26   ; Colonne initiale dans la zone noire (ajust? par rapport ? la position absolue)
    saveFlags dw ?     ; Pour sauvegarder les flags apr?s l'op?ration

.code
main proc
    mov ax, @data
    mov ds, ax

    ; Initialiser l'?cran texte
    mov ax, 0003h
    int 10h

    ; Appel interface ?cran
    call screen

    ; Effacer l'?cran noir au d?but
    call ClearBlackScreen
    
    ; Lecture de la base
    call PositionCursor
    lea dx, msg1
    call PrintStr
    call ReadChar
    mov base, al
    call ClearCurrentLine
    
    ; Lecture du premier op?rande
    call PositionCursor
    lea dx, msg2
    call PrintStr
    lea di, op1
    call ReadStr
    lea dx, op1
    call ConvertToNum
    mov val1, ax
    call ClearCurrentLine
    
    ; Lecture du second op?rande
    call PositionCursor
    lea dx, msg3
    call PrintStr
    lea di, op2
    call ReadStr
    lea dx, op2
    call ConvertToNum
    mov val2, ax
    call ClearCurrentLine
    
    ; Lecture de l'op?ration
    call PositionCursor
    lea dx, msg4
    call PrintStr
    call ReadChar
    mov oper, al
    call ClearCurrentLine

    ; Traitement
    mov ax, val1
    mov bx, val2

    cmp oper, '+'
    je DoAdd
    cmp oper, '-'
    je DoSub
    cmp oper, '*'
    je DoMul
    cmp oper, '/'
    je DoDiv
    cmp oper, '&'
    je DoAnd
    cmp oper, '|'
    je DoOr
    cmp oper, '^'
    je DoXor
    jmp Done

DoAdd:
    add ax, bx
    ; Sauvegarde des drapeaux imm?diatement apr?s l'op?ration
    pushf
    pop saveFlags
    jmp StoreRes
DoSub:
    sub ax, bx
    pushf
    pop saveFlags
    jmp StoreRes
DoMul:
    imul bx
    pushf
    pop saveFlags
    jmp StoreRes
DoDiv:
    cmp bx, 0
    je DivErr
    cwd
    idiv bx
    pushf
    pop saveFlags
    jmp StoreRes
DoAnd:
    and ax, bx
    pushf
    pop saveFlags
    jmp StoreRes
DoOr:
    or ax, bx
    pushf
    pop saveFlags
    jmp StoreRes
DoXor:
    xor ax, bx
    pushf
    pop saveFlags
    jmp StoreRes

DivErr:
    call ClearBlackScreen
    call PositionCursor
    lea dx, msgERR
    call PrintStr
    call IncrementRow
    jmp Done

StoreRes:
    mov res, ax

    ; Afficher le r?sultat avec un ?cran propre
    call ClearBlackScreen
    
    call PositionCursor
    lea dx, msgRes
    call PrintStr
    call IncrementRow

    call PositionCursor
    lea dx, msgBIN
    call PrintStr
    mov ax, res
    call PrintBin
    call IncrementRow

    call PositionCursor
    lea dx, msgDEC
    call PrintStr
    mov ax, res
    call PrintSignedDec
    call IncrementRow

    call PositionCursor
    lea dx, msgHEX
    call PrintStr
    mov ax, res
    call PrintHex
    call IncrementRow

    ; Afficher les flags correctement sur une seule ligne avec labels
    call PositionCursor
    lea dx, msgFlags
    call PrintStr
    
    ; Afficher ZF (Zero Flag)
    ; Si le r?sultat est 0, ZF doit ?tre 1
    cmp res, 0
    jnz NotZeroFlag
    mov dl, '1'
    jmp PrintZF
NotZeroFlag:
    mov dl, '0'
PrintZF:
    call PrintChar
    
    ; Afficher SF (Sign Flag) avec son label
    lea dx, msgSF
    call PrintStr
    ; Si le bit le plus significatif du r?sultat est 1, SF doit ?tre 1
    test res, 8000h
    jz NotSignFlag
    mov dl, '1'
    jmp PrintSF
NotSignFlag:
    mov dl, '0'
PrintSF:
    call PrintChar
    
    ; Afficher CF (Carry Flag) avec son label
    lea dx, msgCF
    call PrintStr
    mov ax, saveFlags
    test ax, 0001h     ; Test bit 0 (CF)
    jz NotCarryFlag
    mov dl, '1'
    jmp PrintCF
NotCarryFlag:
    mov dl, '0'
PrintCF:
    call PrintChar
    
    ; Afficher OF (Overflow Flag) avec son label
    lea dx, msgOF
    call PrintStr
    mov ax, saveFlags
    test ax, 0800h     ; Test bit 11 (OF)
    jz NotOverflowFlag
    mov dl, '1'
    jmp PrintOF
NotOverflowFlag:
    mov dl, '0'
PrintOF:
    call PrintChar

Done:
    mov ah, 4ch
    int 21h

main endp

; ----------------------------------------------------------
; PROC?DURES D'AFFICHAGE DANS LA ZONE NOIRE
; ----------------------------------------------------------

; Positionne le curseur ? la position courante dans la zone noire
PositionCursor proc
    mov ah, 02h       ; Fonction BIOS pour d?placer le curseur
    mov bh, 0         ; Page vid?o
    mov dh, [currentRow]    ; Ligne
    mov dl, [currentCol]    ; Colonne
    int 10h
    ret
PositionCursor endp

; Incr?mente la ligne courante pour le prochain affichage
IncrementRow proc
    inc [currentRow]
    ; V?rifie si on doit retourner en haut de la zone noire
    cmp [currentRow], 9    ; La zone noire s'arr?te ? la ligne 9
    jl IncrementRow_Done
    mov [currentRow], 3    ; Retour au d?but de la zone noire
IncrementRow_Done:
    ret
IncrementRow endp

; Efface la ligne courante
ClearCurrentLine proc
    mov ah, 6       ; Fonction pour scroller la fen?tre (utilis?e pour effacer)
    mov al, 0       ; Effacer la ligne enti?re
    mov bh, 00001110b ; Attributs de la zone noire (noir avec texte jaune)
    mov ch, [currentRow] ; Ligne de d?but = ligne courante
    mov cl, 25      ; Colonne de d?but (bord gauche de zone noire)
    mov dh, [currentRow] ; Ligne de fin = ligne courante
    mov dl, 58      ; Colonne de fin (bord droit de zone noire)
    int 10h
    ; Repositionne le curseur au d?but de la ligne
    mov dl, [currentCol]
    call PositionCursor
    ret
ClearCurrentLine endp

; Efface l'?cran noir entier
ClearBlackScreen proc
    mov ah, 6       ; Fonction pour scroller la fen?tre
    mov al, 0       ; Effacer tout
    mov bh, 00001110b ; Attributs de la zone noire
    mov ch, 2       ; Ligne de d?but
    mov cl, 25      ; Colonne de d?but
    mov dh, 9       ; Ligne de fin
    mov dl, 58      ; Colonne de fin
    int 10h
    ; Repositionne le curseur au d?but de la zone noire
    mov [currentRow], 3
    mov dl, [currentCol]
    call PositionCursor
    ret
ClearBlackScreen endp

; ----------------------------------------------------------
; PROC?DURES INTERFACE (provenant de INTERFACE.asm)
; ----------------------------------------------------------

screen proc
   ; Effacer l'?cran avec fond blanc
    mov ah, 6
    mov al, 0
    mov bh, 01111111b
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 80
    int 10h
    
    ; Afficher le titre "BIMO CALCULATOR"
    mov ah, 2
    mov bh, 0
    mov dh, 1
    mov dl, 36
    int 10h
    mov ah, 9
    lea dx, msgTitle
    int 21h
    
    ; Cadre bleu principal
    mov ah, 6
    mov al, 0
    mov bh, 00111110b
    mov ch, 0
    mov cl, 20
    mov dh, 24
    mov dl, 64
    int 10h
    
    ; Titre "BIMO CALCULATOR" au-dessus de l'?cran noir
    mov ah, 2
    mov bh, 0
    mov dh, 1       ; Ligne 1 (au-dessus de l'?cran noir)
    mov dl, 36      ; Centr? approximativement
    int 10h
    lea dx, msgTitle
    mov ah, 9
    int 21h
    
    ; ?cran noir (zone de r?sultat)
    mov ah, 6
    mov al, 0
    mov bh, 00001110b
    mov ch, 2
    mov cl, 25
    mov dh, 9
    mov dl, 58
    int 10h
    
    ; Boutons num?riques (3 lignes de 5 boutons)
    ; Ligne 1 (1-5)
    mov bh, 00001110b
    mov ch, 11
    mov dh, 13
    
    mov cl, 25
    mov dl, 30
    int 10h
    
    mov cl, 32
    mov dl, 37
    int 10h
    
    mov cl, 39
    mov dl, 44
    int 10h
    
    mov cl, 46
    mov dl, 51
    int 10h
    
    mov cl, 53
    mov dl, 58
    int 10h
    
    ; Ligne 2 (6-0)
    mov ch, 15
    mov dh, 17
    
    mov cl, 25
    mov dl, 30
    int 10h
    
    mov cl, 32
    mov dl, 37
    int 10h
    
    mov cl, 39
    mov dl, 44
    int 10h
    
    mov cl, 46
    mov dl, 51
    int 10h
    
    mov cl, 53
    mov dl, 58
    int 10h
    
    ; Ligne 3 (op?rateurs)
    mov ch, 19
    mov dh, 21
    
    mov cl, 25
    mov dl, 30
    int 10h
    
    mov cl, 32
    mov dl, 37
    int 10h
    
    mov cl, 39
    mov dl, 44
    int 10h
    
    mov cl, 46
    mov dl, 51
    int 10h
    
    mov cl, 53
    mov dl, 58
    int 10h
    
    ; Bordures color?es gauche
    mov bh, 00111110b
    mov ch, 0
    mov dh, 24
    mov cl, 0
    mov dl, 2
    int 10h
    
    mov bh, 00111110b
    mov cl, 3
    mov dl, 5
    int 10h
    
    mov bh, 00111110b
    mov cl, 6
    mov dl, 8
    int 10h
    
    mov bh, 00111110b
    mov cl, 9
    mov dl, 11
    int 10h
    
    mov bh, 00111110b
    mov cl, 12
    mov dl, 14
    int 10h
    
    mov bh, 00111110b
    mov cl, 15
    mov dl, 17
    int 10h
    
    mov bh, 00111110b
    mov cl, 18
    mov dl, 20
    int 10h
    
    ; Bordures color?es droite
    mov bh, 00111110b
    mov cl, 63
    mov dl, 65
    int 10h
    
    mov bh, 00111110b
    mov cl, 66
    mov dl, 68
    int 10h
    
    mov bh, 00111110b
    mov cl, 69
    mov dl, 71
    int 10h
    
    mov bh, 00111110b
    mov cl, 72
    mov dl, 74
    int 10h
    
    mov bh, 00111110b
    mov cl, 75
    mov dl, 77
    int 10h
    
    ; Afficher les chiffres et op?rateurs
    ; Chiffres 1-3 (ligne 1)
    mov ah, 2
    mov bh, 0
    mov dh, 12
    mov dl, 27
    int 10h
    mov ah, 2
    mov dl, '1'
    int 21h
    
    mov dh, 12
    mov dl, 34
    int 10h
    mov dl, '2'
    int 21h
    
    mov dh, 12
    mov dl, 41
    int 10h
    mov dl, '3'
    int 21h
    
    ; Chiffres 4-6 (ligne 2)
    mov dh, 16
    mov dl, 27
    int 10h
    mov dl, '4'
    int 21h
    
    mov dh, 16
    mov dl, 34
    int 10h
    mov dl, '5'
    int 21h
    
    mov dh, 16
    mov dl, 41
    int 10h
    mov dl, '6'
    int 21h
    
    ; Chiffres 7-9 (ligne 3)
    mov dh, 20
    mov dl, 27
    int 10h
    mov dl, '7'
    int 21h
    
    mov dh, 20
    mov dl, 34
    int 10h
    mov dl, '8'
    int 21h
    
    mov dh, 20
    mov dl, 41
    int 10h
    mov dl, '9'
    int 21h
    
    ; Chiffre 0
    mov dh, 20
    mov dl, 48
    int 10h
    mov dl, '0'
    int 21h
    
    ; Op?rateurs
    mov dh, 12
    mov dl, 48
    int 10h
    mov dl, '+'
    int 21h
    
    mov dh, 12
    mov dl, 55
    int 10h
    mov dl, '-'
    int 21h
    
    mov dh, 16
    mov dl, 48
    int 10h
    mov dl, '*'
    int 21h
    
    mov dh, 16
    mov dl, 55
    int 10h
    mov dl, '/'
    int 21h
    
    mov dh, 20
    mov dl, 55
    int 10h
    mov dl, '='
    int 21h
    
    ret
screen endp

; ----------------------------------------------------------
; PROC?DURES UTILITAIRES
; ----------------------------------------------------------
PrintStr:
    mov ah, 09h
    int 21h
    ret

PrintChar:
    mov ah, 02h
    int 21h
    ret

ReadChar:
    mov ah, 01h
    int 21h
    ret

NewLine:
    lea dx, newline
    call PrintStr
    ret

ReadStr:
    mov cx, 0
ReadStr_next:
    call ReadChar
    cmp al, 13
    je ReadStr_done
    mov [di], al
    inc di
    inc cx
    jmp ReadStr_next
ReadStr_done:
    mov byte ptr [di], '$'
    ret

ConvertToNum:
    mov si, dx
    xor ax, ax
    xor cx, cx
    mov bl, [si]
    cmp bl, '-'
    jne Conv_start
    inc si
    mov cl, 1
Conv_start:
Conv_nextDigit:
    mov bl, [si]
    cmp bl, '$'
    je Conv_done
    cmp base, 'd'
    je Conv_decimal
    cmp base, 'h'
    je Conv_hexa
    shl ax, 1
    sub bl, '0'
    add ax, bx
    inc si
    jmp Conv_nextDigit
Conv_decimal:
    mov dx, 0
    mov bx, 10
    mul bx
    mov bl, [si]
    sub bl, '0'
    add ax, bx
    inc si
    jmp Conv_nextDigit
Conv_hexa:
    mov dx, 0
    mov bx, 16
    mul bx
    mov bl, [si]
    cmp bl, 'A'
    jb HexDigit
    cmp bl, 'a'
    jb HexDigit
    sub bl, 32
HexDigit:
    cmp bl, '9'
    jbe HexDigitAdd
    sub bl, 7
HexDigitAdd:
    sub bl, '0'
    add ax, bx
    inc si
    jmp Conv_nextDigit
Conv_done:
    cmp cl, 1
    jne Conv_ret
    neg ax
Conv_ret:
    ret

PrintSignedDec:
    cmp ax, 0
    jge PrintDec
   
    neg ax
    push ax
    mov dl, '-'
    call PrintChar
    pop ax
    call PrintDec
    
    ret

PrintDec:
    cmp ax, 0
    jne PrintDec_nonzero
    mov dl, '0'
    call PrintChar
    ret
PrintDec_nonzero:
    mov cx, 0
    mov bx, 10
PrintDec_next:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne PrintDec_next
PrintDec_print:
    pop dx
    add dl, '0'
    call PrintChar
    loop PrintDec_print
    ret

PrintHex:
    cmp ax, 0
    jne PrintHex_nonzero
    mov dl, '0'
    call PrintChar
    ret
PrintHex_nonzero:
    mov cx, 0
    mov bx, 16
PrintHex_next:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne PrintHex_next
PrintHex_print:
    pop dx
    add dl, '0'
    cmp dl, '9'
    jbe PrintHex_ok
    add dl, 7
PrintHex_ok:
    call PrintChar
    loop PrintHex_print
    ret

PrintBin:
    cmp ax, 0
    jne PrintBin_nonzero
    mov dl, '0'
    call PrintChar
    ret
PrintBin_nonzero:
    mov cx, 0
    mov bx, 2
PrintBin_next:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne PrintBin_next
PrintBin_print:
    pop dx
    add dl, '0'
    call PrintChar
    loop PrintBin_print
    ret

end main