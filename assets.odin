package main

import rl "vendor:raylib"


load_prefab :: proc() {
	prefab_bank[PREFAB.ENEMY] = Prefab {
		mask      = COMPONENT_ID.ANIMATION | .POSITION | .VELOCITY | .COLLIDER | .IA | .DATA,
		animation = &animation_bank[ANIMATION.ENEMY_SHOT],
		position  = &Position{{0, 0}, {ENEMY_SIZE, ENEMY_SIZE}},
		velocity  = &Velocity{{0, 0}, ENEMY_SPEED},
		collider  = &Collider {
			Vector2{0, 0} + EPSILON_COLISION * 2,
			ENEMY_SIZE - EPSILON_COLISION * 4,
			ENEMY_SIZE - EPSILON_COLISION * 4,
		},
		ia        = &IA{.APPROACH, 60, 100, 500, 0},
		data      = &Data{.ENEMY, .ALIVE, .BAD},
	}

	prefab_bank[PREFAB.BORDER] = Prefab {
		mask     = COMPONENT_ID.SPRITE | .POSITION | .COLLIDER | .DATA,
		sprite   = &sprite_bank[SPRITE.BORDER_UP],
		position = &Position{{BORDER_SIZE / 2, SCREEN_WIDTH / 2}, {BORDER_SIZE, SCREEN_WIDTH}},
		collider = &Collider {
			Vector2{0, 0} + EPSILON_COLISION * 2,
			GRID_SIZE - EPSILON_COLISION * 4,
			GRID_SIZE - EPSILON_COLISION * 4,
		},
		data     = &Data{.STATIC, .ALIVE, .NEUTRAL},
	}

	prefab_bank[PREFAB.COIN] = Prefab {
		mask      = COMPONENT_ID.ANIMATION | .POSITION | .COLLIDER | .DATA,
		animation = &animation_bank[ANIMATION.CANDY],
		position  = &Position{{0, 0}, {CANDY_SIZE, CANDY_SIZE}},
		collider  = &Collider {
			Vector2{0, 0} + EPSILON_COLISION * 2,
			CANDY_SIZE - EPSILON_COLISION * 4,
			CANDY_SIZE - EPSILON_COLISION * 4,
		},
		data      = &Data{.CANDY, .ALIVE, .NEUTRAL},
	}
}


spawn_enemy :: proc(game: ^Game, pos: Vector2) {
	mask := (COMPONENT_ID.POSITION | .VELOCITY | .ANIMATION | .COLLIDER | .DATA | .IA)
	add_entity(game.world, mask)

	archetype := game.world.archetypes[mask]
	enemy_position := Position{pos, {ENEMY_SIZE, ENEMY_SIZE}}
	append(&archetype.positions, enemy_position)
	append(&archetype.velocities, Velocity{{0, 0}, ENEMY_SPEED})
	append(&archetype.animations, animation_bank[ANIMATION.ENEMY_RUN])


	colision_origin := pos + EPSILON_COLISION * 2
	enemy_collider := Collider {
		colision_origin,
		ENEMY_SIZE - EPSILON_COLISION * 4,
		ENEMY_SIZE - EPSILON_COLISION * 4,
	}
	append(&archetype.colliders, enemy_collider)

	append(&archetype.data, Data{.ENEMY, .ALIVE, .BAD})
	append(&archetype.ias, IA{.APPROACH, 60, 100, 500, 0})

}


// load_scenario :: proc(game: ^Game) {
// 	world := game.world
//
// 	mask := COMPONENT_ID.COLLIDER | .SPRITE | .DATA | .POSITION
//
// 	add_entity(world, mask)
// 	arquetype := world.archetypes[mask]
//
// 	append(&arquetype.positions, Position{{0, 0}, {SCREEN_WIDTH, PLAYER_SIZE}})
// 	append(&arquetype.colliders, Collider{{0, 0}, SCREEN_WIDTH, PLAYER_SIZE})
// 	append(
// 		&arquetype.sprites,
// 		Sprite{&atlas, Rect{{0, 96}, {32, 32}}, Rect{{0 + 800 / 2, 0 + 128 / 2}, {128, 800}}, 90},
// 	)
//
// 	append(&arquetype.data, Data{.STATIC, .ALIVE, .NEUTRAL})
//
// 	add_entity(world, mask)
// 	append(
// 		&arquetype.positions,
// 		Position{{0, SCREEN_HEIGHT - PLAYER_SIZE}, {SCREEN_WIDTH, PLAYER_SIZE}},
// 	)
// 	append(
// 		&arquetype.colliders,
// 		Collider{{0, SCREEN_HEIGHT - PLAYER_SIZE}, SCREEN_WIDTH, PLAYER_SIZE},
// 	)
// 	append(
// 		&arquetype.sprites,
// 		Sprite {
// 			&atlas,
// 			Rect{{0, 96}, {32, 32}},
// 			Rect{{0 + 800 / 2, 672 + 128 / 2}, {128, 800}},
// 			270,
// 		},
// 	)
// 	append(&arquetype.data, Data{.STATIC, .ALIVE, .NEUTRAL})
//
// 	add_entity(world, mask)
//
// 	append(&arquetype.positions, Position{{0, 0}, {PLAYER_SIZE, SCREEN_HEIGHT}})
// 	append(&arquetype.colliders, Collider{{0, 0}, PLAYER_SIZE, SCREEN_HEIGHT})
// 	append(
// 		&arquetype.sprites,
// 		Sprite{&atlas, Rect{{0, 96}, {32, 32}}, Rect{{128 / 2, 800 / 2}, {128, 800}}, 0},
// 	)
//
// 	append(&arquetype.data, Data{.STATIC, .ALIVE, .NEUTRAL})
//
// 	add_entity(world, mask)
// 	append(
// 		&arquetype.positions,
// 		Position{{SCREEN_WIDTH - PLAYER_SIZE, 0}, {PLAYER_SIZE, SCREEN_HEIGHT}},
// 	)
// 	append(
// 		&arquetype.colliders,
// 		Collider{{SCREEN_WIDTH - PLAYER_SIZE, 0}, PLAYER_SIZE, SCREEN_HEIGHT},
// 	)
// 	append(
// 		&arquetype.sprites,
// 		Sprite{&atlas, Rect{{0, 96}, {32, 32}}, Rect{{672 + 128 / 2, 800 / 2}, {128, 800}}, 180},
// 	)
// 	append(&arquetype.data, Data{.STATIC, .ALIVE, .NEUTRAL})
//
//
// 	// CORNERS
// 	add_entity(world, mask)
// 	append(&arquetype.positions, Position{{0, SCREEN_HEIGHT - PLAYER_SIZE}, {32, 32}})
// 	append(
// 		&arquetype.colliders,
// 		Collider{{0, SCREEN_HEIGHT - PLAYER_SIZE}, SCREEN_WIDTH, PLAYER_SIZE},
// 	)
// 	append(
// 		&arquetype.sprites,
// 		Sprite {
// 			&atlas,
// 			Rect{{32, 96}, {32, 32}},
// 			Rect{{800 - 128 / 2, 0 + 128 / 2}, {128, 128}},
// 			90,
// 		},
// 	)
// 	append(&arquetype.data, Data{.STATIC, .ALIVE, .NEUTRAL})
//
//
// 	add_entity(world, mask)
// 	append(&arquetype.positions, Position{{0, SCREEN_HEIGHT - PLAYER_SIZE}, {32, 32}})
// 	append(
// 		&arquetype.colliders,
// 		Collider{{0, SCREEN_HEIGHT - PLAYER_SIZE}, SCREEN_WIDTH, PLAYER_SIZE},
// 	)
// 	append(
// 		&arquetype.sprites,
// 		Sprite{&atlas, Rect{{32, 96}, {32, 32}}, Rect{{0 + 128 / 2, 0 + 128 / 2}, {128, 128}}, 0},
// 	)
// 	append(&arquetype.data, Data{.STATIC, .ALIVE, .NEUTRAL})
//
//
// 	add_entity(world, mask)
// 	append(&arquetype.positions, Position{{0, SCREEN_HEIGHT - PLAYER_SIZE}, {32, 32}})
// 	append(
// 		&arquetype.colliders,
// 		Collider{{0, SCREEN_HEIGHT - PLAYER_SIZE}, SCREEN_WIDTH, PLAYER_SIZE},
// 	)
// 	append(
// 		&arquetype.sprites,
// 		Sprite {
// 			&atlas,
// 			Rect{{32, 96}, {32, 32}},
// 			Rect{{800 - 128 / 2, 800 - 128 / 2}, {128, 128}},
// 			180,
// 		},
// 	)
// 	append(&arquetype.data, Data{.STATIC, .ALIVE, .NEUTRAL})
//
//
// 	add_entity(world, mask)
// 	append(&arquetype.positions, Position{{0, SCREEN_HEIGHT - PLAYER_SIZE}, {32, 32}})
// 	append(
// 		&arquetype.colliders,
// 		Collider{{0, SCREEN_HEIGHT - PLAYER_SIZE}, SCREEN_WIDTH, PLAYER_SIZE},
// 	)
// 	append(
// 		&arquetype.sprites,
// 		Sprite {
// 			&atlas,
// 			Rect{{32, 96}, {32, 32}},
// 			Rect{{0 + 128 / 2, 800 - 128 / 2}, {128, 128}},
// 			270,
// 		},
// 	)
// 	append(&arquetype.data, Data{.STATIC, .ALIVE, .NEUTRAL})
// }
