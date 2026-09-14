extends Node2D
## S1 아레나. 엔진 상태를 즉시 그린다. P0 적·FX 텍스처는 시각만 담당.

var engine: CombatEngine
var pulse: float = 0.0
var muzzle: float = 0.0
var shake: float = 0.0

var _enemy_sprites: Dictionary = {}
var _seen_alive: Dictionary = {}
var _fx: Array[Dictionary] = []
var _layer: Node2D
var _player_sprite: Sprite2D


func _ready() -> void:
	_layer = Node2D.new()
	_layer.name = "P0Sprites"
	add_child(_layer)
	_player_sprite = Sprite2D.new()
	_player_sprite.name = "PlayerSprite"
	_player_sprite.centered = true
	_player_sprite.flip_h = true
	_player_sprite.texture = P0Art.player()
	_player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_layer.add_child(_player_sprite)


func _wh() -> Vector2:
	if get_parent() is Control:
		var s: Vector2 = (get_parent() as Control).size
		if s.x > 8.0 and s.y > 8.0:
			return s
	return Vector2(1280, 400)


func _process(delta: float) -> void:
	pulse += delta
	muzzle = maxf(0.0, muzzle - delta * 6.0)
	shake = maxf(0.0, shake - delta * 18.0)
	_sync_enemy_art()
	_sync_player_art()
	_tick_fx(delta)
	queue_redraw()


func kick(shot: bool) -> void:
	muzzle = 1.0
	shake = 1.0 if shot else 0.55


func reset_visuals() -> void:
	for id in _enemy_sprites.keys():
		var spr: Sprite2D = _enemy_sprites[id]
		if is_instance_valid(spr):
			spr.queue_free()
	_enemy_sprites.clear()
	_seen_alive.clear()
	for item in _fx:
		var node: Node = item.get("node")
		if node != null and is_instance_valid(node):
			node.queue_free()
	_fx.clear()


func _draw() -> void:
	var wh := _wh()
	var W: float = wh.x
	var H: float = wh.y
	var ox := sin(pulse * 33.0) * shake * 4.0
	draw_rect(Rect2(0, 0, W, H), Color(0.04, 0.06, 0.08, 1))
	draw_rect(Rect2(0, H - 86, W, 86), Color(0.09, 0.11, 0.14, 1))
	for i in range(0, 18):
		var x := 40.0 + i * 72.0
		var stripe := PackedVector2Array([
			Vector2(x, H - 86), Vector2(x + 28, H - 86),
			Vector2(x - 10, H), Vector2(x - 38, H),
		])
		draw_colored_polygon(stripe, Color(0.84, 0.89, 0.29, 0.22 if i % 2 == 0 else 0.08))
	draw_rect(Rect2(0, 0, W, 48), Color(0.07, 0.09, 0.12, 1))
	draw_line(Vector2(0, 48), Vector2(W, 48), Color(0.24, 0.89, 0.78, 0.35), 2.0)
	for i in range(6):
		var lx := 90.0 + i * 200.0
		var glow := 0.08 + 0.04 * sin(pulse * 2.2 + i)
		draw_circle(Vector2(lx, 28), 10.0, Color(0.24, 0.89, 0.78, glow))
	if engine == null:
		return
	_draw_player(ox, H)
	for e in engine.enemies:
		if e.alive:
			_draw_enemy_chrome(e, ox, H)


func _draw_player(ox: float, H: float) -> void:
	if engine.player.is_empty() or not engine.player.has("x"):
		return
	var x: float = engine.player.x + ox
	var y := H - 132.0
	var has_sprite := _player_sprite != null and _player_sprite.texture != null
	if not has_sprite:
		var body := Color(0.24, 0.88, 0.78)
		if engine.ibeonman:
			body = Color(0.84, 0.89, 0.29)
		draw_circle(Vector2(x, y - 46), 16.0, body)
		draw_rect(Rect2(x - 14, y - 30, 28, 46), body)
		draw_rect(Rect2(x + 10, y - 18, 36 + muzzle * 10.0, 6), Color(0.84, 0.89, 0.29))
	if muzzle > 0.0:
		draw_circle(Vector2(x + 52, y - 15), 8.0 + muzzle * 10.0, Color(1, 0.92, 0.4, muzzle))
	var ratio: float = clampf(engine.player.hp / engine.player.max_hp, 0.0, 1.0)
	draw_rect(Rect2(x - 22, y + 22, 44, 5), Color(0.15, 0.16, 0.18))
	draw_rect(Rect2(x - 22, y + 22, 44.0 * ratio, 5), Color(0.24, 0.88, 0.78))


func _enemy_feet(e: Dictionary, ox: float, H: float) -> Vector2:
	var x: float = e.x + ox
	var y := H - 128.0
	if e.kind == "runner":
		y += 6.0
	elif e.kind == "boss":
		y -= 10.0
	return Vector2(x, y)


func _draw_enemy_chrome(e: Dictionary, ox: float, H: float) -> void:
	var feet := _enemy_feet(e, ox, H)
	var r: float = e.radius
	var spr: Sprite2D = _enemy_sprites.get(int(e.id))
	if spr == null or spr.texture == null:
		var col := Color(0.89, 0.23, 0.29)
		if e.kind == "runner":
			col = Color(0.95, 0.38, 0.22)
		elif e.kind == "brute":
			col = Color(0.62, 0.12, 0.22)
		elif e.kind == "boss":
			col = Color(0.72, 0.08, 0.2)
		draw_circle(feet, r, col)
		draw_circle(Vector2(feet.x - r * 0.35, feet.y - r * 0.2), r * 0.22, Color(0.12, 0.02, 0.04))
		draw_circle(Vector2(feet.x + r * 0.3, feet.y - r * 0.15), r * 0.18, Color(0.12, 0.02, 0.04))
	if e.shielded:
		draw_arc(feet, r + 18.0, 0.0, TAU, 28, Color(0.45, 0.75, 1.0, 0.7), 3.0)
	var ratio: float = clampf(e.hp / e.max_hp, 0.0, 1.0)
	draw_rect(Rect2(feet.x - r, feet.y + 10, r * 2.0, 4), Color(0.12, 0.08, 0.08))
	draw_rect(Rect2(feet.x - r, feet.y + 10, r * 2.0 * ratio, 4), Color(0.89, 0.23, 0.29))


func _sync_enemy_art() -> void:
	if engine == null:
		return
	var living: Dictionary = {}
	var ox := sin(pulse * 33.0) * shake * 4.0
	var H := _wh().y
	for e in engine.enemies:
		if not e.alive:
			continue
		var eid := int(e.id)
		living[eid] = {
			"x": e.x,
			"kind": e.kind,
			"radius": e.radius,
		}
		_place_enemy_sprite(e, ox, H)
	for eid in _seen_alive.keys():
		if not living.has(eid):
			var prev: Dictionary = _seen_alive[eid]
			_spawn_kill_scrap_fx(float(prev.x), H)
			_free_enemy_sprite(eid)
	for eid in _enemy_sprites.keys():
		if not living.has(eid):
			_free_enemy_sprite(eid)
	_seen_alive = living


func _place_enemy_sprite(e: Dictionary, ox: float, H: float) -> void:
	var eid := int(e.id)
	var spr: Sprite2D = _enemy_sprites.get(eid)
	var src := P0Art.tex(P0Art.ENEMIES_SHEET)
	var use_atlas := P0Art.is_p0_sheet(src)
	var region := P0Art.enemy_region(String(e.kind), eid)
	if spr == null:
		spr = Sprite2D.new()
		spr.texture = src
		spr.centered = false
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_layer.add_child(spr)
		_enemy_sprites[eid] = spr
	if spr.texture == null:
		spr.visible = false
		return
	spr.visible = true
	var frame_h: float
	var frame_w: float
	if use_atlas:
		spr.region_enabled = true
		spr.region_rect = region
		frame_w = region.size.x
		frame_h = region.size.y
	else:
		spr.region_enabled = false
		frame_w = float(spr.texture.get_width())
		frame_h = float(spr.texture.get_height())
	var target_h: float = float(e.radius) * 6.8
	var s: float = target_h / maxf(frame_h, 1.0)
	if e.kind == "boss":
		s *= 1.2
	spr.scale = Vector2(s, s)
	var feet := _enemy_feet(e, ox, H)
	spr.position = Vector2(feet.x - frame_w * 0.5 * s, feet.y - frame_h * s)


func _free_enemy_sprite(eid: int) -> void:
	if _enemy_sprites.has(eid):
		var spr: Sprite2D = _enemy_sprites[eid]
		if is_instance_valid(spr):
			spr.queue_free()
		_enemy_sprites.erase(eid)


func _spawn_kill_scrap_fx(x: float, H: float) -> void:
	var y := H - 150.0
	_push_fx(P0Art.fx_kill(), Vector2(x, y - 8.0), 0.22, 0.4, Vector2(0, -20))
	_push_fx(P0Art.fx_scrap(), Vector2(x + 22.0, y - 36.0), 0.2, 0.55, Vector2(6, -40))


func _sync_player_art() -> void:
	if _player_sprite == null:
		return
	if engine == null or engine.player.is_empty() or not engine.player.has("x") or _player_sprite.texture == null:
		_player_sprite.visible = false
		return
	_player_sprite.visible = true
	var tex: Texture2D = _player_sprite.texture
	var frame_h := float(tex.get_height())
	var target_h := 152.0
	var s: float = target_h / maxf(frame_h, 1.0)
	_player_sprite.scale = Vector2(s, s)
	var ox := sin(pulse * 33.0) * shake * 4.0
	var H := _wh().y
	var feet := Vector2(engine.player.x + ox, H - 132.0)
	_player_sprite.position = Vector2(feet.x, feet.y - frame_h * s * 0.5)
	if engine.ibeonman:
		_player_sprite.modulate = Color(1.08, 1.05, 0.72)
	else:
		_player_sprite.modulate = Color.WHITE


func _push_fx(tex: Texture2D, pos: Vector2, scale: float, life: float, drift: Vector2) -> void:
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = true
	spr.scale = Vector2(scale, scale)
	spr.position = pos
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_layer.add_child(spr)
	_fx.append({
		"node": spr,
		"t": 0.0,
		"life": life,
		"origin": pos,
		"drift": drift,
		"base_scale": Vector2(scale, scale),
	})


func _tick_fx(delta: float) -> void:
	var keep: Array[Dictionary] = []
	for item in _fx:
		var node: Sprite2D = item.node
		if node == null or not is_instance_valid(node):
			continue
		item.t = float(item.t) + delta
		var life: float = float(item.life)
		var u: float = clampf(float(item.t) / life, 0.0, 1.0)
		node.position = item.origin + item.drift * u
		node.modulate.a = 1.0 - u
		node.scale = item.base_scale * (1.0 + 0.35 * u)
		if float(item.t) < life:
			keep.append(item)
		else:
			node.queue_free()
	_fx = keep
