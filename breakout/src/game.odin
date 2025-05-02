package main

import "core:fmt"
import "core:math"
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
	ball:          Ball,
}

// Represents the four possible (collision) directions
Direction :: enum {
	Up,
	Right,
	Down,
	Left,
}
// Defines a Collision struct that represents collision data
Collision :: struct {
	collided:  bool,
	direction: Direction,
	diff_vec:  glm.vec2, // difference vector center - closest point
}

resources := ResourceManager{}
renderer := SpriteRenderer{}
particles := ParticleGenerator{}

shake_time: f32 = 0.0

game_init :: proc(game: ^Game) {
	// load shaders
	rm_load_shader(
		&resources,
		"./resources/shaders/sprite.vert",
		"./resources/shaders/sprite.frag",
		"sprite",
	)
	rm_load_shader(
		&resources,
		"./resources/shaders/particle.vert",
		"./resources/shaders/particle.frag",
		"particle",
	)
	rm_load_shader(
		&resources,
		"./resources/shaders/post_processing.vert",
		"./resources/shaders/post_processing.frag",
		"post_processing",
	)

	// configure shaders
	projection := glm.mat4Ortho3d(0.0, cast(f32)game.width, cast(f32)game.height, 0.0, -1.0, 1.0)

	sprite_shader := rm_get_shader(&resources, "sprite")
	shader_use(sprite_shader)
	shader_set_int(sprite_shader, "image", 0)
	shader_set_mat4(sprite_shader, "projection", &projection)

	particle_shader := rm_get_shader(&resources, "particle")
	shader_use(particle_shader)
	shader_set_int(particle_shader, "u_sprite", 0)
	shader_set_mat4(particle_shader, "u_projection", &projection)

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
	rm_load_texture(&resources, "./resources/textures/particle.png", gl.GL_Enum.RGBA, "particle")
	rm_load_texture(
		&resources,
		"./resources/textures/powerup_speed.png",
		gl.GL_Enum.RGBA,
		"powerup_speed",
	)
	rm_load_texture(
		&resources,
		"./resources/textures/powerup_sticky.png",
		gl.GL_Enum.RGBA,
		"powerup_sticky",
	)
	rm_load_texture(
		&resources,
		"./resources/textures/powerup_increase.png",
		gl.GL_Enum.RGBA,
		"powerup_increase",
	)
	rm_load_texture(
		&resources,
		"./resources/textures/powerup_confuse.png",
		gl.GL_Enum.RGBA,
		"powerup_confuse",
	)
	rm_load_texture(
		&resources,
		"./resources/textures/powerup_chaos.png",
		gl.GL_Enum.RGBA,
		"powerup_chaos",
	)
	rm_load_texture(
		&resources,
		"./resources/textures/powerup_passthrough.png",
		gl.GL_Enum.RGBA,
		"powerup_passthrough",
	)

	sprite_renderer_create(&renderer, sprite_shader)

	particle_tex, _ := rm_get_texture(&resources, "particle")
	particle_generator_create(&particles, particle_shader, particle_tex, 500)

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

	// Init ball object
	ball := Ball{}
	ball_pos := player_pos + glm.vec2{player.size.x / 2.0 - BALL_RADIUS, -BALL_RADIUS * 2.0}
	ball_velocity := INITIAL_BALL_VELOCITY
	if ball_tex, ok := rm_get_texture(&resources, "face"); ok {
		ball_create(&ball, ball_pos, BALL_RADIUS, ball_tex, glm.vec3(1.0), ball_velocity)
	}
	game.ball = ball
}

game_process_input :: proc(game: ^Game, dt: f32) {
	if (game.state == GameState.GameActive) {
		velocity: f32 = game.player.velocity.x * dt
		// move playerboard
		if (game.keys[glfw.KEY_A] || game.keys[glfw.KEY_LEFT]) {
			if (game.player.position.x >= 0.0) {
				game.player.position.x -= velocity
				if (game.ball.stuck) {
					game.ball.game_object.position.x -= velocity
				}
			}
		}
		if (game.keys[glfw.KEY_D] || game.keys[glfw.KEY_RIGHT]) {
			if (cast(u32)game.player.position.x <= game.width - cast(u32)game.player.size.x) {
				game.player.position.x += velocity
				if (game.ball.stuck) {
					game.ball.game_object.position.x += velocity
				}
			}
		}
		if (game.keys[glfw.KEY_SPACE]) {
			game.ball.stuck = false
		}
	}
}

game_update :: proc(game: ^Game, dt: f32) {
	ball_update(&game.ball, dt, game.width)

	game_do_collisions(game)

	// update particles
	particle_generator_update(
		&particles,
		dt,
		&game.ball.game_object,
		2,
		glm.vec2(game.ball.radius / 2.0),
	)

	// game_update_powerups(game, dt);

	// reduce shake time
	// if (shake_time > 0.0f) {
	//     shake_time -= dt;
	//     if (shake_time <= 0.0f) {
	//         game->effects->shake = false;
	//     }
	// }

	// check loss condition
	if (cast(u32)game.ball.game_object.position.y >= game.height) {
		game_reset_level(game)
		game_reset_player(game)
	}
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

		// particles (particles are on top of all the other objects but
		// below the ball)
		particle_generator_draw(&particles)

		// ball
		game_object_draw(&renderer, &game.ball.game_object)
	}
}

game_delete :: proc(game: ^Game) {
	rm_clear_resources(&resources)
}

game_reset_level :: proc(game: ^Game) {
	if (game.level == 0) {
		game_level_load(
			&resources,
			&game.levels[0],
			"./resources/levels/one.lvl",
			game.width,
			game.height / 2,
		)
	} else if (game.level == 1) {
		game_level_load(
			&resources,
			&game.levels[1],
			"./resources/levels/two.lvl",
			game.width,
			game.height / 2,
		)
	} else if (game.level == 2) {
		game_level_load(
			&resources,
			&game.levels[2],
			"./resources/levels/three.lvl",
			game.width,
			game.height / 2,
		)
	} else if (game.level == 3) {
		game_level_load(
			&resources,
			&game.levels[3],
			"./resources/levels/four.lvl",
			game.width,
			game.height / 2,
		)
	}
}

game_reset_player :: proc(game: ^Game) {
	// reset player/ball stats
	game.player.size = glm.vec2{100.0, 20.0}
	game.player.position = glm.vec2 {
		cast(f32)game.width / 2.0 - game.player.size.x / 2.0,
		cast(f32)game.height - game.player.size.y,
	}
	game.player.color = glm.vec3(1.0)

	ball_pos :=
		game.player.position +
		glm.vec2{game.player.size.x / 2.0 - BALL_RADIUS, -(BALL_RADIUS * 2.0)}
	ball_reset(&game.ball, ball_pos, INITIAL_BALL_VELOCITY)
}

// collisions

game_do_collisions :: proc(game: ^Game) {
	for &box in game.levels[game.level].bricks {
		if (!box.destroyed) {
			collision := check_collision_AABB_circle(game.ball, box)
			if (collision.collided) {
				// destroy block if not solid
				if (!box.is_solid) {
					box.destroyed = true
					// TODO: implement
					// game_spawn_powerups(game, &box)
				} else {
					// TODO: implement
					// shake_time = 0.05
					// game.effects.shake = true
				}
				// collision resolution
				dir := collision.direction
				diff_vector := collision.diff_vec
				// don't do collision resolution on non-solid bricks if
				// pass-through is activated
				if (!(game.ball.pass_through && !box.is_solid)) {
					// horizontal collision
					if (dir == Direction.Left || dir == Direction.Right) {
						// reverse horizontal velocity
						game.ball.game_object.velocity.x = -game.ball.game_object.velocity.x
						// relocate
						penetration := game.ball.radius - math.abs(diff_vector.x)
						if (dir == Direction.Left) {
							// move ball to right
							game.ball.game_object.position.x += penetration
						} else {
							// move ball to left;
							game.ball.game_object.position.x -= penetration
						}
					} else {
						// vertical collision
						// reverse vertical velocity
						game.ball.game_object.velocity.y = -game.ball.game_object.velocity.y
						// relocate
						penetration := game.ball.radius - math.abs(diff_vector.y)
						if (dir == Direction.Up) {
							// move ball back up
							game.ball.game_object.position.y -= penetration
						} else {
							// move ball back down
							game.ball.game_object.position.y += penetration
						}
					}
				}
			}
		}
	}

	// TODO: implement
	// for (powerup_t &powerup : game->powerups) {
	//     if (!powerup.game_object.destroyed) {
	//         if (powerup.game_object.position.y >= game->height) {
	//             powerup.game_object.destroyed = true;
	//         }
	//
	//         // collided with player, now activate powerup
	//         if (check_collision_AABB_AABB(game->player, powerup.game_object)) {
	//             game_activate_powerup(game, &powerup);
	//             powerup.game_object.destroyed = true;
	//             powerup.activated = true;
	//         }
	//     }
	// }

	// check collisions for player pad (unless stuck)
	result := check_collision_AABB_circle(game.ball, game.player)
	if (!game.ball.stuck && result.collided) {
		// check where it hit the board, and change velocity based on where it
		// hit the board
		center_board := game.player.position.x + game.player.size.x / 2.0
		distance := (game.ball.game_object.position.x + game.ball.radius) - center_board
		percentage := distance / (game.player.size.x / 2.0)
		// then move accordingly
		strength: f32 = 2.0
		old_velocity := game.ball.game_object.velocity
		game.ball.game_object.velocity.x = INITIAL_BALL_VELOCITY.x * percentage * strength
		game.ball.game_object.velocity =
			glm.normalize(game.ball.game_object.velocity) * glm.length(old_velocity) // keep speed consistent over both axes// (multiply by length of old velocity, so// total strength is not changed)
		// fix sticky paddle
		game.ball.game_object.velocity.y = -1.0 * math.abs(game.ball.game_object.velocity.y)

		// if Sticky powerup is activated, also stick ball to paddle once new
		// velocity vectors were calculated
		game.ball.stuck = game.ball.sticky
	}
}

// AABB - AABB collision
check_collision_AABB_AABB :: proc(one: GameObject, two: GameObject) -> bool {
	// collision x-axis?
	collision_x :=
		one.position.x + one.size.x >= two.position.x &&
		two.position.x + two.size.x >= one.position.x
	// collision y-axis?
	collision_y :=
		one.position.y + one.size.y >= two.position.y &&
		two.position.y + two.size.y >= one.position.y
	// collision only if on both axes
	return collision_x && collision_y
}

// AABB - Circle collision
check_collision_AABB_circle :: proc(one: Ball, two: GameObject) -> Collision {
	// get center point circle first
	center := glm.vec2(one.game_object.position + one.radius)
	// calculate AABB info (center, half-extents)
	aabb_half_extents := glm.vec2{two.size.x / 2.0, two.size.y / 2.0}
	aabb_center := glm.vec2 {
		two.position.x + aabb_half_extents.x,
		two.position.y + aabb_half_extents.y,
	}
	// get difference vector between both centers
	difference := center - aabb_center
	clamped := glm.clamp(difference, -aabb_half_extents, aabb_half_extents)
	// add clamped value to AABB_center and we get the value of box closest to
	// circle
	closest := aabb_center + clamped
	// retrieve vector between center circle and closest point AABB and check if
	// length <= radius
	difference = closest - center

	// not <= since in that case a collision also occurs when
	// object one exactly touches object two, which they are at
	// the end of each collision resolution stage.
	if (glm.length(difference) < one.radius) {
		return Collision{true, vector_direction(difference), difference}
	} else {
		return Collision{false, Direction.Up, glm.vec2(0.0)}
	}
}

// calculates which direction a vector is facing (N,E,S or W)
vector_direction :: proc(target: glm.vec2) -> Direction {
	compass := [?]glm.vec2 {
		glm.vec2{0.0, 1.0}, // up
		glm.vec2{1.0, 0.0}, // right
		glm.vec2{0.0, -1.0}, // down
		glm.vec2{-1.0, 0.0}, // left
	}
	max: f32 = 0.0
	best_match: i32 = -1
	for i := 0; i < 4; i += 1 {
		dot_product := glm.dot(glm.normalize(target), compass[i])
		if (dot_product > max) {
			max = dot_product
			best_match = auto_cast i
		}
	}
	return auto_cast best_match
}
