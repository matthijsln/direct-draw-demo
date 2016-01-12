ASM_FILES = mainloop.asm 
C_FILES = draw_triangle_c.c
C_OBJ_FILES = $(C_FILES:.c=.obj)
OBJ_FILES = $(ASM_FILES:.asm=.obj) $(C_OBJ_FILES)
INCLUDE_DIR = ..\\asminclude
EXE = intro.exe

# ---

_NASM = nasmw
NASM_FLAGS = -f win32 -O1000 -w+orphan-labels -I$(INCLUDE_DIR)

LINK = link
CL = cl
CFLAGS = /nologo /QIfist
LIB_FILES = user32.lib ddraw.lib msvcrt.lib kernel32.lib winmm.lib gdi32.lib
LINK_MERGE = /merge:.data=.text /merge:.rdata=.text 
LINK_FLAGS = /nologo /opt:ref /out:$(EXE) /entry:entry_point $(LINK_MERGE) /align:4096 /section:.text,erw /subsystem:windows $(OBJ_FILES) $(LIB_FILES)

# ---

all: $(C_OBJ_FILES)
	$(_NASM) $(NASM_FLAGS) $(ASM_FILES)
	$(LINK) $(LINK_FLAGS) 

clean:
  -del /q *.obj $(EXE)
