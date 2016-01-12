#include "intro.h"

#define uint int

struct _face {
	uint v0;
	uint v1;
	uint v2;
	uint col;
};

struct _point {
	uint x;
	uint y;
};

extern struct _point *vertexes_t;

/* draws solid colored triangle on 32 bpp surface
 *
 * edi: surface ptr
 * ebx: pitch
 * WIDTH, HEIGHT
 * ebp, face: _face struct
 * vertexes_t: array of (x,y) where face.v0,v1,v2 are indexes for
 *
 * no mmx
 */

__declspec(naked) void draw_triangle_c_ref_flp_32bpp() {
	uint *surface;
	uint pitch;
	struct _face *face;
	struct _point p0, p1, p2;
	float dxdy1, dxdy2, dy1, dy2;
	float dxdyL, dxdyR;
	uint y;
	float xL, xR;

	__asm {
				push	ebp
				mov		ebp, esp
				sub		esp, __LOCAL_SIZE

				mov		surface, edi
				mov		pitch, ebx
				mov		eax, [ebp]
				mov		face, eax
	}

	p0 = vertexes_t[face->v0];
	p1 = vertexes_t[face->v1];
	p2 = vertexes_t[face->v2];

	/* sort points according to y coordinate */

#define SWAP_POINTS(a,b) do { struct _point temp; temp = a; a = b; b = temp; } while(0)

	if(p1.y < p0.y) SWAP_POINTS(p0,p1);
	if(p2.y < p0.y) SWAP_POINTS(p0,p2);
	if(p2.y < p1.y) SWAP_POINTS(p1,p2);

	/* calc dxdy1 and dxdy2 */

	dy1 = p1.y-p0.y;
	if(dy1 != 0.0) {
		dxdy1 = (p1.x-p0.x) / (dy1+1);
	} else {
		dxdy1 = (p1.x-p0.x); // only paint one half ?!?!?!
	}

	dy2 = p2.y-p0.y;
	if(dy2 != 0.0) {
		dxdy2 = (p2.x-p0.x) / dy2;
	} else {
		dxdy2 = (p2.x-p0.x);
	}

	if(dxdy1<dxdy2) {
		dxdyL = dxdy1;
		dxdyR = dxdy2;
	} else {
		dxdyL = dxdy2;
		dxdyR = dxdy1;
	}

	__asm {
	//			int 3;
	}

	xL = p0.x;
	xR = p0.x;
	for(y=p0.y; y<p1.y; y++) {
		int i,c,col;
		uint *ptr = (uint *)((char *)surface + y * pitch) + (uint)xL;

		xR += dxdyR;

		c = (int)(xR-xL);
		col = face->col;
		for(i=0;i<c;i++) {
			*ptr++ = col;
		}

		xL += dxdyL;
	}

	dxdyR = (p2.x-p1.x) / (p2.y-p1.y+1);
	xR = p1.x + 0.5;

	for(; y<=p2.y; y++) {
		int i,c,col;
		uint *ptr = (uint *)((char *)surface + y * pitch) + (uint)xL;

		c = (int)(xR-xL);
		col = face->col;
		if(c==0) {
			*ptr = col;
		} else {
			for(i=0;i<c;i++) {
				*ptr++ = col;
			}
		}

		xR += dxdyR;
		xL += dxdyL;
	}



	__asm {
				leave
				ret
	}

}