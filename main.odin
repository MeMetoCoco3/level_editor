package main

import "core:fmt"
import "core:math"
import "core:math/rand"

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


atlas: rl.Texture2D
tx_candy: rl.Texture2D


// WE ALWAYS PUT ONE AND we are automatically moving it, if we click, we leave it on the spot


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

	world := new_world()


	game := Game {
		world          = world,
		on_cursor      = animation_bank[ANIMATION.ENEMY_RUN],
		draw_colliders = false,
	}


	for !rl.WindowShouldClose() {


		pos := rl.GetMousePosition()
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			fmt.println(pos)
			spawn_enemy(&game, pos)
			fmt.println(game.world.entity_count)
		}

		if rl.IsKeyPressed(rl.KeyboardKey.C) {
			if game.draw_colliders {
				game.draw_colliders = false
			} else {
				game.draw_colliders = true
			}
		}


		rl.BeginDrawing()

		draw_grid()

		draw_animated_sprite(
			&game,
			Position{pos, {ENEMY_SIZE, ENEMY_SIZE}},
			&game.on_cursor,
			0,
			.NEUTRAL,
		)


		RenderingSystem(&game)
		if game.draw_colliders {
			DrawCollidersSystem(&game)
		}
		rl.ClearBackground(rl.BLACK)
		rl.EndDrawing()

	}
}

draw_grid :: proc() {
	for i: i32 = 0; i < SCREEN_WIDTH; i += GRID_SIZE {
		rl.DrawLine(i, 0, i, SCREEN_HEIGHT, rl.RED)

		rl.DrawLine(0, i, SCREEN_WIDTH, i, rl.RED)
	}
}
