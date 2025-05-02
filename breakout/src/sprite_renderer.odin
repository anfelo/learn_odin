package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

SpriteRenderer :: struct {
	shader:  ^Shader,
	quadVAO: u32,
}

sprite_renderer_create :: proc(sr: ^SpriteRenderer, shader: ^Shader) {
	renderer.shader = shader
	sprite_renderer_init(sr)
}

sprite_renderer_draw_sprite :: proc(
	sr: ^SpriteRenderer,
	texture: ^Texture2D,
	position: ^glm.vec2,
	size: ^glm.vec2,
	rotate: f32,
	color: ^glm.vec3,
) {
	// prepare transformations
	shader_use(sr.shader)

	model := glm.mat4(1.0)
	model *= glm.mat4Translate(glm.vec3{position.x, position.y, 0.0})

	model *= glm.mat4Translate(glm.vec3{0.5 * size.x, 0.5 * size.y, 0.0})
	model *= glm.mat4Rotate(glm.vec3{0.0, 0.0, 1.0}, glm.radians(rotate))
	model *= glm.mat4Translate(glm.vec3{-0.5 * size.x, -0.5 * size.y, 0.0})

	model *= glm.mat4Scale(glm.vec3{size.x, size.y, 1.0})

	gl.UniformMatrix4fv(gl.GetUniformLocation(sr.shader.ID, "model"), 1, false, &model[0][0])
	shader_set_mat4(sr.shader, "model", &model)
	shader_set_vec3(sr.shader, "spriteColor", color)

	texture_bind(texture, gl.GL_Enum.TEXTURE0)

	gl.BindVertexArray(sr.quadVAO)
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
	gl.BindVertexArray(0)
}

sprite_renderer_init :: proc(sr: ^SpriteRenderer) {
	// configure VAO/VBO
	VBO: u32

	// pos      // tex
	vertices := [?]f32 {
		0.0,
		1.0,
		0.0,
		1.0,
		1.0,
		0.0,
		1.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		1.0,
		0.0,
		1.0,
		1.0,
		1.0,
		1.0,
		1.0,
		1.0,
		0.0,
		1.0,
		0.0,
	}

	gl.GenVertexArrays(1, &sr.quadVAO)
	gl.GenBuffers(1, &VBO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	gl.BindVertexArray(sr.quadVAO)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)
}

sr_destroy :: proc(sr: ^SpriteRenderer) {
	gl.DeleteVertexArrays(1, &sr.quadVAO)
}
