package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import vmem "core:mem/virtual"
import "core:os"
import "core:strings"

import rl "vendor:raylib"
DEBUG_COLISION :: #config(DEBUG_COLISION, false)

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 800
PLAYER_SIZE :: 32
GRID_SIZE :: PLAYER_SIZE / 2

CANDY_SIZE :: 32

ENEMY_SIZE :: 32
ENEMY_SPEED :: 1
ENEMY_COLLIDER_THRESHOLD :: 4
ENEMY_SIZE_BULLET :: 16

EPSILON_COLISION :: 4

BULLET_SIZE :: 16

NUM_RECTANGLES_ON_SCENE :: 100
NUM_ENTITIES :: 1000
TITLE :: "SCENE_001"

atlas: rl.Texture2D
tx_candy: rl.Texture2D


main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "LEVELEDIT")
	rl.InitAudioDevice()

	rl.SetTargetFPS(60)

	atlas = rl.LoadTexture("assets/atlas.png")
	tx_candy = rl.LoadTexture("assets/coin.png")
	defer rl.UnloadTexture(atlas)
	defer rl.UnloadTexture(tx_candy)

	load_animations()
	load_sprites()
	load_prefab()
	world := new_world()


	game := Game {
		world          = world,
		on_cursor      = PREFAB(0),
		draw_colliders = false,
	}


	for !rl.WindowShouldClose() {


		pos := rl.GetMousePosition()
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			fmt.println(pos)

			spawn_entity(game.world, prefab_bank[game.on_cursor], pos)

			fmt.println(game.world.entity_count)
		}

		if rl.IsKeyPressed(rl.KeyboardKey.C) {
			if game.draw_colliders {
				game.draw_colliders = false
			} else {
				game.draw_colliders = true
			}
		}

		if rl.IsKeyPressed(rl.KeyboardKey.N) {
			next := game.on_cursor + PREFAB(1)
			if next >= PREFAB.PREFAB_COUNT {
				next = PREFAB(0)
			}
			game.on_cursor = next
			fmt.println(game.on_cursor)
		}


		if rl.IsKeyPressed((rl.KeyboardKey.F5)) {
			strings, arena := save_scene(world)
			// fmt.println()
			// for str in strings {
			// 	fmt.print(str)
			// }
			write_file(TITLE, strings)
			vmem.arena_destroy(&arena)
			delete(strings)
			free_all(context.temp_allocator)
		}


		rl.BeginDrawing()

		draw_grid()

		draw_prefab(&game, pos)


		RenderingSystem(&game)
		if game.draw_colliders {
			DrawCollidersSystem(&game)
		}
		rl.ClearBackground(rl.BLACK)
		rl.EndDrawing()

	}
}

save_scene :: proc(world: ^World) -> ([dynamic]string, vmem.Arena) {
	arena: vmem.Arena
	strings: [dynamic]string
	arena_allocator := vmem.arena_allocator(&arena)
	// TODO: BE CAREFULL WITH THIS, WE WILL COUNT NUMBER OF FILES ON ./SCENES AND MAKE SCENES_00n
	append(&strings, "SCENE 001\n\n")
	for _, archetype in world.archetypes {
		mask := archetype.component_mask
		for i in 0 ..< len(archetype.entities_id) {
			str := fmt.aprintf("$%b$\n", int(mask), allocator = arena_allocator)
			append(&strings, str)
			for component in COMPONENT_ID(0) ..< COMPONENT_ID.COUNT {
				if (component & mask) == component {
					switch component {
					case .POSITION:
						c := archetype.positions[i]
						str := fmt.aprintf(
							"C1/%v/%v\n",
							c.pos,
							c.size,
							allocator = arena_allocator,
						)
						append(&strings, str)
					case .VELOCITY:
						c := archetype.velocities[i]
						str := fmt.aprintf(
							"C2/%v/%v\n",
							c.direction,
							c.speed,
							allocator = arena_allocator,
						)
						append(&strings, str)
					case .SPRITE:
						c := archetype.sprites[i]
						str := fmt.aprintf("C4/%v\n", c.IMAGE_IDX, allocator = arena_allocator)
						append(&strings, str)

					case .ANIMATION:
						c := archetype.animations[i]
						str := fmt.aprintf("C8/%v\n", c.IMAGE_IDX, allocator = arena_allocator)
						append(&strings, str)

					case .DATA:
						c := archetype.data[i]
						str := fmt.aprintf(
							"C16/%v/%v/%v\n",
							int(c.kind),
							int(c.state),
							int(c.team),
							allocator = arena_allocator,
						)
						append(&strings, str)
					case .COLLIDER:
						c := archetype.colliders[i]
						str := fmt.aprintf(
							"C32/%v/%v/%v\n",
							c.position,
							c.w,
							c.h,
							allocator = arena_allocator,
						)
						append(&strings, str)
					case .IA:
						c := archetype.ias[i]
						str := fmt.aprintf(
							"C64/%v/%v/%v/%v/0\n",
							int(c.behavior),
							c.reload_time,
							c.minimum_distance,
							c.maximum_distance,
							allocator = arena_allocator,
						)
						append(&strings, str)
					case .COUNT:
					}
				}
			}
			str = fmt.aprintf("\n", allocator = arena_allocator)
			append(&strings, str)
		}


	}
	fmt.println("SCENE SAVED\n\n")
	return strings, arena
}


spawn_entity :: proc(world: ^World, prefab: Prefab, position: Vector2) {
	mask := prefab.mask
	add_entity(world, mask)

	archetype := world.archetypes[mask]
	for component in COMPONENT_ID(0) ..< COMPONENT_ID.COUNT {
		if (component & mask) == component {
			switch component {
			case .POSITION:
				new_position := prefab.position
				new_position.pos = position
				append(&archetype.positions, new_position)
			case .VELOCITY:
				append(&archetype.velocities, prefab.velocity)
			case .SPRITE:
				new_sprite := prefab.sprite
				new_sprite.dst_rect.position = position
				append(&archetype.sprites, new_sprite)
			case .ANIMATION:
				append(&archetype.animations, prefab.animation)
			case .DATA:
				append(&archetype.data, prefab.data)
			case .COLLIDER:
				new_collider := prefab.collider
				new_collider.position += position
				append(&archetype.colliders, new_collider)
			case .IA:
				append(&archetype.ias, prefab.ia)
			case .COUNT:
			}
		}
	}
}

transmute_dynamic_array :: proc(strings: [dynamic]string) -> [dynamic]u8 {
	buffer := make([dynamic]u8, context.temp_allocator)

	for str in strings {
		for c in str {
			append(&buffer, cast(u8)c)
		}
	}
	return buffer

	// REMEMBER TO USE free_all(context.temp_allocator)
}


write_file :: proc(filepath: string, data: [dynamic]string) {
	bytes := transmute_dynamic_array(data)
	fmt.println(bytes)
	cwd := os.get_current_directory()

	name := fmt.tprintf("%v/scenes/%v.txt", cwd, filepath)
	fmt.println(name)
	ok := os.write_entire_file(name, bytes[:])
	fmt.println(ok)
	if !ok {
		fmt.println("Error writing file")
	}
}

read_file :: proc(filepath: string) {
	data, ok := os.read_entire_file(filepath, context.allocator)
	if !ok {
		return
	}
	defer delete(data, context.allocator)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		// process line
	}
}


draw_prefab :: proc(game: ^Game, pos: Vector2) {
	prefab := prefab_bank[game.on_cursor]

	if (prefab.mask & COMPONENT_ID.ANIMATION) == .ANIMATION {
		draw_animated_sprite(
			game,
			Position{pos, {ENEMY_SIZE, ENEMY_SIZE}},
			&prefab.animation,
			0,
			.NEUTRAL,
		)
	} else if (prefab.mask & COMPONENT_ID.SPRITE) == .SPRITE {
		dst_rec := Rect{pos, prefab.sprite.dst_rect.size}
		prefab.sprite.dst_rect = dst_rec
		draw_sprite(prefab.sprite)
	}
}

draw_grid :: proc() {
	for i: i32 = 0; i < SCREEN_WIDTH; i += GRID_SIZE {
		rl.DrawLine(i, 0, i, SCREEN_HEIGHT, rl.RED)

		rl.DrawLine(0, i, SCREEN_WIDTH, i, rl.RED)
	}
}
