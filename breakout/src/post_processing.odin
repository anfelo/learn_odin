package main

import "core:fmt"
import gl "vendor:OpenGL"

// PostProcessor hosts all PostProcessing effects for the Breakout
// Game. It renders the game on a textured quad after which one can
// enable specific effects by enabling either the confuse, chaos or
// shake boolean.
// It is required to call begin_render() before rendering the game
// and end_render() after rendering the game for the class to work.
PostProcessor :: struct {
	shader:                ^Shader,
	texture:               Texture2D,
	width, height:         u32,
	confuse, chaos, shake: bool,
	// render state
	MSFBO, FBO:            u32, // MSFBO = Multisampled FBO. FBO is regular, used
	// for blitting MS color-buffer to texture
	RBO:                   u32, // RBO is used for multisampled color buffer
	VAO:                   u32,
}

post_processor_create :: proc(
	post_processor: ^PostProcessor,
	shader: ^Shader,
	width: u32,
	height: u32,
) {
	texture := Texture2D{}
	texture_create(&texture)
	post_processor.texture = texture

	post_processor.shader = shader
	post_processor.width = width
	post_processor.height = height

	post_processor.confuse = false
	post_processor.shake = false
	post_processor.chaos = false

	// initialize renderbuffer/framebuffer object
	gl.GenFramebuffers(1, &post_processor.MSFBO)
	gl.GenFramebuffers(1, &post_processor.FBO)
	gl.GenRenderbuffers(1, &post_processor.RBO)
	// initialize renderbuffer storage with a multisampled color buffer (don't
	// need a depth/stencil buffer)
	gl.BindFramebuffer(gl.FRAMEBUFFER, post_processor.MSFBO)
	gl.BindRenderbuffer(gl.RENDERBUFFER, post_processor.RBO)
	gl.RenderbufferStorageMultisample(
		gl.RENDERBUFFER,
		4,
		auto_cast gl.GL_Enum.RGB,
		auto_cast width,
		auto_cast height,
	) // allocate storage for render buffer object
	gl.FramebufferRenderbuffer(
		gl.FRAMEBUFFER,
		gl.COLOR_ATTACHMENT0,
		gl.RENDERBUFFER,
		post_processor.RBO,
	) // attach MS render buffer object to framebuffer
	if (gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE) {
		fmt.println("ERROR::POSTPROCESSOR: Failed to initialize MSFBO")
	}
	// also initialize the FBO/texture to blit multisampled color-buffer to
	// used for shader operations (for postprocessing effects)
	gl.BindFramebuffer(gl.FRAMEBUFFER, post_processor.FBO)
	texture_generate(&post_processor.texture, auto_cast width, auto_cast height, nil)
	gl.FramebufferTexture2D(
		gl.FRAMEBUFFER,
		gl.COLOR_ATTACHMENT0,
		gl.TEXTURE_2D,
		post_processor.texture.ID,
		0,
	) // attach texture to framebuffer as its color attachment
	if (gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE) {
		fmt.println("ERROR::POSTPROCESSOR: Failed to initialize FBO")
	}
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	// initialize render data and uniforms
	post_processor_init_render_data(post_processor)
	shader_use(post_processor.shader)
	shader_set_int(post_processor.shader, "scene", 0)
	offset: f32 = 1.0 / 300.0
	offsets := [9][2]f32 {
		{-offset, offset}, // top-left
		{0.0, offset}, // top-center
		{offset, offset}, // top-right
		{-offset, 0.0}, // center-left
		{0.0, 0.0}, // center-center
		{offset, 0.0}, // center - right
		{-offset, -offset}, // bottom-left
		{0.0, -offset}, // bottom-center
		{offset, -offset}, // bottom-right
	}
	gl.Uniform2fv(gl.GetUniformLocation(post_processor.shader.ID, "offsets"), 9, &offsets[0][0])
	edge_kernel := [9]i32{-1, -1, -1, -1, 8, -1, -1, -1, -1}
	gl.Uniform1iv(
		gl.GetUniformLocation(post_processor.shader.ID, "edge_kernel"),
		9,
		&edge_kernel[0],
	)
	blur_kernel := [9]f32 {
		1.0 / 16.0,
		2.0 / 16.0,
		1.0 / 16.0,
		2.0 / 16.0,
		4.0 / 16.0,
		2.0 / 16.0,
		1.0 / 16.0,
		2.0 / 16.0,
		1.0 / 16.0,
	}
	gl.Uniform1fv(
		gl.GetUniformLocation(post_processor.shader.ID, "blur_kernel"),
		9,
		&blur_kernel[0],
	)
}

post_processor_begin_render :: proc(post_processor: ^PostProcessor) {
	gl.BindFramebuffer(gl.FRAMEBUFFER, post_processor.MSFBO)
	gl.ClearColor(0.0, 0.0, 0.0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

post_processor_end_render :: proc(post_processor: ^PostProcessor) {
	// now resolve multisampled color-buffer into intermediate FBO to store to
	// texture
	gl.BindFramebuffer(gl.READ_FRAMEBUFFER, post_processor.MSFBO)
	gl.BindFramebuffer(gl.DRAW_FRAMEBUFFER, post_processor.FBO)
	gl.BlitFramebuffer(
		0,
		0,
		auto_cast post_processor.width,
		auto_cast post_processor.height,
		0,
		0,
		auto_cast post_processor.width,
		auto_cast post_processor.height,
		gl.COLOR_BUFFER_BIT,
		gl.NEAREST,
	)
	// binds both READ and WRITE framebuffer to default framebuffer
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}

post_processor_render :: proc(post_processor: ^PostProcessor, time: f32) {
	// set uniforms/options
	shader_use(post_processor.shader)
	shader_set_float(post_processor.shader, "time", time)
	shader_set_int(post_processor.shader, "confuse", auto_cast post_processor.confuse)
	shader_set_int(post_processor.shader, "chaos", auto_cast post_processor.chaos)
	shader_set_int(post_processor.shader, "shake", auto_cast post_processor.shake)

	// render textured quad
	gl.ActiveTexture(auto_cast gl.GL_Enum.TEXTURE0)
	texture_bind(&post_processor.texture, gl.GL_Enum.TEXTURE0)
	gl.BindVertexArray(post_processor.VAO)
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
	gl.BindVertexArray(0)
}

post_processor_init_render_data :: proc(post_processor: ^PostProcessor) {
	// configure VAO/VBO
	VBO: u32
	vertices := [?]f32 { 	// pos        // tex
		-1.0,
		-1.0,
		0.0,
		0.0,
		1.0,
		1.0,
		1.0,
		1.0,
		-1.0,
		1.0,
		0.0,
		1.0,
		-1.0,
		-1.0,
		0.0,
		0.0,
		1.0,
		-1.0,
		1.0,
		0.0,
		1.0,
		1.0,
		1.0,
		1.0,
	}
	gl.GenVertexArrays(1, &post_processor.VAO)
	gl.GenBuffers(1, &VBO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	gl.BindVertexArray(post_processor.VAO)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)
}
