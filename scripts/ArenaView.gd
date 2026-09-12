extends Node2D
## S1 아레나. 엔진 상태를 즉시 그린다.

var engine: CombatEngine
var pulse: float = 0.0
var muzzle: float = 0.0
var shake: float = 0.0

const H := 400.0
const W := 1280.0


func _process(delta: float) -> void:
	pulse += delta
	muzzle = maxf(0.0, muzzle - delta * 6.0)
	shake = maxf(0.0, shake - delta * 18.0)
	queue_redraw()


func kick(shot: bool) -> void:
	muzzle = 1.0
	shake = 1.0 if shot else 0.55


func _draw() -> void:
	var ox := sin(pulse * 33.0) * shake * 4.0
	draw_rect(Rect2(0, 0, W, H), Color(0.04, 0.06, 0.08, 1))
	# floor
	draw_rect(Rect2(0, H - 86, W, 86), Color(0.09, 0.11, 0.14, 1))
	for i in range(0, 18):
		var x := 40.0 + i * 72.0
		var stripe := PackedVector2Array([
			Vector2(x, H - 86), Vector2(x + 28, H - 86),
			Vector2(x - 10, H), Vector2(x - 38, H),
		])
		draw_colored_polygon(stripe, Color(0.84, 0.89, 0.29, 0.22 if i % 2 == 0 else 0.08))
	# far wall
	draw_rect(Rect2(0, 0, W, 48), Color(0.07, 0.09, 0.12, 1))
	draw_line(Vector2(0, 48), Vector2(W, 48), Color(0.24, 0.89, 0.78, 0.35), 2.0)
	# containment lights
	for i in range(6):
		var lx := 90.0 + i * 200.0
		var glow := 0.08 + 0.04 * sin(pulse * 2.2 + i)
		draw_circle(Vector2(lx, 28), 10.0, Color(0.24, 0.89, 0.78, glow))
	if engine == null:
		return
	_draw_player(ox)
	for e in engine.enemies:
		if e.alive:
			_draw_enemy(e, ox)


func _draw_player(ox: float) -> void:
	var x: float = engine.player.x + ox
	var y := H - 132.0
	var body := Color(0.24, 0.88, 0.78)
	if engine.ibeonman:
		body = Color(0.95, 0.86, 0.32)
	draw_circle(Vector2(x, y - 46), 16.0, body)
	draw_rect(Rect2(x - 14, y - 30, 28, 46), body)
	draw_rect(Rect2(x + 10, y - 18, 36 + muzzle * 10.0, 6), Color(0.84, 0.89, 0.29))
	if muzzle > 0.0:
		draw_circle(Vector2(x + 52, y - 15), 8.0 + muzzle * 10.0, Color(1, 0.92, 0.4, muzzle))
	# hp pip
	var ratio: float = clampf(engine.player.hp / engine.player.max_hp, 0.0, 1.0)
	draw_rect(Rect2(x - 22, y + 22, 44, 5), Color(0.15, 0.16, 0.18))
	draw_rect(Rect2(x - 22, y + 22, 44.0 * ratio, 5), Color(0.24, 0.88, 0.78))


func _draw_enemy(e: Dictionary, ox: float) -> void:
	var x: float = e.x + ox
	var y := H - 128.0
	var r: float = e.radius
	var col := Color(0.89, 0.23, 0.29)
	if e.kind == "runner":
		col = Color(0.95, 0.38, 0.22)
		y += 6.0
	elif e.kind == "brute":
		col = Color(0.62, 0.12, 0.22)
	elif e.kind == "boss":
		col = Color(0.72, 0.08, 0.2)
		y -= 10.0
	draw_circle(Vector2(x, y), r, col)
	draw_circle(Vector2(x - r * 0.35, y - r * 0.2), r * 0.22, Color(0.12, 0.02, 0.04))
	draw_circle(Vector2(x + r * 0.3, y - r * 0.15), r * 0.18, Color(0.12, 0.02, 0.04))
	if e.shielded:
		draw_arc(Vector2(x, y), r + 8.0, 0.0, TAU, 28, Color(0.45, 0.75, 1.0, 0.7), 3.0)
	var ratio: float = clampf(e.hp / e.max_hp, 0.0, 1.0)
	draw_rect(Rect2(x - r, y + r + 8, r * 2.0, 4), Color(0.12, 0.08, 0.08))
	draw_rect(Rect2(x - r, y + r + 8, r * 2.0 * ratio, 4), Color(0.89, 0.23, 0.29))
