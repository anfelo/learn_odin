package main

import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"


Texture2D :: struct {
	ID:              u32,
	internal_format: gl.GL_Enum,
	image_format:    gl.GL_Enum,
	width, height:   i32,
}

texture_create :: proc(texture: ^Texture2D) {
	texture.width = 0
	texture.height = 0
	texture.internal_format = gl.GL_Enum.RGB
	texture.image_format = gl.GL_Enum.RGB

	gl.GenTextures(1, &texture.ID)
}

texture_load :: proc(texture: ^Texture2D, texture_file: string, alpha: bool) {
	// create texture object
	if (alpha) {
		texture.internal_format = gl.GL_Enum.RGBA
		texture.image_format = gl.GL_Enum.RGBA
	}

	// Load an image file
	width, height, channels: i32
	// Load the image - this returns a pointer to the pixel data
	data := stbi.load(strings.clone_to_cstring(texture_file), &width, &height, &channels, 0)
	defer stbi.image_free(data)
	if data == nil {
		fmt.println("Failed to load image")
		return
	}

	// now generate texture
	texture_generate(texture, width, height, data)
}

texture_generate :: proc(texture: ^Texture2D, width: i32, height: i32, data: rawptr) {
	texture.width = width
	texture.height = height
	// create Texture
	gl.BindTexture(gl.TEXTURE_2D, texture.ID)
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		auto_cast texture.internal_format,
		width,
		height,
		0,
		auto_cast texture.image_format,
		gl.UNSIGNED_BYTE,
		data,
	)
	// set Texture wrap and filter modes
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	// unbind texture
	gl.BindTexture(gl.TEXTURE_2D, 0)
}

texture_bind :: proc(texture: ^Texture2D, slot: gl.GL_Enum) {
	gl.ActiveTexture(auto_cast slot)
	gl.BindTexture(gl.TEXTURE_2D, texture.ID)
}

texture_unbind :: proc(texture: ^Texture2D) {
	gl.BindTexture(gl.TEXTURE_2D, 0)
}

texture_delete :: proc(texture: ^Texture2D) {
	gl.DeleteTextures(1, &texture.ID)
}
