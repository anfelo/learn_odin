package main

import glm "core:math/linalg/glsl"

POWERUP_SIZE :: glm.vec2{60.0, 20.0}
POWERUP_VELOCITY :: glm.vec2{0.0, 150.0}

PowerUp :: struct {
	game_object: GameObject,
	// powerup state
	type:        string,
	duration:    f32,
	activated:   bool,
}

powerup_create :: proc(
	powerup: ^PowerUp,
	type: string,
	color: glm.vec3,
	duration: f32,
	position: glm.vec2,
	texture: ^Texture2D,
) {
	game_object := GameObject{}
	game_object_create(&game_object, position, POWERUP_SIZE, texture, color, POWERUP_VELOCITY)
	powerup.game_object = game_object
	powerup.type = type
	powerup.duration = duration
	powerup.activated = false
}
