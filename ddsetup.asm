; *** ebp: window handle
[section .bss]
ddobj		resd	1
__SECT__
		; --- DirectDraw setup ---

		; create dd object

		invoke	DirectDrawCreate, byte 0, dword ddobj, byte 0
		checkerror {test eax, eax}, nz, eddc

		mov	esi, [ddobj]
		mov	ebx, [esi]

%ifdef WINDOWED
		invokeintf ebx, IDirectDraw.SetCooperativeLevel, esi, byte 0, byte DDSCL_NORMAL
		checkerror {test eax, eax}, nz, escl

		; create the primary surface
[section .bss]
ddsd		resb DDSURFACEDESC_size

ddprimsurf	resd 1			; primary surface	
ddbacksurf	resd 1			; secondary surface	
ddprimclipper	resd 1				

__SECT__
		mov	eax, ddsd
                mov	dword [eax + DDSURFACEDESC.dwSize], DDSURFACEDESC_size
		mov	dword [eax + DDSURFACEDESC.dwFlags], DDSD_CAPS
		mov	dword [eax + DDSURFACEDESC.ddsCaps + DDCAPS.dwCaps], DDSCAPS_PRIMARYSURFACE

		invokeintf ebx, IDirectDraw.CreateSurface, esi, eax, dword ddprimsurf, byte 0
		checkerror {test eax, eax}, nz, esurf

		invokeintf ebx, IDirectDraw.CreateClipper, esi, byte 0, dword ddprimclipper, byte 0

		mov	ebp, [ddprimclipper]
		mov	edi, [ebp]

		invokeintf edi, IDirectDrawClipper.SetHWnd, ebp, byte 0, dword [hwnd]

		mov	ebp, [ddprimsurf]
		mov	edi, [ebp]

		invokeintf edi, IDirectDrawSurface.SetClipper, ebp, dword [ddprimclipper]

		mov	eax, ddsd
		push	eax			; save ddsd
		mov	dword [eax + DDSURFACEDESC.dwFlags], DDSD_CAPS | DDSD_HEIGHT | DDSD_WIDTH | DDSD_PIXELFORMAT

		; we only want the pixel format, really
		invokeintf edi, IDirectDrawSurface.GetSurfaceDesc, ebp, eax

		pop	eax			; get ddsd back

%ifdef BPP_CHECK
		cmp	dword [eax + DDSURFACEDESC.ddpfPixelFormat + DDPIXELFORMAT.dwRGBBitCount], BPP
		je	.ok
		invoke 	MessageBoxA, byte 0, dword epfbad, dword window_title, byte 0
		ret
.ok:
%endif
		mov	dword [eax + DDSURFACEDESC.ddsCaps + DDCAPS.dwCaps], DDSCAPS_OFFSCREENPLAIN
		mov	dword [eax + DDSURFACEDESC.dwWidth], WIDTH
		mov	dword [eax + DDSURFACEDESC.dwHeight], HEIGHT

		invokeintf ebx, IDirectDraw.CreateSurface, esi, eax, dword ddbacksurf, byte 0
		checkerror {test eax, eax}, nz, esurf
%else
		; fullscreen

[section .bss]
ddsd		resb DDSURFACEDESC_size

ddprimsurf	resd 1				; primary surface
ddbacksurf	resd 1				; backbuffer

__SECT__

		invokeintf ebx, IDirectDraw.SetCooperativeLevel, esi, ebp, byte DDSCL_ALLOWMODEX | DDSCL_EXCLUSIVE | DDSCL_FULLSCREEN
		checkerror {test eax, eax}, nz, escl

		invokeintf ebx, IDirectDraw.SetDisplayMode, esi, dword WIDTH, dword HEIGHT, byte BPP
		checkerror {test eax, eax}, nz, esdm

		mov	eax, ddsd
                mov	dword [eax + DDSURFACEDESC.dwSize], DDSURFACEDESC_size
		mov	dword [eax + DDSURFACEDESC.dwFlags], DDSD_CAPS | DDSD_BACKBUFFERCOUNT
		mov	dword [eax + DDSURFACEDESC.ddsCaps + DDCAPS.dwCaps], DDSCAPS_PRIMARYSURFACE | DDSCAPS_FLIP | DDSCAPS_COMPLEX
		mov	dword [eax + DDSURFACEDESC.dwBackBufferCount], FULLSCREEN_BACKBUFFERCOUNT

		invokeintf ebx, IDirectDraw.CreateSurface, esi, eax, dword ddprimsurf, byte 0
		checkerror {test eax, eax}, nz, esurf

		; get back buffer

		; reuse DDSCAPS struct in ddsd

		push	byte DDSCAPS_BACKBUFFER
		mov	eax, esp

		mov	esi, dword [ddprimsurf]
		mov	ebx, [esi]

		invokeintf ebx, IDirectDrawSurface.GetAttachedSurface, esi, eax, dword ddbacksurf
		checkerror {test eax, eax}, nz, egas
%endif