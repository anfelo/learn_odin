package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

GameState :: enum {
	GameActive,
	GameMenu,
	GameWin,
}

Game :: struct {
	state:         GameState,
	keys:          [1024]bool,
	width, height: u32,
}

resources := ResourceManager{}
renderer := SpriteRenderer{}

game_init :: proc(game: ^Game) {
	// load shaders
	rm_load_shader(
		&resources,
		"./resources/shaders/sprite.vert",
		"./resources/shaders/sprite.frag",
		"sprite",
	)

	// configure shaders
	projection := glm.mat4Ortho3d(0.0, cast(f32)game.width, cast(f32)game.height, 0.0, -1.0, 1.0)

	sprite_shader := rm_get_shader(&resources, "sprite")
	shader_use(sprite_shader)
	shader_set_int(sprite_shader, "image", 0)
	shader_set_mat4(sprite_shader, "projection", &projection)

	sprite_renderer_create(&renderer, rm_get_shader(&resources, "sprite"))

	// load textures
	rm_load_texture(&resources, "./resources/textures/awesomeface.png", gl.GL_Enum.RGBA, "face")
}

game_process_input :: proc(game: ^Game) {
}

game_update :: proc(game: ^Game) {
}

game_draw :: proc(game: ^Game) {
	if texture, ok := rm_get_texture(&resources, "face"); ok {
		sprite_renderer_draw_sprite(
			&renderer,
			texture,
			&glm.vec2{200.0, 200.0},
			&glm.vec2{300.0, 400.0},
			45.0,
			&glm.vec3{0.0, 1.0, 0.0},
		)
	}
}

game_delete :: proc(game: ^Game) {
	rm_clear_resources(&resources)
}
