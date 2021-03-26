segment datos data
	fileOrig	  db "prueba.dat",0
	foHandle	  resw 1
	regOrig		  resb 4
	msjErrOpen	  db "Error en apertura$"
	msjErrRead	  db "Error en lectura$"
	msjErrClose	  db "Error en cierre$"
	signo		  resb 1
	signoNegExp   db "-$"
	infinito      db " oo$"
	naN           db "NAN$"
	resultSigno   resb 1
	menosUno      db -1b
	unoComa       db " 1,$"
	zero          db " 0$"
	ceroComa      db " 0,$"
	mantiza       db "                       $"
	por10Elev     db " x 10^$"
	exponente     db "        $"
	exponenteSub  db "1111110 $" ;126 en binario para PS
	enconSignifi  resb 1
	enterCarac    db 10,13,"$"
	contPasadas   resb 1
	numEspecial   resb 1
	infinitoONan  resb 1
	zeroOSubNorm  resb 1
	mantizaDist0  resb 1
	
segment codigo code
..start:
	mov ax,datos
	mov ds,ax
	mov ax,pila
	mov ss,ax
	
	mov	al,0
	lea dx,[fileOrig]
	call fOpen
	jc errOpen
	mov [foHandle],ax
	
readNext:
	mov	bx,[foHandle]
	mov cx,4
	lea dx,[regOrig]
	call fRead
	jc errRead
	cmp ax,4
	jne finArch
	
	call limpiarFlags
	shl [regOrig],1
	call verSigno
	mov ah,0
	mov al,byte[regOrig]
	;aca me queda el exponente con un 0 a izquierda
	;veo si corresponde reemplazar con 1 o 0
	shl [regOrig+1],1
	jc sumo1
	;iba cero no hace falta sumarle nada
	jmp resto127
sumo1:
	add al,00000001b
resto127:
	call verSiEsEsp
	cmp byte[numEspecial],1
	je almacenarM
	sub ax,0000000001111111b
	call limpiarExp
	call almacExp
almacenarM:
	call almacMan
	call verManIgual0
	cmp byte[numEspecial],1
	jne impNormal
	call imprimNotEsp
	jmp siguiente
impNormal:
	call imprimNotC
siguiente:
	jmp readNext	
		
finArch:
	mov bx,[foHandle]
	call fClose
	jc errClose
fin:
	mov	ah,4ch
	int 21h
	
;Subrutinas

limpiarFlags:
	mov byte[zeroOSubNorm],0
	mov byte[infinitoONan],0
	mov byte[numEspecial],0
	mov byte[mantizaDist0],0
	ret
	
verSigno:
	jc  esNegativo
	mov byte[signo],"+"
	ret
esNegativo:
	mov byte[signo],"-"
	ret

verSiEsEsp:
	cmp al,255
	jne verSubOsi0
	mov byte[infinitoONan],1
	jmp esEsp
verSubOsi0:
	cmp al,0
	jne retornar
	mov byte[zeroOSubNorm],1
esEsp:
	mov byte[numEspecial],1
retornar:
	ret
	
limpiarExp:
	mov cx,7
	mov si,0
insEsp:
	mov byte[exponente+si]," "
	inc si
	loop insEsp
	inc si
	mov byte[exponente+si],"$"
	ret
	
almacExp:
	mov byte[resultSigno],0
	cmp al,0
	jg proc
	mov byte[resultSigno],1
	imul byte[menosUno]
proc:
	mov byte[enconSignifi],0
	mov cx,8
	mov si,0
otro:
	shl al,1
	jc  alma1Exp
	cmp byte[enconSignifi],0
	je cxLoop
	mov byte[exponente+si],"0"
	inc si
	jmp cxLoop	
alma1Exp:
	mov byte[enconSignifi],1
	mov byte[exponente+si],"1"
	inc si			
cxLoop:
	loop otro
	ret
	
almacMan:
	mov cx,7
	mov si,0
	mov di,1
	mov byte[contPasadas],0
otroMas:
    shl [regOrig+di],1
	jc  alma1Man
	mov byte[mantiza+si],"0"
	jmp sigLoop
alma1Man:
	mov byte[mantiza+si],"1"
sigLoop:
	inc si
	loop otroMas
	inc di
	mov cx,8
	inc byte[contPasadas]
	cmp byte[contPasadas],3
	je volver
	jmp otroMas
volver:	
	ret	
	
verManIgual0:
	mov cx,23
	mov si,0
next:
	cmp byte[mantiza+si],"0"
	jne hayUno
	inc si
	loop next
	jmp done
hayUno:
	mov byte[mantizaDist0],1
done:
	ret
	
imprimNotC:
    mov dl,[signo]
	call printChar
	mov dx,unoComa
	call printMsg
	mov dx,mantiza
	call printMsg
	mov dx,por10Elev
	call printMsg
	cmp byte[resultSigno],0
	je  imprimExp
	mov dx,signoNegExp
	call printMsg
imprimExp:
	mov dx,exponente
	call printMsg
	mov dx,enterCarac
	call printMsg
	ret
	
imprimNotEsp:
	cmp byte[infinitoONan],1
	jne esSub0Cero
	cmp byte[mantizaDist0],1
	jne esInfinito
	mov dx,naN
	call printMsg
	jmp regreso
esInfinito:
	mov dl,[signo]
	call printChar
	mov dx,infinito
	call printMsg
	jmp regreso	
esSub0Cero:
	mov dl,[signo]
	call printChar
	cmp byte[mantizaDist0],1
	jne esCero
	mov dx,ceroComa
	call printMsg
	mov dx,mantiza
	call printMsg
	mov dx,por10Elev
	call printMsg
	mov dx,exponenteSub
	call printMsg
	jmp regreso
esCero:
	mov dx,zero
	call printMsg
regreso:
	mov dx,enterCarac
	call printMsg
	ret
	
fOpen:
	mov	ah,3dh		;abrir archivo 3dh
	int	21h
	ret
	
fRead:
	mov	ah,3fh		;leer un archivo: 3fh
	int	21h
	ret
	
fClose:
	mov	ah,3eh		;cerrar archivo: 3eh
	int	21h
	ret

errOpen:
	mov	dx,msjErrOpen
	call printMsg
	jmp fin
	
errRead:
	mov	dx,msjErrRead
	call printMsg
	jmp fin
	
errClose:
	mov	dx,msjErrClose
	call printMsg
	ret
	
printMsg:
	mov	ah,9   ;imprimir cadena en pantalla
	int	21h
	ret
	
printChar:
	mov ah,2
	int 21h
	ret

segment pila stack