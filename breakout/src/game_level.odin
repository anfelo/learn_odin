package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:strings"
import "core:unicode/utf8"

GameLevel :: struct {
	bricks: [dynamic]GameObject,
}

game_level_load :: proc(
	resources: ^ResourceManager,
	level: ^GameLevel,
	file: string,
	level_width: u32,
	level_height: u32,
) {
	// clear old data
	clear(&level.bricks)

	data, ok := os.read_entire_file(file, context.allocator)
	if !ok {
		fmt.println("Could not read level file")
		return
	}
	defer delete(data, context.allocator)

	rows := make([dynamic][dynamic]u32)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		// Skip empty lines
		if len(line) == 0 {
			continue
		}

		// Create a new row of numbers
		row := make([dynamic]u32)

		for r, _ in utf8.string_to_runes(line) {
			// Skip non-digit characters if any
			if r < '0' || r > '9' {
				continue
			}

			// Convert rune to integer (subtract '0' rune value)
			number := u32(r - '0')

			// Add number to row
			append(&row, number)
		}

		// Add row to rows
		append(&rows, row)
	}

	if (len(rows) > 0) {
		game_level_init(resources, level, rows, level_width, level_height)
	}
}

game_level_draw :: proc(renderer: ^SpriteRenderer, level: ^GameLevel) {
	for &tile in level.bricks {
		if (!tile.destroyed) {
			game_object_draw(renderer, &tile)
		}
	}
}

game_level_is_complete :: proc(level: ^GameLevel) -> bool {
	for tile in level.bricks {
		if (!tile.is_solid && !tile.destroyed) {
			return false
		}
	}
	return true
}

game_level_init :: proc(
	resources: ^ResourceManager,
	level: ^GameLevel,
	tile_data: [dynamic][dynamic]u32,
	level_width: u32,
	level_height: u32,
) {
	// calculate dimensions
	height := cast(u32)len(tile_data)
	// note we can index vector at [0] since this
	// function is only called if height > 0
	width := cast(u32)len(tile_data[0])

	unit_width := cast(f32)level_width / cast(f32)(width)
	unit_height := cast(f32)level_height / cast(f32)(height)

	// initialize level tiles based on tileData
	for y: u32 = 0; y < height; y += 1 {
		for x: u32 = 0; x < width; x += 1 {
			// check block type from level data (2D level array)
			// Solid Bricks
			if (tile_data[y][x] == 1) {
				pos := glm.vec2{unit_width * cast(f32)x, unit_height * cast(f32)y}
				size := glm.vec2{unit_width, unit_height}
				color := glm.vec3{0.8, 0.8, 0.7}
				if sprite, ok := rm_get_texture(resources, "block_solid"); ok {
					obj := GameObject{}
					game_object_create(&obj, pos, size, sprite, color)
					obj.is_solid = true
					append(&level.bricks, obj)
				}
			} else if (tile_data[y][x] > 1) {
				// non-solid; now determine its color
				// based on level data

				color := glm.vec3(1.0) // original: white
				if (tile_data[y][x] == 2) {
					color = glm.vec3{0.2, 0.6, 1.0}
				} else if (tile_data[y][x] == 3) {
					color = glm.vec3{0.0, 0.7, 0.0}
				} else if (tile_data[y][x] == 4) {
					color = glm.vec3{0.8, 0.8, 0.4}
				} else if (tile_data[y][x] == 5) {
					color = glm.vec3{1.0, 0.5, 0.0}
				}

				pos := glm.vec2{unit_width * cast(f32)x, unit_height * cast(f32)y}
				size := glm.vec2{unit_width, unit_height}
				if sprite, ok := rm_get_texture(resources, "block"); ok {
					obj := GameObject{}
					game_object_create(&obj, pos, size, sprite, color)
					append(&level.bricks, obj)
				}
			}
		}
	}
}
