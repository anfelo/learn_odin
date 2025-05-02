package main

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"

// Vertex shader source
vertex_shader_source := `#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in vec3 color;
out vec3 vertexColor;

void main() {
    gl_Position = vec4(position, 1.0);
    vertexColor = color;
}
`


// Fragment shader source
fragment_shader_source := `#version 330 core
in vec3 vertexColor;
out vec4 fragColor;

void main() {
    fragColor = vec4(vertexColor, 1.0);
}
`


// Triangle vertices with positions and colors
vertices := [?]f32 {
	// Positions     // Colors
	-0.5, -0.5, 0.0, 1.0, 0.0, 0.0, // bottom left, red
	0.5, -0.5, 0.0, 0.0, 1.0, 0.0, // bottom right, green
	0.0, 0.5, 0.0, 0.0, 0.0, 1.0, // top, blue
}

main :: proc() {
	// Initialize GLFW
	if !glfw.Init() {
		fmt.println("Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	// Set required OpenGL version and profile
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	// Create a window
	window := glfw.CreateWindow(800, 600, "Odin OpenGL Triangle", nil, nil)
	if window == nil {
		fmt.println("Failed to create GLFW window")
		return
	}
	defer glfw.DestroyWindow(window)

	// Make the window's context current
	glfw.MakeContextCurrent(window)

	// Load OpenGL functions
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	// Create and compile vertex shader
	vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
	vertex_src := cstring(raw_data(vertex_shader_source))
	gl.ShaderSource(vertex_shader, 1, &vertex_src, nil)
	gl.CompileShader(vertex_shader)

	// Check for shader compile errors
	success: i32
	gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetShaderInfoLog(vertex_shader, 512, nil, cast(^u8)&info_log)
		fmt.printf("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n%s\n", info_log)
    }

	// Create and compile fragment shader
	fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
	fragment_src := cstring(raw_data(fragment_shader_source))
	gl.ShaderSource(fragment_shader, 1, &fragment_src, nil)
	gl.CompileShader(fragment_shader)

	// Check for shader compile errors
	gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetShaderInfoLog(fragment_shader, 512, nil, cast(^u8)&info_log)
		fmt.printf("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n%s\n", info_log)
	}

	// Create shader program
	shader_program := gl.CreateProgram()
	gl.AttachShader(shader_program, vertex_shader)
	gl.AttachShader(shader_program, fragment_shader)
	gl.LinkProgram(shader_program)

	// Check for linking errors
	gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetProgramInfoLog(shader_program, 512, nil, cast(^u8)&info_log)
		fmt.printf("ERROR::SHADER::PROGRAM::LINKING_FAILED\n%s\n", info_log)
	}

	// Delete shaders as they're linked into our program and no longer necessary
	gl.DeleteShader(vertex_shader)
	gl.DeleteShader(fragment_shader)

	// Set up vertex data
	vbo, vao: u32
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)

	// Bind VAO first
	gl.BindVertexArray(vao)

	// Bind VBO and copy vertices data
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	// Position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// Color attribute
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	// Main render loop
	for !glfw.WindowShouldClose(window) {
		// Process input
		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
			glfw.SetWindowShouldClose(window, true)
		}

		// Clear the screen
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// Draw the triangle
		gl.UseProgram(shader_program)
		gl.BindVertexArray(vao)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		// Swap buffers and poll events
		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	// Optional cleanup
    gl.DeleteVertexArrays(1, &vao)
    gl.DeleteBuffers(1, &vbo)
    gl.DeleteProgram(shader_program)
}
