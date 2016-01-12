[section .data]

init	db	0

%define VERTEXES 3

vertexes	db	  -10,  -10,  -10,
		db	   10,   10,   10,
		db	    5,    7,    9

%define FACES 1

faces		db	0,1,2

global _vertexes_t
_vertexes_t dd vertexes_t

__SECT__

struc _face
	.v0	resd 1
	.v1	resd 1
	.v2	resd 1
	.col	resd 1
endstruc

[section .bss]

x	resd 1
y	resd 1
z	resd 1

vertexes_t	resd	VERTEXES*2	; x and y coords for each transformed vertex

face resb _face_size

	
__SECT__
                ; edi: pixels
                ; ebx: pitch
                ; esi: ddbacksurf
                
                mov	ebp, vertexes_t

                mov	dword [ebp], 150
                mov	dword [ebp+4], 20
                add	ebp, 8
                mov	dword [ebp], 0
                mov	dword [ebp+4], 0
                add	ebp, 8
                mov	dword [ebp], 5
                mov	dword [ebp+4], 55
		
		mov	ebp, face
		mov	dword [ebp+_face.v0], 0
		mov	dword [ebp+_face.v1], 1
		mov	dword [ebp+_face.v2], 2
		mov	dword [ebp+_face.col], RGB(0xFF,0,0)
		
		push	esi
		
		;call	draw_triangle_ref_flp_32bpp
		call	_draw_triangle_c_ref_flp_32bpp
		
		pop	esi
		
		emms
		

