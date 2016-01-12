%include "utils.inc"

[section .bss]
ddbltfx	resb    DDBLTFX_size
t		resd 1
col		resd 1
__SECT__
		invoke	timeGetTime
		sub	eax, [start_time]
		mov	[t], eax


                mov     esi, [ddbacksurf]
                mov     ebx, [esi]

%if 1
                mov     eax, ddbltfx
                mov     dword [eax + DDBLTFX.dwSize], DDBLTFX_size

                ;mov	ecx, RGB(249,240,213)
                mov	ecx, RGB(0xff,0xff,0xff)

                mov     dword [eax + DDBLTFX.dwFillColor], ecx

                invokeintf ebx, IDirectDrawSurface.Blt, esi, byte 0, byte 0, byte 0, dword DDBLT_WAIT | DDBLT_COLORFILL, eax
                checkerror {test eax, eax}, nz, eback
%endif

                invokeintf ebx, IDirectDrawSurface.Lock, esi, byte 0, dword ddsd, dword DDLOCK_WAIT, byte 0
                checkerror {test eax, eax}, nz, eback

                mov     edi, [ddsd + DDSURFACEDESC.lpSurface]
                mov     ebx, [ddsd + DDSURFACEDESC.lPitch]

; -----------------------------------------------------------------------------

                mov     edi, [ddsd + DDSURFACEDESC.lpSurface]
                mov     ebx, [ddsd + DDSURFACEDESC.lPitch]

%include "part0.asm"

; -----------------------------------------------------------------------------

		mov	ebx, [esi]		
                invokeintf ebx, IDirectDrawSurface.Unlock, esi, byte 0
                checkerror {test eax, eax}, nz, eback

%ifdef FPS_DISPLAY 

%define FPS_UPDATE_INTERVAL	1000		; update fps every x ms

%include "libc.inc"
%include "gdi32.inc"
[section .bss]
hdc		resd 1
textbuf		resb 32
[section .data]
fps_start	dd 0
frames		dd 0
_temp:
fps		dd 0
nf1000		dd 1000.0 
format		db "%u", 0
__SECT__
		inc	dword [frames]
		
		invoke	timeGetTime
		sub	eax, [start_time]
		mov	edi, eax
		
		sub	eax, [fps_start]
		
		cmp	eax, FPS_UPDATE_INTERVAL
		jl	.no_fps_calc
		
		; frames / s = fps
		
        	fild	dword [frames]
        	
        	mov	[_temp], eax
        	fild	dword [_temp]
        	
        	; convert ms to s
        	
        	fdiv	dword [nf1000]
        	
        	; divide frames by s
        	
        	fdivp	st1, st0
        	fistp	dword [fps]

        	mov	dword [fps_start], edi
        	mov	dword [frames], 0
        	
.no_fps_calc:

		push	dword [fps]
        	push	format
        	push	textbuf
        	call	[wsprintfA]
        	add	esp, 3*4
        	
                mov	edi, eax

                invokeintf ebx, IDirectDrawSurface.GetDC, esi, hdc
               	invoke	TextOutA, dword [hdc], 10, 10, textbuf, edi
                invokeintf ebx, IDirectDrawSurface.ReleaseDC, esi, hdc
%endif          
                
; *** ebx: IDirectDrawSurface vtable*

