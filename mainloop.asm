%define WINDOWED

;%define FPS_DISPLAY
%define DEBUG
%define BPP_CHECK
%define ERROR_CHECKS

%ifdef DEBUG
%define ERROR_CHECKS
%define BPP_CHECK
%endif

;-----------------------

%include "ddraw.inc"
%include "macros.inc"
%include "win32.inc"
%include "debug.inc"

%include "user32.inc"
%include "mmsystem.inc"		; timeGetTime()

%define IMAGE_BASE	0400000h

%ifdef WINDOWED
%ifdef BPP_CHECK
string		epfbad, "Color depth not 32 bpp", 0
%endif
%endif

%ifdef ERROR_CHECKS
string		esurf,	"CreateSurface failed"
string		ewnd, 	"Error setting up window"
string		eddc, 	"DirectDrawCreate failed"
string		eblt, 	"Blt failed"
string		eback, 	"Secondary surface error"
string		escl, 	"SetCooperativeLevel failed"
%ifndef WINDOWED
string		esdm, 	"SetDisplayMode failed"
string		egas,	"GetAttachedSurface failed"
%endif
%endif

section .text

window_title	db "intro", 0

window_class	dd 0				; style
		dd WindowProc			; lpfnWndProc
		dd 0				; cbClsExtra
		dd 0				; cbWndExtra
		dd IMAGE_BASE			; hInstance
		dd 0				; hIcon
		dd 0				; hCursor
		dd 0				; hbrBackground
		dd 0				; lpszMenuName
		dd window_title			; lpszClassName

section .bss

hwnd		resd	1
start_esp	resd	1

section .text

%define	WND_EX_STYLE	byte WS_EX_DLGMODALFRAME
%define	WND_STYLE	dword WS_MINIMIZEBOX | WS_SYSMENU | WS_CAPTION

%define WIDTH	512	; change in intro.h too
%define	HEIGHT 	384
%define BPP	32	; when changing this, change epfbad too

%define FULLSCREEN_BACKBUFFERCOUNT 1		; double buffering

global          _entry_point
_entry_point:
		; we need the return address on the stack so that we can
		; exit nicely using this esp and a ret instruction so there is
		; no need for the ExitProcess import if we don't use API's that
		; spawn threads
		mov	dword [start_esp], esp

; --- window setup ---

		invoke	RegisterClassA, dword window_class
		checkerror {test eax, eax}, z, ewnd

		xor	ebx, ebx
		invoke	CreateWindowExA, WND_EX_STYLE, eax, dword window_title, WND_STYLE, ebx, ebx, ebx, ebx, ebx, ebx, dword IMAGE_BASE, ebx
		checkerror {test eax, eax}, z, ewnd

		mov	ebp, eax
		mov	[hwnd], eax

; *** ebp: window handle
; -----------------------------------------------------------------------------

%ifdef WINDOWED
; --- set window position and size ---
		; calc dimensions for window with WIDTH*HEIGHT client area

		; height
		invoke	GetSystemMetrics, byte SM_CYFIXEDFRAME
		lea	esi, [eax * 2 + HEIGHT]
		invoke	GetSystemMetrics, byte SM_CYCAPTION
		add	esi, eax

		; width
		invoke	GetSystemMetrics, byte SM_CXFIXEDFRAME
		lea	edi, [eax * 2 + WIDTH]

		; start building args for SetWindowPos
		push	byte SWP_SHOWWINDOW
		push	esi
		push	edi

		; now calc the x,y for centering the window
		; edi:esi width:height

		; y
		invoke	GetSystemMetrics, SM_CYSCREEN
		sub	eax, esi
		shr	eax, 1
		push	eax

		; x
		invoke	GetSystemMetrics, SM_CXSCREEN
		sub	eax, edi
		shr	eax, 1
		push	eax

		; push HWND_TOP
                xor	eax, eax
		push	eax

		push	ebp
		call	[SetWindowPos]

		; do a final error check. If hwnd was invalid, SetWindowPos would fail
		; too.
		checkerror {test eax, eax}, z, ewnd
%endif

; -----------------------------------------------------------------------------

%include "ddsetup.asm"
; *** ebp: free

[section .bss]
start_time	resd 1
__SECT__

		invoke	timeGetTime
		mov	[start_time], eax

[section .bss]
msg 		resd 1
__SECT__

		sub	esp, MSG_size
		mov	[msg], esp
MessageLoop:
		invoke	PeekMessageA, dword [msg], 0, 0, 0, byte PM_REMOVE
		test	eax, eax
		jz	short .nomsg
		invoke	DispatchMessageA, dword esp
.nomsg:
%include "render.asm"
%include "blit.asm"
		jmp	MessageLoop

; -----------------------------------------------------------------------------

WindowProc:
%ifndef WINDOWED
		invoke	SetCursor, byte 0
%endif
		cmp	dword [esp+8], WM_DESTROY
		je	.destroy
		jmp	dword [DefWindowProcA]	; parameters still on stack!
.destroy:
		mov	esp, dword [start_esp]
		; this ret terminates the app
		xor	eax, eax
		ret

; -----------------------------------------------------------------------------

%include "procs.asm"