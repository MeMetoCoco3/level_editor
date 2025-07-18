package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import vmem "core:mem/virtual"
import "core:os"
import "core:path/filepath"
import "core:strconv"
import "core:strings"

import rl "vendor:raylib"

MIN_SIZE :: 8

PADDING :: 20
HEIGHT_TEXT_BLOCK :: 50


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

BORDER_SIZE :: 128


NUM_RECTANGLES_ON_SCENE :: 100
NUM_ENTITIES :: 1000

VERTEX_SIZE :: 12


atlas: rl.Texture2D
tx_candy: rl.Texture2D


title :: #config(title, "")

main :: proc() {

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "LEVEL EDIT: " + title)
	rl.InitAudioDevice()

	rl.SetTargetFPS(60)

	atlas = rl.LoadTexture("assets/atlas.png")
	tx_candy = rl.LoadTexture("assets/coin.png")
	defer rl.UnloadTexture(atlas)
	defer rl.UnloadTexture(tx_candy)


	load_animations()

	load_sprites()
	load_prefab()

	fmt.println(prefab_bank[PREFAB.ENEMY])
	world := new_world()


	game := Game {
		world           = world,
		on_cursor       = PREFAB(0),
		draw_colliders  = false,
		cursor_state    = .SELECT,
		vertex_selected = .NOT_SELECTED,
	}

	buf := make([dynamic]string)
	get_scene_files(&buf)
	game.files = &buf

	game.current_title = fmt.tprintf("SCENE_0%v", len(buf))

	when len(title) > 0 {
		game.current_title = title
	}

	for !rl.WindowShouldClose() {
		pos := rl.GetMousePosition()


		InputSystem(&game, &pos)

		rl.BeginDrawing()
		if game.cursor_state == .LOAD {
			rl.DrawRectangle(
				0 + PADDING,
				0 + PADDING,
				SCREEN_WIDTH - PADDING * 2,
				SCREEN_HEIGHT - PADDING * 2,
				rl.BLACK,
			)
			for name, i in game.files {
				x: i32 = PADDING
				y := i32(0 + PADDING * (i + 1) + HEIGHT_TEXT_BLOCK * i)
				rl.DrawRectangle(x, y, SCREEN_WIDTH - PADDING * 4, 50, rl.ORANGE)
				c_name, err := strings.clone_to_cstring(name)

				color := i == game.selected_file ? rl.RED : rl.BLACK
				rl.DrawText(c_name, x * 2, y, 50, color)
			}


		} else {
			draw_grid()
			if game.cursor_state == .GRAB_NEW {
				draw_prefab(&game, pos)
			}
			RenderingSystem(&game)
			if game.draw_colliders {
				DrawCollidersSystem(&game)
			}
		}


		rl.ClearBackground(rl.BLACK)
		rl.EndDrawing()

	}
}


InputSystem :: proc(game: ^Game, pos: ^Vector2) {
	state := game.cursor_state


	if rl.IsKeyPressed(rl.KeyboardKey.F6) {
		game.cursor_state = .LOAD
	}

	if state == .LOAD {
		if rl.IsKeyPressed(rl.KeyboardKey.UP) {
			game.selected_file -= 1
			if game.selected_file < 0 {
				game.selected_file = len(game.files) - 1
			}
		}
		if rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
			game.selected_file += 1


			if game.selected_file >= len(game.files) {
				game.selected_file = 0
			}

		}

		if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
			file_name := game.files[game.selected_file]
			free_all_entities(game)
			content, arena := read_file(file_name)

			load_content(game, content)

			vmem.arena_destroy(&arena)
			delete(content)
			free_all(context.temp_allocator)

			game.cursor_state = .SELECT
			game.current_title = strings.clone(file_name)
		}


	}


	if rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) {
		pos.x = math.floor(pos.x / GRID_SIZE) * GRID_SIZE
		pos.y = math.floor(pos.y / GRID_SIZE) * GRID_SIZE
	}

	if rl.IsKeyPressed(rl.KeyboardKey.C) {
		if game.draw_colliders {
			game.draw_colliders = false
		} else {
			game.draw_colliders = true
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.L) {
		game.cursor_state = .LOAD
	}

	if rl.IsKeyPressed(rl.KeyboardKey.R) {
		game.cursor_state = .RESIZE
	}

	if rl.IsKeyPressed(rl.KeyboardKey.S) {
		game.cursor_state = .SELECT
	}

	if state == .SELECT {
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			for _, archetype in game.world.archetypes {
				for i in 0 ..< len(archetype.entities_id) {
					position := archetype.positions[i]
					if point_in_pos(pos^, position) {
						load_prefab_from_archetype(game, archetype, i)
						game.cursor_state = .GRAB_EXISTING
						break
					}
				}
			}
		}
	}

	if state == .RESIZE {
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			check_vertex_col: for _, archetype in game.world.archetypes {
				for i in 0 ..< len(archetype.entities_id) {
					entity_pos := archetype.positions[i].pos
					entity_size := archetype.positions[i].size
					vertices := [4]rl.Rectangle {
						{
							f32(entity_pos.x - VERTEX_SIZE / 2),
							f32(entity_pos.y - VERTEX_SIZE / 2),
							f32(VERTEX_SIZE),
							f32(VERTEX_SIZE),
						},
						{
							f32(entity_pos.x + entity_size.x - VERTEX_SIZE / 2),
							f32(entity_pos.y - VERTEX_SIZE / 2),
							f32(VERTEX_SIZE),
							f32(VERTEX_SIZE),
						},
						{
							f32(entity_pos.x - VERTEX_SIZE / 2),
							f32(entity_pos.y + entity_size.y - VERTEX_SIZE / 2),
							f32(VERTEX_SIZE),
							f32(VERTEX_SIZE),
						},
						{
							f32(entity_pos.x + entity_size.x - VERTEX_SIZE / 2),
							f32(entity_pos.y + entity_size.y - VERTEX_SIZE / 2),
							f32(VERTEX_SIZE),
							f32(VERTEX_SIZE),
						},
					}

					for vertex, v_index in vertices {
						if point_in_rec(pos^, vertex) {
							load_prefab_from_archetype(game, archetype, i)
							game.vertex_selected = VERTEX(v_index)
							break check_vertex_col
						}
					}
				}
			}
		}
	}

	if state == .RESIZE &&
	   rl.IsMouseButtonDown(rl.MouseButton.LEFT) &&
	   game.vertex_selected != .NOT_SELECTED {
		fmt.println(game.vertex_selected)
		vertex_pos := &game.loaded_prefab.position.pos
		size := &game.loaded_prefab.position.size
		collider := game.loaded_prefab.collider


		original_pos := vertex_pos^
		original_size := size^
		original_br := vertex_pos^ + size^

		switch game.vertex_selected {
		case .TL:
			new_tl := pos
			new_br := original_br
			vertex_pos^ = new_tl^
			new_size := new_br - new_tl^
			size.x = max(new_size.x, MIN_SIZE)
			size.y = max(new_size.y, MIN_SIZE)

		case .TR:
			new_tl := Vector2{vertex_pos^.x, pos.y}
			new_br := Vector2{pos.x, original_br.y}
			vertex_pos^ = new_tl
			new_size := new_br - new_tl
			size.x = max(new_size.x, MIN_SIZE)
			size.y = max(new_size.y, MIN_SIZE)

		case .BL:
			new_tl := Vector2{pos.x, vertex_pos^.y}
			new_br := Vector2{original_br.x, pos.y}
			vertex_pos^ = Vector2{pos.x, vertex_pos^.y}
			new_size := new_br - vertex_pos^
			size.x = max(new_size.x, MIN_SIZE)
			size.y = max(new_size.y, MIN_SIZE)
		case .BR:
			new_size := pos^ - vertex_pos^
			size.x = max(new_size.x, MIN_SIZE)
			size.y = max(new_size.y, MIN_SIZE)

		case .NOT_SELECTED:

		}
		pos_delta := vertex_pos^ - original_pos
		size_delta := size^ - original_size
		collider.position += pos_delta
		collider.w += int(size_delta.x)
		collider.h += int(size_delta.y)

	} else if state == .RESIZE {
		game.vertex_selected = .NOT_SELECTED
	}


	if state == .GRAB_EXISTING {
		delta := game.loaded_prefab.collider.position - game.loaded_prefab.position.pos
		game.loaded_prefab.position.pos = pos^

		game.loaded_prefab.collider.position = pos^ + delta
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			game.cursor_state = .SELECT
		}
	}


	if state == .GRAB_NEW {
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			spawn_entity(game.world, prefab_bank[game.on_cursor], pos^)
			game.cursor_state = .SELECT
		}
	}


	if rl.IsKeyPressed(rl.KeyboardKey.N) {
		next: PREFAB
		if state != .GRAB_NEW {
			next = PREFAB(0)
		} else {
			next = game.on_cursor + PREFAB(1)
			if next >= PREFAB.PREFAB_COUNT {
				next = PREFAB(0)
			}
		}

		game.cursor_state = .GRAB_NEW
		game.on_cursor = next
	}


	if rl.IsKeyPressed(rl.KeyboardKey.F5) {
		strings, arena := save_scene(game)
		write_file(game.current_title, strings)
		vmem.arena_destroy(&arena)
		delete(strings)
		free_all(context.temp_allocator)
	}

	if rl.IsKeyPressed(rl.KeyboardKey.F1) {
		free_all_entities(game)
		content, arena := read_file(game.current_title)

		load_content(game, content)

		vmem.arena_destroy(&arena)
		delete(content)
		free_all(context.temp_allocator)
	}
}


free_all_entities :: proc(game: ^Game) {
	for _, archetype in game.world.archetypes {
		mask := archetype.component_mask
		delete(archetype.entities_id)
		for component in COMPONENT_ID {
			if (component & mask) == component {
				switch component {
				case .POSITION:
					delete(archetype.positions)
				case .VELOCITY:
					delete(archetype.velocities)
				case .SPRITE:
					delete(archetype.sprites)
				case .ANIMATION:
					delete(archetype.animations)
				case .DATA:
					delete(archetype.data)
				case .COLLIDER:
					delete(archetype.colliders)
				case .IA:
					delete(archetype.ias)
				case .COUNT:
				}
			}
		}
		delete_key(&game.world.archetypes, mask)
	}
}

load_content :: proc(game: ^Game, content: [dynamic]string) {
	fmt.println("LOADING")
	current_arquetype: ^Archetype
	if len(content) < 3 {
		return
	}
	for line in content[1:] {
		if len(line) == 0 {
			continue
		}

		if strings.starts_with(line, "$") {
			mask, ok := strconv.parse_i64_of_base(strings.trim(line, "$"), 2)
			if !ok {
				fmt.println("ERROR PARSING MASK")
				return
			}

			fmt.println(mask)
			add_entity(game.world, COMPONENT_ID(mask))
			current_arquetype = game.world.archetypes[COMPONENT_ID(mask)]

		} else if strings.starts_with(line, "C") {
			pieces, _ := strings.split(line, "/")
			component_id := COMPONENT_ID(strconv.atoi(strings.trim(pieces[0], "C")))

			switch component_id {
			case .POSITION:
				pos := strings.split(strings.trim(pieces[1], "[]"), ",")
				fmt.println("POSITION!!:", pos)
				pos_x := strconv.atof(pos[0])
				pos_y := strconv.atof(strings.trim(pos[1], " "))
				size := strings.split(strings.trim(pieces[2], "[]"), ",")
				size_x := strconv.atof(size[0])
				size_y := strconv.atof(strings.trim(size[1], " "))

				fmt.println(
					Position {
						pos = Vector2{f32(pos_x), f32(pos_y)},
						size = Vector2{f32(size_x), f32(size_y)},
					},
				)

				append(
					&current_arquetype.positions,
					Position {
						pos = Vector2{f32(pos_x), f32(pos_y)},
						size = Vector2{f32(size_x), f32(size_y)},
					},
				)

			case .VELOCITY:
				dir := strings.split(strings.trim(pieces[1], "[]"), ",")
				dir_x := strconv.atof(dir[0])
				dir_y := strconv.atof(dir[1])
				speed := strconv.atof(pieces[2])

				fmt.println(
					Velocity{direction = Vector2{f32(dir_x), f32(dir_y)}, speed = f32(speed)},
				)

				append(
					&current_arquetype.velocities,
					Velocity{direction = Vector2{f32(dir_x), f32(dir_y)}, speed = f32(speed)},
				)

			case .SPRITE:
				sprite_index := strconv.atoi(pieces[1])
				fmt.println(sprite_bank[sprite_index])
				append(&current_arquetype.sprites, sprite_bank[sprite_index])

			case .ANIMATION:
				animation_index := strconv.atoi(pieces[1])
				fmt.println(animation_bank[animation_index])
				append(&current_arquetype.animations, animation_bank[animation_index])

			case .DATA:
				fmt.println(
					Data {
						kind = ENTITY_KIND(strconv.atoi(pieces[1])),
						state = ENTITY_STATE(strconv.atoi(pieces[2])),
						team = ENTITY_TEAM(strconv.atoi(pieces[3])),
					},
				)
				append(
					&current_arquetype.data,
					Data {
						kind = ENTITY_KIND(strconv.atoi(pieces[1])),
						state = ENTITY_STATE(strconv.atoi(pieces[2])),
						team = ENTITY_TEAM(strconv.atoi(pieces[3])),
					},
				)

			case .COLLIDER:
				pos := strings.split(strings.trim(pieces[1], "[]"), ",")
				pos_x := strconv.atof(pos[0])
				pos_y := strconv.atof(pos[1])

				w := strconv.atof(pieces[2])
				h := strconv.atof(pieces[3])

				fmt.println(
					Collider{position = Vector2{f32(pos_x), f32(pos_y)}, w = int(w), h = int(h)},
				)

				append(
					&current_arquetype.colliders,
					Collider{position = Vector2{f32(pos_x), f32(pos_y)}, w = int(w), h = int(h)},
				)

			case .IA:
				fmt.println(
					IA {
						behavior = ENEMY_BEHAVIOR(strconv.atoi(pieces[1])),
						reload_time = f32(strconv.atof(pieces[2])),
						minimum_distance = f32(strconv.atof(pieces[3])),
						maximum_distance = f32(strconv.atof(pieces[4])),
					},
				)

				append(
					&current_arquetype.ias,
					IA {
						behavior = ENEMY_BEHAVIOR(strconv.atoi(pieces[1])),
						reload_time = f32(strconv.atof(pieces[2])),
						minimum_distance = f32(strconv.atof(pieces[3])),
						maximum_distance = f32(strconv.atof(pieces[4])),
					},
				)

			case .COUNT:


			}

		}
	}
}


save_scene :: proc(game: ^Game) -> ([dynamic]string, vmem.Arena) {
	arena: vmem.Arena
	world := game.world
	// TODO: CHECK IF THIS STRINGS SHOULD BE DECLARED IN ARENA
	strings: [dynamic]string
	arena_allocator := vmem.arena_allocator(&arena)
	scene_title := fmt.tprintf("%s\n\n", game.current_title)
	append(&strings, scene_title)
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
				fmt.println("NEW POSITION: ", new_position)
				fmt.println("SIZE: ", prefab.position.size)
				append(&archetype.positions, new_position)
			case .VELOCITY:
				append(&archetype.velocities, prefab.velocity)
			case .SPRITE:
				new_sprite := prefab.sprite
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
	cwd := os.get_current_directory()


	name := fmt.tprintf("%v/scenes/%v", cwd, filepath)
	if !strings.has_suffix(name, ".txt") {
		name = fmt.tprintf("%v.txt", name)
	}


	fmt.println(name)
	ok := os.write_entire_file(name, bytes[:])

	fmt.println(ok)
	if !ok {
		fmt.println("Error writing file")
	}
}


get_scene_files :: proc(buf: ^[dynamic]string) {
	cwd := os.get_current_directory()
	dir_path := fmt.tprintf("%v/scenes", cwd)
	dir, err := os.open(dir_path)
	defer os.close(dir)

	if err != nil {
		fmt.printfln("Failed to open directory: %v", err)
		return
	}
	fis: []os.File_Info
	fis, err = os.read_dir(dir, -1)
	defer os.file_info_slice_delete(fis)

	if err != os.ERROR_NONE {
		fmt.eprintln("Could not read directory", err)
		return
	}

	for fi in fis {
		_, file_name := filepath.split(fi.fullpath)

		append(buf, strings.clone(file_name))
	}
}

read_file :: proc(filename: string) -> ([dynamic]string, vmem.Arena) {
	cwd := os.get_current_directory()
	filepath := fmt.tprintf("%v/scenes/%v", cwd, filename)
	fmt.println(filepath)
	data, ok := os.read_entire_file(filepath, context.temp_allocator)
	if !ok {
		return [dynamic]string{}, vmem.Arena{}
	}
	defer delete(data, context.allocator)

	arena: vmem.Arena
	content: [dynamic]string
	arena_allocator := vmem.arena_allocator(&arena)


	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		fmt.println(line)
		append(&content, line)
	}

	return content, arena
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
		draw_sprite(prefab.sprite, Position{pos, prefab.position.size})
	}
}

draw_grid :: proc() {
	for i: i32 = 0; i < SCREEN_WIDTH; i += GRID_SIZE {
		rl.DrawLine(i, 0, i, SCREEN_HEIGHT, rl.GRAY)

		rl.DrawLine(0, i, SCREEN_WIDTH, i, rl.GRAY)
	}
}
