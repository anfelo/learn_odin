package main

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"

screen_width: u32 : 800
screen_height: u32 : 600
game := Game{GameState.GameActive, [1024]bool{}, screen_width, screen_height}

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
	window := glfw.CreateWindow(
		auto_cast screen_width,
		auto_cast screen_height,
		"Odin Breakout",
		nil,
		nil,
	)
	if window == nil {
		fmt.println("Failed to create GLFW window")
		return
	}
	defer glfw.DestroyWindow(window)

	// Make the window's context current
	glfw.MakeContextCurrent(window)

	// Load OpenGL functions
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	glfw.SetKeyCallback(window, key_callback)
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

	gl.Viewport(0, 0, auto_cast screen_width, auto_cast screen_height)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	game_init(&game)
	defer game_delete(&game)

	// Main render loop
	for !glfw.WindowShouldClose(window) {
		// Process input
		glfw.PollEvents()

		game_process_input(&game)

		game_update(&game)

		// Clear the screen
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		game_draw(&game)

		// Swap buffers and poll events
		glfw.SwapBuffers(window)
	}
}

key_callback :: proc "c" (
	window: glfw.WindowHandle,
	key: i32,
	scancode: i32,
	action: i32,
	mode: i32,
) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}

	if (key >= 0 && key < 1024) {
		if (action == glfw.PRESS) {
			game.keys[key] = true
		} else if (action == glfw.RELEASE) {
			game.keys[key] = false
		}
	}
}

framebuffer_size_callback :: proc "c" (_: glfw.WindowHandle, width: i32, height: i32) {
	gl.Viewport(0, 0, width, height)
}
