blit:
%ifdef WINDOWED
[section .bss]
wnd_rect	resb	RECT_size
__SECT__
		; determine dest rect in screen coords

		mov	eax, [hwnd]
		mov	ebx, wnd_rect

		mov	dword [ebx + RECT.top], 0
		mov	dword [ebx + RECT.left], 0

		invoke	ClientToScreen, eax, ebx

		mov	eax, dword [ebx + RECT.top]
		add	eax, HEIGHT
		mov	dword [ebx + RECT.bottom], eax

		mov	eax, dword [ebx + RECT.left]
		add	eax, WIDTH
		mov	dword [ebx + RECT.right], eax

		; ebp: blit dest rect
		mov	ebp, ebx

                mov	edi, [ddprimsurf]
		mov	ebx, [edi]

		mov	esi, [ddbacksurf]

		mov	eax, ddbltfx
		mov	dword [eax + DDBLTFX.dwSize], DDBLTFX_size
		mov	dword [eax + DDBLTFX.dwDDFX], DDBLTFX_NOTEARING

		; no error checking here, because if window is being destroyed this
		; will fail, and we don't want error handling interfering then
		invokeintf ebx, IDirectDrawSurface.Blt, edi, ebp, esi, byte 0, dword DDBLT_WAIT | DDBLT_DDFX, eax

%else
; *** esi, ebx: ddbacksurf 
; note that we call Flip on de primary surface. ebx contains the vtable* for 
; IDirectDrawSurface we got in render.asm from ddbacksurf, and as that is also
; an IDDS we don't need to "mov esi, [ddprimsurf]; mov ebx, [esi]" here!
		invokeintf ebx, IDirectDrawSurface.Flip, dword [ddprimsurf], 0, dword DDBLT_WAIT
%endif