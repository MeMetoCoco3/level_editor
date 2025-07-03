package main
import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Vector2 :: [2]f32

Game :: struct {
	draw_colliders:  bool,
	on_cursor:       PREFAB,
	loaded_prefab:   Prefab_loaded,
	world:           ^World,
	cursor_state:    CURSOR_STATE,
	vertex_selected: VERTEX,
}

VERTEX :: enum {
	TL,
	TR,
	BL,
	BR,
	NOT_SELECTED,
}

ANIMATION :: enum {
	PLAYER = 0,
	BULLET_G,
	ENEMY_SHOT,
	ENEMY_RUN,
	BIG_EXPLOSION,
	BULLET_B,
	CANDY,
	ANIM_COUNT,
}

SPRITE :: enum {
	PLAYER_IDLE = 0,
	PLAYER_EAT,
	BODY_STRAIGHT,
	BODY_TURN,
	TAIL,
	BORDER,
	CORNER,
	BORDER_UP,
	// BORDER_DOWN,
	// BORDER_LEFT,
	// BORDER_RIGHT,
	SPRITE_COUNT,
}


Prefab :: struct {
	mask:      COMPONENT_ID,
	position:  Position,
	velocity:  Velocity,
	sprite:    Sprite,
	animation: Animation,
	data:      Data,
	collider:  Collider,
	ia:        IA,
}

Prefab_loaded :: struct {
	mask:      COMPONENT_ID,
	position:  ^Position,
	velocity:  ^Velocity,
	sprite:    ^Sprite,
	animation: ^Animation,
	data:      ^Data,
	collider:  ^Collider,
	ia:        ^IA,
}

PREFAB :: enum {
	ENEMY,
	BORDER,
	COIN,
	PREFAB_COUNT,
	LOADED_PREFAB,
	UPPER_COUNT,
}

CURSOR_STATE :: enum {
	SELECT,
	GRAB_EXISTING,
	GRAB_NEW,
	RESIZE,
}

prefab_bank: [PREFAB.UPPER_COUNT]Prefab
animation_bank: [ANIMATION.ANIM_COUNT]Animation
sprite_bank: [SPRITE.SPRITE_COUNT]Sprite
bg_music: rl.Music

draw :: proc {
	draw_sprite,
	draw_animated_sprite,
}


draw_animated_sprite :: proc(
	game: ^Game,
	position: Position,
	animation: ^Animation,
	direction: Vector2,
	team: ENTITY_TEAM,
) {
	if animation._current_frame >= animation.num_frames {
		animation._current_frame = 0
	}
	src_rec := rl.Rectangle {
		f32(animation.source_x + animation.w * f32(animation._current_frame)),
		f32(animation.source_y),
		animation.w,
		animation.h,
	}
	angle: f32 = 0.0
	switch animation.angle_type {
	case .LR:
		if direction.x <= 0 {
			src_rec.width *= -1
		}
	case .DIRECTIONAL:
		angle = angle_from_vector(direction) + animation.angle
	case .IGNORE:
	}

	dst_rec := rl.Rectangle {
		position.pos.x + position.size.x / 2,
		position.pos.y + position.size.y / 2,
		position.size.x,
		position.size.y,
	}

	origin := Vector2{position.size.x / 2, position.size.y / 2}
	rl.DrawTexturePro(animation.image^, src_rec, dst_rec, origin, angle, rl.WHITE)
	if game.draw_colliders {
		dst_rec.x -= position.size.x / 2
		dst_rec.y -= position.size.y / 2
		color := rl.WHITE
		switch team {
		case .NEUTRAL:
			color = rl.GRAY
		case .BAD:
			color = rl.RED
		case .GOOD:
			color = rl.BLUE
		}

		rl.DrawRectangleLinesEx(dst_rec, 1, color)
	}

	if animation._time_on_frame >= animation.frame_delay && animation.kind != .STATIC {
		animation._current_frame += 1
		animation._time_on_frame = 0
	}

	animation._time_on_frame += 1
}


draw_sprite :: proc(sprite: Sprite, position: Position) {
	src_rec := rl.Rectangle {
		sprite.src_rect.position.x,
		sprite.src_rect.position.y,
		sprite.src_rect.size.x,
		sprite.src_rect.size.y,
	}
	dst_rec := rl.Rectangle{position.pos.x, position.pos.y, position.size.x, position.size.y}
	origin := Vector2{position.size.x / 2, position.size.y / 2}
	rl.DrawTexturePro(sprite.image^, src_rec, dst_rec, origin, sprite.rotation, rl.WHITE)
}

load_animations :: proc() {
	animation_bank[ANIMATION.PLAYER] = Animation {
		image          = &atlas,
		w              = PLAYER_SIZE,
		h              = PLAYER_SIZE,
		source_x       = 0,
		source_y       = 0,
		angle          = 90,
		_current_frame = 0,
		num_frames     = 0,
		frame_delay    = 0,
		_time_on_frame = 0,
		padding        = {0, 0},
		offset         = {0, 0},
		kind           = .STATIC,
		angle_type     = .DIRECTIONAL,
		IMAGE_IDX      = int(ANIMATION.PLAYER),
	}

	animation_bank[ANIMATION.BULLET_G] = Animation {
		image          = &atlas,
		w              = 32,
		h              = 32,
		source_x       = 0,
		source_y       = 64,
		_current_frame = 0,
		num_frames     = 2,
		frame_delay    = 8,
		_time_on_frame = 0,
		angle          = 90,
		padding        = {0, 0},
		offset         = {0, 0},
		kind           = .REPEAT,
		angle_type     = .DIRECTIONAL,
		IMAGE_IDX      = int(ANIMATION.BULLET_G),
	}

	animation_bank[ANIMATION.BULLET_B] = Animation {
		image          = &atlas,
		w              = 32,
		h              = 32,
		source_x       = 64,
		source_y       = 64,
		_current_frame = 0,
		num_frames     = 2,
		frame_delay    = 8,
		angle          = 90,
		_time_on_frame = 0,
		padding        = {0, 0},
		offset         = {0, 0},
		kind           = .REPEAT,
		angle_type     = .DIRECTIONAL,
		IMAGE_IDX      = int(ANIMATION.BULLET_B),
	}

	animation_bank[ANIMATION.ENEMY_SHOT] = Animation {
		image          = &atlas,
		w              = 32,
		h              = 32,
		source_x       = 0,
		source_y       = 128,
		_current_frame = 0,
		num_frames     = 1,
		frame_delay    = 8,
		_time_on_frame = 0,
		padding        = {0, 0},
		offset         = {0, 0},
		kind           = .STATIC,
		angle_type     = .LR,
		IMAGE_IDX      = int(ANIMATION.ENEMY_SHOT),
	}

	animation_bank[ANIMATION.ENEMY_RUN] = Animation {
		image          = &atlas,
		w              = 32,
		h              = 32,
		source_x       = 32,
		source_y       = 128,
		_current_frame = 0,
		num_frames     = 4,
		frame_delay    = 8,
		_time_on_frame = 0,
		padding        = {0, 0},
		offset         = {0, 0},
		kind           = .REPEAT,
		angle_type     = .LR,
		IMAGE_IDX      = int(ANIMATION.ENEMY_RUN),
	}


	animation_bank[ANIMATION.BIG_EXPLOSION] = Animation {
		image          = &atlas,
		w              = 32,
		h              = 32,
		source_x       = 0,
		source_y       = 64,
		_current_frame = 0,
		num_frames     = 2,
		frame_delay    = 8,
		_time_on_frame = 0,
		padding        = {0, 0},
		offset         = {0, 0},
		kind           = .REPEAT,
		angle_type     = .DIRECTIONAL,
		IMAGE_IDX      = int(ANIMATION.BIG_EXPLOSION),
	}

	animation_bank[ANIMATION.CANDY] = Animation {
		image       = &tx_candy,
		w           = 16,
		h           = 16,
		source_x    = 0,
		source_y    = 0,
		num_frames  = 16,
		frame_delay = 4,
		kind        = .REPEAT,
		angle_type  = .IGNORE,
		IMAGE_IDX   = int(ANIMATION.CANDY),
	}

}


load_prefab_from_archetype :: proc(game: ^Game, archetype: ^Archetype, index: int) {
	mask := archetype.component_mask
	prefab_bank[PREFAB.LOADED_PREFAB].mask = mask
	for component in COMPONENT_ID {
		if !((mask & component) == component) {
			continue
		}
		switch component {
		case .POSITION:
			game.loaded_prefab.position = &archetype.positions[index]
		case .VELOCITY:
			game.loaded_prefab.velocity = &archetype.velocities[index]
		case .SPRITE:
			game.loaded_prefab.sprite = &archetype.sprites[index]
		case .ANIMATION:
			game.loaded_prefab.animation = &archetype.animations[index]
		case .DATA:
			game.loaded_prefab.data = &archetype.data[index]
		case .COLLIDER:
			game.loaded_prefab.collider = &archetype.colliders[index]
		case .IA:
			game.loaded_prefab.ia = &archetype.ias[index]
		case .COUNT:

		}

	}
}


load_sprites :: proc() {
	sprite_bank[SPRITE.PLAYER_IDLE] = Sprite {
		image     = &atlas,
		src_rect  = Rect{{0, 0}, {32, 32}},
		IMAGE_IDX = int(SPRITE.PLAYER_IDLE),
	}

	sprite_bank[SPRITE.PLAYER_EAT] = Sprite {
		image     = &atlas,
		src_rect  = Rect{{32, 0}, {32, 32}},
		IMAGE_IDX = int(SPRITE.PLAYER_EAT),
	}

	sprite_bank[SPRITE.BODY_STRAIGHT] = Sprite {
		image     = &atlas,
		src_rect  = Rect{{0, 32}, {32, 32}},
		rotation  = 90,
		IMAGE_IDX = int(SPRITE.BODY_STRAIGHT),
	}

	sprite_bank[SPRITE.BODY_TURN] = Sprite {
		image     = &atlas,
		src_rect  = Rect{{32, 32}, {32, 32}},
		IMAGE_IDX = int(SPRITE.BODY_TURN),
	}

	sprite_bank[SPRITE.TAIL] = Sprite {
		image     = &atlas,
		src_rect  = Rect{{32, 64}, {32, 32}},
		IMAGE_IDX = int(SPRITE.TAIL),
	}

	sprite_bank[SPRITE.BORDER] = Sprite {
		image     = &atlas,
		src_rect  = Rect{{0, 96}, {32, 32}},
		IMAGE_IDX = int(SPRITE.BORDER),
	}

	sprite_bank[SPRITE.CORNER] = Sprite {
		image     = &atlas,
		src_rect  = Rect{{32, 96}, {32, 32}},
		IMAGE_IDX = int(SPRITE.CORNER),
	}

	sprite_bank[SPRITE.BORDER_UP] = Sprite {
		&atlas,
		Rect{{0, 96}, {32, 32}},
		90,
		int(SPRITE.BORDER_UP),
	}
	// sprite_bank[SPRITE.BORDER_DOWN] = Sprite {
	// sprite_bank[SPRITE.BORDER_LEFT] = Sprite {
	// sprite_bank[SPRITE.BORDER_RIGHT] = Sprite {
	//

}


unload_atlas :: proc() {
	rl.UnloadTexture(atlas)
}
