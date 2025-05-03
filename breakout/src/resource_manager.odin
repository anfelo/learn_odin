package main

import gl "vendor:OpenGL"

ResourceManager :: struct {
	textures: map[string]Texture2D,
	shaders:  map[string]Shader,
}

// loads (and generates) a shader program from file loading vertex, fragment
// (and geometry) shader's source code. If gShaderFile is not nullptr, it
// also loads a geometry shader
rm_load_shader :: proc(
	rm: ^ResourceManager,
	vertex_shader_file: string,
	fragment_shader_file: string,
	name: string,
) {
	shader := Shader{}
	shader_create(&shader, vertex_shader_file, fragment_shader_file)
	rm.shaders[name] = shader
}

// retrieves a stored shader
rm_get_shader :: proc(rm: ^ResourceManager, name: string) -> (^Shader, bool) {
	return &rm.shaders[name]
}

// loads (and generates) a texture from file
rm_load_texture :: proc(rm: ^ResourceManager, file: string, format: gl.GL_Enum, name: string) {
	texture := Texture2D{}
	texture_create(&texture)
	texture_load(&texture, file, format == gl.GL_Enum.RGBA)
	rm.textures[name] = texture
}

// retrieves a stored texture
rm_get_texture :: proc(rm: ^ResourceManager, name: string) -> (^Texture2D, bool) {
	return &rm.textures[name]
}

// properly de-allocates all loaded resources
rm_clear_resources :: proc(rm: ^ResourceManager) {
	defer delete(rm.shaders)
	for key, &shader in rm.shaders {
		shader_delete(&shader)
	}

	defer delete(rm.textures)
	for key, &texture in rm.textures {
		texture_delete(&texture)
	}
}
