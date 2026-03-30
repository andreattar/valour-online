extends RefCounted
## Procedural pixel placeholders until production art (e.g. PixelLab) is wired in.


static func make_character_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	var dirs: Array[String] = ["south", "north", "east", "west"]
	for d in dirs:
		var idle := "idle_" + d
		sf.add_animation(idle)
		sf.set_animation_loop(idle, true)
		sf.add_frame(idle, _tex(d, false), 0.4)
		var walk := "walk_" + d
		sf.add_animation(walk)
		sf.set_animation_loop(walk, true)
		sf.add_frame(walk, _tex(d, false), 0.12)
		sf.add_frame(walk, _tex(d, true), 0.12)
	return sf


static func make_slime_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation(&"idle")
	sf.set_animation_loop(&"idle", true)
	sf.add_frame(&"idle", _slime_tex(false), 0.35)
	sf.add_frame(&"idle", _slime_tex(true), 0.35)
	return sf


static func _tex(dir_name: String, alt: bool) -> Texture2D:
	var base := Color(0.85, 0.68, 0.52, 1.0)
	match dir_name:
		"north":
			base = base.lightened(0.08)
		"east", "west":
			base = base.darkened(0.05)
	if alt:
		base = base.lightened(0.06)
	var img := Image.create(28, 44, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(44):
		for x in range(28):
			var dx := absf(x - 14.0) / 14.0
			var dy := float(y) / 44.0
			if dx * dx * 0.85 + dy * dy < 0.92:
				img.set_pixel(x, y, base)
	return ImageTexture.create_from_image(img)


static func _slime_tex(alt: bool) -> Texture2D:
	var c := Color(0.35, 0.75, 0.42, 1.0) if not alt else Color(0.4, 0.82, 0.48, 1.0)
	var img := Image.create(24, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(20):
		for x in range(24):
			var dx := absf(x - 12.0) / 12.0
			var dy := float(y) / 20.0
			if dx * dx + dy * dy < 0.95:
				img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func make_rat_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation(&"idle")
	sf.set_animation_loop(&"idle", true)
	sf.add_frame(&"idle", _rat_tex(false), 0.25)
	sf.add_frame(&"idle", _rat_tex(true), 0.25)
	return sf


static func _rat_tex(alt: bool) -> Texture2D:
	var c := Color(0.45, 0.35, 0.28, 1.0) if not alt else Color(0.5, 0.4, 0.32, 1.0)
	var img := Image.create(20, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(16):
		for x in range(20):
			var dx := absf(x - 10.0) / 10.0
			var dy := absf(y - 8.0) / 8.0
			if dx * dx * 0.6 + dy * dy * 0.8 < 0.85:
				img.set_pixel(x, y, c)
	for x in range(3, 8):
		img.set_pixel(x, 7, c.darkened(0.2))
		img.set_pixel(x, 8, c.darkened(0.2))
	return ImageTexture.create_from_image(img)


static func make_skeleton_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation(&"idle")
	sf.set_animation_loop(&"idle", true)
	sf.add_frame(&"idle", _skeleton_tex(false), 0.4)
	sf.add_frame(&"idle", _skeleton_tex(true), 0.4)
	return sf


static func _skeleton_tex(alt: bool) -> Texture2D:
	var c := Color(0.9, 0.88, 0.82, 1.0) if not alt else Color(0.85, 0.83, 0.78, 1.0)
	var img := Image.create(24, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(10):
		for x in range(8, 16):
			var dx := absf(x - 12.0) / 4.0
			var dy := absf(y - 5.0) / 5.0
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(x, y, c)
	for y in range(10, 28):
		for x in range(10, 14):
			img.set_pixel(x, y, c.darkened(0.1))
	for y in range(28, 36):
		for x in range(8, 10):
			img.set_pixel(x, y, c.darkened(0.15))
		for x in range(14, 16):
			img.set_pixel(x, y, c.darkened(0.15))
	for y in range(12, 20):
		for x in range(4, 8):
			img.set_pixel(x, y, c.darkened(0.1))
		for x in range(16, 20):
			img.set_pixel(x, y, c.darkened(0.1))
	return ImageTexture.create_from_image(img)
