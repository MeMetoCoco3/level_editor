package main
import "core:fmt"
import "core:math"
import rl "vendor:raylib"


DrawCollidersSystem :: proc(game: ^Game) {
	arquetypes, is_empty := query_archetype(game.world, COMPONENT_ID.COLLIDER)
	if is_empty {
		fmt.println("IS EMPTY")
		return
	}

	for arquetype in arquetypes {
		colliders := arquetype.colliders
		for i in 0 ..< len(arquetype.entities_id) {
			team := arquetype.data[i].team
			color := rl.WHITE

			switch team {
			case .NEUTRAL:
				color = rl.GRAY
			case .BAD:
				color = rl.RED
			case .GOOD:
				color = rl.BLUE
			}

			rect := rl.Rectangle {
				x      = colliders[i].position.x,
				y      = colliders[i].position.y,
				width  = f32(colliders[i].w),
				height = f32(colliders[i].h),
			}
			rl.DrawRectangleRec(rect, color)
		}
	}
}

RenderingSystem :: proc(game: ^Game) {
	arquetypes, is_empty := query_archetype(game.world, COMPONENT_ID.POSITION | .SPRITE)
	if !is_empty {
		for arquetype in arquetypes {
			positions := arquetype.positions
			sprites := arquetype.sprites
			for i in 0 ..< len(arquetype.entities_id) {
				draw(sprites[i], positions[i])
			}
		}
	}


	arquetypes, is_empty = query_archetype(game.world, COMPONENT_ID.POSITION | .ANIMATION)
	if !is_empty {
		for arquetype in arquetypes {
			positions := arquetype.positions
			animations := arquetype.animations
			direction := Vector2{0, 0}
			team := arquetype.data


			for i in 0 ..< len(arquetype.entities_id) {
				draw(game, positions[i], &animations[i], direction, team[i].team)
			}
		}
	}
}


point_in_rect :: proc(p: Vector2, pos: Position) -> bool {
	return(
		p.x >= pos.pos.x &&
		p.x <= pos.pos.x + pos.size.x &&
		p.y >= pos.pos.y &&
		p.y <= pos.pos.y + pos.size.y \
	)
}
