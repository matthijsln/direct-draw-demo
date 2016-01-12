extern _draw_triangle_c_ref_flp_32bpp

draw_triangle_ref_flp_32bpp:

		; edi: surface
		; ebx: pitch
		; WIDTH, HEIGHT
		; face, ebp: _face struct with 
		;  .v0, .v1, .v2 - indexes into vertexes_t array of (dword x, dword y) coords
		;  .col
		; uses MMX, use femms or emms

[section .bss]
p0:
x0 resd 1
y0 resd 1
p1:
x1 resd 1
y1 resd 1
p2:
x2 resd 1
y2 resd 1

ix resd 1
ix2 resd 1
__SECT__
		
		mov	eax, vertexes_t
		
		movq	mm0, [eax]
		movq	mm1, [eax+8]
		movq	mm2, [eax+16]
		
		movq	[p0], mm0
		movq	[p1], mm1
		movq	[p2], mm2

		; sort points according to height
	
		int3
		
		; if (p1.y < p0.y) swap (p0,p1)
		
		mov	eax, [y1]
		cmp	eax, [y0]
		jge	.sorted1
		; swap p0/p1
		movq	mm0, [p0]
		movq	mm1, [p1]
		movq	[p0], mm1
		movq	[p1], mm0
		
.sorted1:
		; if (p2.y < p0.y) swap (p0,p2)

		mov	ecx, [y2]		; NOTE: ecx == y0, used later
		cmp	ecx, [y0]
		jge	.sorted2
		; swap p0/p2
		movq	mm0, [p0]
		movq	mm1, [p2]
		movq	[p0], mm1
		movq	[p2], mm0
		
.sorted2:
		; if (p2.y < p1.y) swap (p1,p2)

		mov	eax, [y2]
		cmp	eax, [y1]
		jge	.sorted3
		; swap p1/p2
		movq	mm0, [p1]
		movq	mm1, [p2]
		movq	[p1], mm1
		movq	[p2], mm0
		
.sorted3:
		emms
		
%if 1		
		; calc dx/dy to p1 
		
		int3
		
		fild	dword [x0]			; x0
				
		fild	dword [x1]			; x1    | x0
		fsub	st0, st1	; x1-x0		; dx1   | x0
		
		fild	dword [y0]			; y0    | dx1   | x0
		
		fild	dword [y1]			; y1    | y0    | dx1   | x0
		fsub	st0, st1	; y1-y0		; dy1   | y0    | dx1   | x0
		
		ftst
		fnstsw	ax
		sahf
		jnz	.dy1nz
		
		; dy1 == 0.0 | y0 | dx1 | x0
		
		fstp	st2
		
		; y0 | dxdy1 == 0.0 | x0
		
		jmp	.l0
		
.dy1nz:		
		fdivp	st2, st0	; dx1/dy1	; y0    | dxdy1 | x0
.l0:
		; y0 | dxdy1 | x0
		
		; calc dx/dy to p2
		
		fild	dword [x2]			; x2    | y0    | dxdy1 | x0
		fsub	st0, st3	; x2-x0		; dx2   | y0    | dxdy1 | x0
		
		fild	dword [y2]			; y2    | dx2   | y0    | dxdy1 | x0
		fsub	st0, st2	; y2-y0		; dy2   | dx2   | y0    | dxdy1 | x0

		ftst
		fnstsw	ax
		sahf
		jnz	.dy2nz
		
		; dy2 == 0.0 | dx2 | y0 | dxdy1 | x0
		
		fstp	st1
		
		; dxdy2 == 0.0 | y0 | dxdy1 | x0
		
		jmp	.l1
.dy2nz:		
		fdivp	st1, st0	; dx2/dy2	; dxdy2 | y0    | dxdy1 | x0
.l1:		
		
		; the edge with the smallest dxdy is the left edge
		
		fcomi	st0, st2
		jb	.dxdy2smallest
		
		; dxdy1 is smallest
		
		fxch	st2
		
.dxdy2smallest:
		; dxdyL: dxdy for left edge
		; dxdyR: dxdy for right edhe
		
		; dxdyL | y0 | dxdyR | x0
		
		fstp	st1				; dxdyL | dxdyR | x0		
		
		; let y go from y0 to y1 to trace upper half
		
		; NOTE: ecx == y0
		;	ebx == pitch
		;	edi == surface
		
		fxch	st2
		
		; x0 | dxdyR | dxdyL
				
		fst	st3
		
		; x0 | dxdyR | dxdyL | x0

.traceupper:
		; xL | dxdyR | dxdyL | xR

		fist	dword [ix]
		fxch	st3
		fist	dword [ix2]
		fxch	st3
		
		mov	eax, ecx			; ecx = y0
		mul	ebx
		mov	edx, [ix]
		lea	eax, [eax+edx*4]
		
		mov	esi, [ix2]
		sub	esi, edx
		jz	.skip_scanlineupper
.scanlineupper:		
		mov	dword [edi+eax], 0x0
		add	eax, 4
		dec	esi
		jnz	.scanlineupper
.skip_scanlineupper:
		; calc new x
		
		; xL | dxdyR | dxdyL | xR
		
		fadd	st0, st2
		fxch	st3
		fadd	st0, st1
		fxch	st3

		inc	ecx
		cmp	ecx, [y1]
		jna	.traceupper

		; xL | dxdyR | dxdyL | xR

		fild	dword [x1]
		fstp	st4

		fild	dword [x2]			; x2 | xL | dxdyR | dxdyL | x1
		fsubr	st0, st4
		fild	dword [y2]
		fisub	dword [y1]
		fdivp	st1, st0
		fstp	st2
		
		; xL | dxdyR2 | dxdyL | x1

.tracelower:
		; xL | dxdyR2 | dxdyL | xR

		fist	dword [ix]
		fxch	st3
		fist	dword [ix2]
		fxch	st3
		
		mov	eax, ecx			; ecx = y
		mul	ebx
		mov	edx, [ix]
		lea	eax, [eax+edx*4]
		
		mov	esi, [ix2]
		sub	esi, edx
		jz	.skip_scanlinelower
.scanlinelower:		
		mov	dword [edi+eax], 0x0
		add	eax, 4
		dec	esi
		jnz	.scanlinelower
.skip_scanlinelower:
		; calc new x
		
		; xL | dxdyR2 | dxdyL | xR
		
		fadd	st0, st2
		fxch	st3
		fsub	st0, st1
		fxch	st3

		inc	ecx
		cmp	ecx, [y2]
		jna	.tracelower
%endif		
%if 1
		; color p0 red, p1 green, p2 blue
		
		mov	eax, [y0]
		mul	ebx
		mov	ecx, [x0]
		lea	eax, [eax+ecx*4]
		
		mov	ecx, 0xff0000
		mov	dword [edi+eax], ecx

		mov	eax, [y1]
		mul	ebx
		mov	ecx, [x1]
		lea	eax, [eax+ecx*4]
		
		mov	ecx, 0x00ff00
		mov	dword [edi+eax], ecx

		mov	eax, [y2]
		mul	ebx
		mov	ecx, [x2]
		lea	eax, [eax+ecx*4]
		
		mov	ecx, 0x0000ff
		mov	dword [edi+eax], ecx
%endif

		ret