package main

import glm "core:math/linalg/glsl"

GameObject :: struct {
    position: glm.vec2,
    size: glm.vec2,
    velocity: glm.vec2,
    color: glm.vec3,
    rotation: f32,
    is_solid: bool,
    destroyed: bool,
    sprite: ^Texture2D,
}

game_object_create :: proc(game_object: ^GameObject, pos: glm.vec2,
                         size: glm.vec2, sprite: ^Texture2D,
                         color := glm.vec3(1.0),
                         velocity := glm.vec2(0.0)) {
    game_object.position = pos
    game_object.size = size
    game_object.velocity = velocity
    game_object.color = color
    game_object.rotation = 0.0
    game_object.is_solid = false
    game_object.destroyed = false
    game_object.sprite = sprite
}

game_object_draw :: proc(renderer: ^SpriteRenderer, game_object: ^GameObject) {
    sprite_renderer_draw_sprite(renderer, game_object.sprite, &game_object.position,
                   &game_object.size, game_object.rotation,
                   &game_object.color);
}
