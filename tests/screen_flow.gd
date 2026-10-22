extends RefCounted

static func settle(game: Node) -> void:
	while not game.transition_phase.is_empty():
		if game.orientation_blocked:
			return
		game.advance_presentation(game.TRANSITION_TIME)

static func skip_intro(game: Node) -> void:
	settle(game)
	if game.state == "play_menu":
		game.handle_primary_press(game.beginning_button.get_center())
		settle(game)
	if game.state == "intro":
		game.handle_primary_press(game.skip_button.get_center())
		settle(game)
	game.advance_presentation(game.PLANET_SPIN_TIME)
