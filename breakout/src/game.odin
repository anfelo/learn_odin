package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

GameState :: enum {
	GameActive,
	GameMenu,
	GameWin,
}

Game :: struct {
	state:         GameState,
	keys:          [1024]bool,
	width, height: u32,
	levels:        [dynamic]GameLevel,
	level:         u32,
	player:        GameObject,
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
	rm_load_texture(
		&resources,
		"./resources/textures/background.jpg",
		gl.GL_Enum.RGB,
		"background",
	)
	rm_load_texture(&resources, "./resources/textures/awesomeface.png", gl.GL_Enum.RGBA, "face")
	rm_load_texture(&resources, "./resources/textures/block.png", gl.GL_Enum.RGB, "block")
	rm_load_texture(
		&resources,
		"./resources/textures/block_solid.png",
		gl.GL_Enum.RGB,
		"block_solid",
	)
	rm_load_texture(&resources, "./resources/textures/paddle.png", gl.GL_Enum.RGBA, "paddle")

	// load levels
	one := GameLevel{}
	game_level_load(&resources, &one, "./resources/levels/one.lvl", game.width, game.height / 2)
	two := GameLevel{}
	game_level_load(&resources, &two, "./resources/levels/two.lvl", game.width, game.height / 2)
	three := GameLevel{}
	game_level_load(
		&resources,
		&three,
		"./resources/levels/three.lvl",
		game.width,
		game.height / 2,
	)
	four := GameLevel{}
	game_level_load(&resources, &four, "./resources/levels/four.lvl", game.width, game.height / 2)

	append(&game.levels, one)
	append(&game.levels, two)
	append(&game.levels, three)
	append(&game.levels, four)
	game.level = 0

	// Init player paddle
	player := GameObject{}
	player_size := glm.vec2{100.0, 20.0}
	player_velocity: f32 = 500.0
	player_pos := glm.vec2 {
		cast(f32)game.width / 2.0 - cast(f32)player_size.x / 2.0,
		cast(f32)game.height - cast(f32)player_size.y,
	}
	if player_tex, ok := rm_get_texture(&resources, "paddle"); ok {
		game_object_create(
			&player,
			player_pos,
			player_size,
			player_tex,
			glm.vec3{1.0, 1.0, 1.0},
			glm.vec2{player_velocity, 0.0},
		)
	}
	game.player = player
}

game_process_input :: proc(game: ^Game, dt: f32) {
	if (game.state == GameState.GameActive) {
		velocity: f32 = game.player.velocity.x * dt
		// move playerboard
		if (game.keys[glfw.KEY_A] || game.keys[glfw.KEY_LEFT]) {
			if (game.player.position.x >= 0.0) {
				game.player.position.x -= velocity
				// if (game.ball.stuck) {
				// 	game.ball.game_object.position.x -= velocity
				// }
			}
		}
		if (game.keys[glfw.KEY_D] || game.keys[glfw.KEY_RIGHT]) {
			if (cast(u32)game.player.position.x <= game.width - cast(u32)game.player.size.x) {
				game.player.position.x += velocity
				// if (game.ball.stuck) {
				// 	game.ball.game_object.position.x += velocity
				// }
			}
		}
		if (game.keys[glfw.KEY_SPACE]) {
			// game.ball.stuck = false
		}
	}
}

game_update :: proc(game: ^Game) {
}

game_draw :: proc(game: ^Game) {
	if (game.state == GameState.GameActive) {
		// draw background
		if bg_texture, ok := rm_get_texture(&resources, "background"); ok {
			sprite_renderer_draw_sprite(
				&renderer,
				bg_texture,
				&glm.vec2{0.0, 0.0},
				&glm.vec2{cast(f32)game.width, cast(f32)game.height},
				0.0,
				&glm.vec3{1.0, 1.0, 1.0},
			)
		}

		// draw level
		game_level_draw(&renderer, &game.levels[game.level])

		// player
		game_object_draw(&renderer, &game.player)
	}
}

game_delete :: proc(game: ^Game) {
	rm_clear_resources(&resources)
}
