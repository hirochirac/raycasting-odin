package main

import "core:fmt"
import "core:strings"
import "core:math"
import "vendor:sdl2"

HEIGHT :: 460
WIDTH :: HEIGHT * 2
TILE_SIZE :: 32
FOV := math.to_radians_f32(60)

player :: struct {
	x:     f32,
	y:     f32,
	speed: f32,
	a:     f32,
}

ray :: struct {
	distance: f32,
	angle:    f32,
	collided: f32,
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

//rays :: [WIDTH]ray


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
			pRect^.x = f32(x) * TILE_SIZE
			pRect^.y = f32(y) * TILE_SIZE
			pRect^.w = TILE_SIZE - 2.0
			pRect^.h = TILE_SIZE - 2.0
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

init_player :: proc(x: f32, y: f32, speed: f32, a: f32) -> player {
	p: player = {}
	p.x = x
	p.y = y
	p.speed = speed
	p.a = a
	return p
}


draw_player :: proc(p: player, scale: f32, renderer: ^sdl2.Renderer) {
	rectF: sdl2.FRect = {}
	pRect := &rectF
	pRect^.x = p.x * scale - 2.5
	pRect^.y = p.y * scale - 2.5
	pRect^.w = 5
	pRect^.h = 5
	sdl2.SetRenderDrawColor(renderer, 255, 0, 0, 255)
	sdl2.RenderFillRectF(renderer, pRect)
	sdl2.RenderDrawLineF(
		renderer,
		p.x * scale,
		p.y * scale,
		(p.x + (math.cos(p.a) * 20)) * scale,
		(p.y + (math.sin(p.a) * 20)) * scale,
	)
	sdl2.SetRenderDrawColor(renderer, 0, 0, 0, 255)
}

moving_player :: proc(p: player) -> player {

	pl := p
	ptr := &pl

	ptr^.x += math.cos_f32(ptr^.a) * ptr^.speed
	ptr^.y += math.sin_f32(ptr^.a) * ptr^.speed

	return ptr^
}

main :: proc() {

	p: player = init_player(100, 200, 0, math.to_radians_f32(0.0))

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
				if e.type == .KEYDOWN && e.key.keysym.sym == .UP {
					p.speed = 2
				}
				if e.type == .KEYDOWN && e.key.keysym.sym == .DOWN {
					p.speed = -2
				}

				if e.type == .KEYDOWN && e.key.keysym.sym == .LEFT {
					p.a -= .1
				}
				if e.type == .KEYDOWN && e.key.keysym.sym == .RIGHT {
					p.a += .1
				}

				if e.type == .KEYUP && (e.key.keysym.sym == .UP || e.key.keysym.sym == .DOWN) {
					p.speed = 0
				}
			case .MOUSEMOTION:
				p.a = math.to_radians_f32(f32(e.motion.x))
			}

		}

		sdl2.RenderClear(r)
		sdl2.SetRenderDrawColor(r, 0, 0, 0, 255)

		draw_map(l, r)
		p = moving_player(p)
		draw_player(p, .75, r)

		sdl2.RenderPresent(r)

	}

	defer sdl2.DestroyRenderer(r)
	defer sdl2.DestroyWindow(w)
	defer sdl2.Quit()

}
