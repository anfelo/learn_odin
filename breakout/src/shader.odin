package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:os"
import gl "vendor:OpenGL"

Shader :: struct {
	ID: u32,
}

shader_create :: proc(shader: ^Shader, vertex_shader_file: string, fragment_shader_file: string) {
	vertex_source_data, ok := os.read_entire_file(vertex_shader_file)
	if (!ok) {
		fmt.println("ERROR::SHADER::READING::FILE\n%s\n")
		return
	}
	vertex_shader_source := string(vertex_source_data)
	defer delete(vertex_source_data)

	fragment_source_data, ok2 := os.read_entire_file(fragment_shader_file)
	if (!ok2) {
		fmt.println("ERROR::SHADER::READING::FILE\n%s\n")
		return
	}
	fragment_shader_source := string(fragment_source_data)
	defer delete(fragment_source_data)

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
	shader.ID = gl.CreateProgram()
	gl.AttachShader(shader.ID, vertex_shader)
	gl.AttachShader(shader.ID, fragment_shader)
	gl.LinkProgram(shader.ID)

	// Check for linking errors
	gl.GetProgramiv(shader.ID, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetProgramInfoLog(shader.ID, 512, nil, cast(^u8)&info_log)
		fmt.printf("ERROR::SHADER::PROGRAM::LINKING_FAILED\n%s\n", info_log)
	}

	// Delete shaders as they're linked into our program and no longer necessary
	gl.DeleteShader(vertex_shader)
	gl.DeleteShader(fragment_shader)
}

shader_use :: proc(shader: ^Shader) {
	gl.UseProgram(shader.ID)
}

shader_delete :: proc(shader: ^Shader) {
	gl.DeleteShader(shader.ID)
}

shader_set_float :: proc(shader: ^Shader, name: string, value: f32) {
	gl.Uniform1f(gl.GetUniformLocation(shader.ID, cstring(raw_data(name))), value)
}

shader_set_bool :: proc(shader: ^Shader, name: string, value: bool) {
	gl.Uniform1i(gl.GetUniformLocation(shader.ID, cstring(raw_data(name))), auto_cast value)
}

shader_set_int :: proc(shader: ^Shader, name: string, value: i32) {
	gl.Uniform1i(gl.GetUniformLocation(shader.ID, cstring(raw_data(name))), value)
}

shader_set_vec2 :: proc(shader: ^Shader, name: string, value: ^glm.vec2) {
	gl.Uniform2fv(gl.GetUniformLocation(shader.ID, cstring(raw_data(name))), 1, &value[0])
}

shader_set_vec3 :: proc(shader: ^Shader, name: string, value: ^glm.vec3) {
	gl.Uniform3fv(gl.GetUniformLocation(shader.ID, cstring(raw_data(name))), 1, &value[0])
}

shader_set_vec4 :: proc(shader: ^Shader, name: string, value: ^glm.vec4) {
	gl.Uniform4fv(gl.GetUniformLocation(shader.ID, cstring(raw_data(name))), 1, &value[0])
}

shader_set_mat4 :: proc(shader: ^Shader, name: string, value: ^glm.mat4) {
	gl.UniformMatrix4fv(
		gl.GetUniformLocation(shader.ID, cstring(raw_data(name))),
		1,
		gl.FALSE,
		&value[0][0],
	)
}
