package main

import "core:fmt"
import "core:strings"
import "core:math"
import "vendor:sdl2"

HEIGHT :: 460
WIDTH :: HEIGHT * 2
TITLE_SIZE :: 32

player :: struct {
	x: f32,
	y: f32,
	a: f32,
}


get_id_backen :: proc(name: string) -> i32 {

	backend_id: i32 = -1
	info: sdl2.RendererInfo

	if n := sdl2.GetNumRenderDrivers(); n <= 0 {
		fmt.eprintln("No render drivers available")
		backend_id = -1
	} else {
		for i in 0 ..< n {
			if err := sdl2.GetRenderDriverInfo(i, &info); err == 0 {
				if name == string(info.name) {
					backend_id = i
				}
			}
		}
	}

	return backend_id
}

/**
**/
draw_map :: proc(t: [8][8]int, renderer: ^sdl2.Renderer) {

	rect: sdl2.FRect = {}
	pRect := &rect
	y: i32 = 0
	x: i32 = 0
	for y in 0 ..< len(t) {
		for x in 0 ..< len(t[y]) {
			pRect^.x = f32(x) * TITLE_SIZE
			pRect^.y = f32(y) * TITLE_SIZE
			pRect^.w = TITLE_SIZE - 2.0
			pRect^.h = TITLE_SIZE - 2.0
			if t[y][x] == 1 {
				sdl2.SetRenderDrawColor(renderer, 117, 117, 117, 255)
			} else {
				sdl2.SetRenderDrawColor(renderer, 200, 200, 200, 255)
			}
			sdl2.RenderFillRectF(renderer, pRect)
			sdl2.SetRenderDrawColor(renderer, 0, 0, 0, 255)
		}
	}


}

init_player :: proc(x: f32, y: f32, a: f32) -> player {
	p: player = {}
	p.x = x
	p.y = y
	p.a = a
	return p
}


draw_player :: proc(p: player, renderer: ^sdl2.Renderer) {
	rectF: sdl2.FRect = {}
	pRect := &rectF
	pRect^.x = p.x
	pRect^.y = p.y
	pRect^.w = 5
	pRect^.h = 5
	sdl2.SetRenderDrawColor(renderer, 255, 0, 0, 255)
	sdl2.RenderFillRectF(renderer, pRect)
	sdl2.SetRenderDrawColor(renderer, 0, 0, 0, 255)
}

moving_player :: proc(p: player, e: sdl2.Event) -> player {

	pl := p
	ptr := &pl

	if (e.type == .KEYUP) {
		if (e.key.keysym.sym == .LEFT) {
			ptr^.x = ptr^.x - 5
		} else if (e.key.keysym.sym == .RIGHT) {
			ptr^.x = ptr^.x + 5
		}
	}

	return ptr^
}


l :: [8][8]int{
	{1, 1, 1, 1, 1, 1, 1, 1},
	{1, 0, 1, 0, 0, 0, 0, 1},
	{1, 0, 1, 0, 0, 0, 1, 1},
	{1, 0, 0, 0, 0, 0, 0, 1},
	{1, 0, 0, 0, 1, 1, 1, 1},
	{1, 0, 0, 0, 1, 0, 0, 1},
	{1, 0, 0, 0, 0, 0, 0, 1},
	{1, 1, 1, 1, 1, 1, 1, 1},
}


main :: proc() {

	p: player = init_player(100, 200, math.to_radians_f32(90.0))

	if i := sdl2.Init(sdl2.INIT_EVERYTHING); i != 0 {
		fmt.eprintln(sdl2.GetError())
		return
	}


	w := sdl2.CreateWindow(
		"Raycasting",
		sdl2.WINDOWPOS_CENTERED,
		sdl2.WINDOWPOS_CENTERED,
		WIDTH,
		HEIGHT,
		sdl2.WINDOW_SHOWN,
	)

	if w == nil {
		fmt.eprintln(sdl2.GetError())
		return
	}


	r := sdl2.CreateRenderer(
		w,
		get_id_backen("opengl"),
		sdl2.RENDERER_ACCELERATED | sdl2.RENDERER_PRESENTVSYNC,
	)

	if r == nil {
		fmt.eprintln(sdl2.GetError())
		return
	}

	main_loop: for {

		for e: sdl2.Event; sdl2.PollEvent(&e) != 0; {
			#partial switch e.type {
			case .QUIT:
				break main_loop
			case .KEYDOWN, .KEYUP:
				if e.type == .KEYUP && e.key.keysym.sym == .ESCAPE {
					sdl2.PushEvent(&sdl2.Event{type = .QUIT})
				}
			}
			p = moving_player(p, e)
		}

		sdl2.RenderClear(r)
		sdl2.SetRenderDrawColor(r, 0, 0, 0, 255)

		draw_map(l, r)
		draw_player(p, r)

		sdl2.RenderPresent(r)

	}

	defer sdl2.DestroyRenderer(r)
	defer sdl2.DestroyWindow(w)
	defer sdl2.Quit()

}
