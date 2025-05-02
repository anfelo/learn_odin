package main

import glm "core:math/linalg/glsl"
import "core:math/rand"
import gl "vendor:OpenGL"

Particle :: struct {
	position: glm.vec2,
	velocity: glm.vec2,
	color:    glm.vec4,
	life:     f32,
}

ParticleGenerator :: struct {
	// state
	particles:          [dynamic]Particle,
	amount:             u32,
	last_used_particle: u32,

	// render state
	shader:             ^Shader,
	texture:            ^Texture2D,
	vao:                u32,
}

particle_create :: proc(particle: ^Particle) {
	particle.position = glm.vec2(0.0)
	particle.velocity = glm.vec2(0.0)
	particle.color = glm.vec4(1.0)
	particle.life = 0.0
}

particle_generator_create :: proc(
	pg: ^ParticleGenerator,
	shader: ^Shader,
	texture: ^Texture2D,
	amount: u32,
) {
	pg.shader = shader
	pg.texture = texture
	pg.amount = amount
	particle_generator_init(pg)
}

particle_generator_update :: proc(
	pg: ^ParticleGenerator,
	dt: f32,
	object: ^GameObject,
	new_particles: u32,
	offset: glm.vec2,
) {
	for i: u32 = 0; i < new_particles; i += 1 {
		unused_particle := first_unused_particle(pg)
		respawn_particle(&pg.particles[unused_particle], object, offset)
	}

	// update all particles
	for i: u32 = 0; i < pg.amount; i += 1 {
		p := &pg.particles[i]
		p.life -= dt
		if (p.life > 0.0) {
			p.position -= p.velocity * dt
			p.color.a -= dt * 2.5
		}
	}
}

particle_generator_draw :: proc(pg: ^ParticleGenerator) {
	// use additive blending to give it a glow effect
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE)
	shader_use(pg.shader)
	for &particle in pg.particles {
		if (particle.life > 0.0) {
			shader_set_vec2(pg.shader, "u_offset", &particle.position)
			shader_set_vec4(pg.shader, "u_color", &particle.color)

			texture_bind(pg.texture, gl.GL_Enum.TEXTURE0)

			gl.BindVertexArray(pg.vao)
			gl.DrawArrays(gl.TRIANGLES, 0, 6)
			gl.BindVertexArray(0)
		}
	}
	// don't forget to rest to default blending mode
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
}

particle_generator_init :: proc(pg: ^ParticleGenerator) {
	// configure VAO/VBO
	VBO: u32
	particle_quad := [?]f32 {
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

	gl.GenVertexArrays(1, &pg.vao)
	gl.GenBuffers(1, &VBO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(particle_quad), &particle_quad, gl.STATIC_DRAW)

	gl.BindVertexArray(pg.vao)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	// create this->amount default particle instances
	pg.last_used_particle = 0
	for i: u32 = 0; i < pg.amount; i += 1 {
		particle := Particle{}
		particle_create(&particle)
		append(&pg.particles, particle)
	}

}

first_unused_particle :: proc(pg: ^ParticleGenerator) -> u32 {
	// first search from last used particle, this will usually return almost
	// instantly
	for i: u32 = pg.last_used_particle; i < pg.amount; i += 1 {
		if (pg.particles[i].life <= 0.0) {
			pg.last_used_particle = i
			return i
		}
	}

	// otherwise, do a linear search
	for i: u32 = 0; i < pg.last_used_particle; i += 1 {
		if (pg.particles[i].life <= 0.0) {
			pg.last_used_particle = i
			return i
		}
	}

	// all particles are taken, override the first one (not that if it
	// repeatedly hits this case, more particles should be reserved)
	pg.last_used_particle = 0
	return 0
}

respawn_particle :: proc(particle: ^Particle, object: ^GameObject, offset: glm.vec2) {
	random := ((rand.uint32() % 100) - 50) / 10.0
	r_color := 0.5 + cast(f32)((rand.uint32() % 100) / 100.0)
	particle.position = object.position + glm.vec2(random) + offset
	particle.color = glm.vec4{r_color, r_color, r_color, 1.0}
	particle.life = 1.0
	particle.velocity = object.velocity * 0.1
}
