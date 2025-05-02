package main

import glm "core:math/linalg/glsl"

BALL_RADIUS : f32 = 12.5
INITIAL_BALL_VELOCITY := glm.vec2{100.0, -350.0}

Ball :: struct {
	game_object:  GameObject,
	radius:       f32,
	stuck:        bool,
	sticky:       bool,
	pass_through: bool,
}

ball_create :: proc(
	ball: ^Ball,
	pos: glm.vec2,
	radius: f32,
	sprite: ^Texture2D,
	color: glm.vec3,
	velocity: glm.vec2,
) {
	game_object := GameObject{}
	game_object_create(&game_object, pos, glm.vec2(radius * 2.0), sprite, color, velocity)
	ball.game_object = game_object
	ball.radius = auto_cast BALL_RADIUS
	ball.stuck = true
	ball.sticky = false
	ball.pass_through = false
}

ball_update :: proc(ball: ^Ball, dt: f32, window_width: u32) {
	// if not stuck to player board
	if (!ball.stuck) {
		// move the ball
		ball.game_object.position += ball.game_object.velocity * dt
		// then check if outside window bounds and if so, reverse velocity and
		// restore at correct position
		if (ball.game_object.position.x <= 0.0) {
			ball.game_object.velocity.x = -ball.game_object.velocity.x
			ball.game_object.position.x = 0.0
		} else if (cast(u32)(ball.game_object.position.x + ball.game_object.size.x) >=
			   window_width) {
			ball.game_object.velocity.x = -ball.game_object.velocity.x
			ball.game_object.position.x = cast(f32)window_width - ball.game_object.size.x
		}
		if (ball.game_object.position.y <= 0.0) {
			ball.game_object.velocity.y = -ball.game_object.velocity.y
			ball.game_object.position.y = 0.0
		}
	}
}

// resets the ball to initial Stuck Position (if ball is outside window bounds)
ball_reset :: proc(ball: ^Ball, pos: glm.vec2, velocity: glm.vec2) {
	ball.game_object.position = pos
	ball.game_object.velocity = velocity
	ball.game_object.color = glm.vec3(1.0)
	ball.stuck = true
	ball.sticky = false
	ball.pass_through = false
}
