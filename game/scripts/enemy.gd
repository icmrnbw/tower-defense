class_name Enemy
extends Node2D
## A creep walking (or flying) along a Curve2D. Stats and abilities come from data/enemies.json.

signal died(enemy: Enemy)
signal leaked(enemy: Enemy)

const SPEED_UNIT := 55.0  # pixels per second for speed 1.0
const OUTLINE := Color(0.11, 0.09, 0.14)

var game: Node
var enemy_id := ""
var def: Dictionary = {}
var hp_mult := 1.0
var max_hp := 1.0
var hp := 1.0
var max_shield := 0.0
var shield := 0.0
var armor := 0.0
var flying := false
var is_boss := false
var stealth := false
var slow_immune := false
var regen := 0.0
var gold := 0
var lives_cost := 1
var radius := 12.0
var color := Color.WHITE
var speed := 50.0
var speed_mult := 1.0
var resist: Dictionary = {}

var curve: Curve2D
var path_index := 0
var path_length := 1.0
var progress := 0.0
var facing := 0.0
var alive := true
var used_rifts: Dictionary = {}

# status effects
var slow_amount := 0.0
var slow_time := 0.0
var freeze_time := 0.0
var shatter_bonus := 0.0
var stun_time := 0.0
var burn_dps := 0.0
var burn_time := 0.0
var burn_spreads := false
var poison_stacks := 0
var poison_dps := 0.0
var poison_time := 0.0
var poison_spreads := false
var shred := 0.0
var shred_time := 0.0
var revealed_time := 0.0
var burrowed_time := 0.0
var harden_time := 0.0
var harden_armor := 0.0
var flash_time := 0.0
var anim := 0.0

var abilities: Array = []  # [{def, timer, done}]

# art: a rigged monster (art/monsters) when one exists, else the old vector blob
var rig: MonsterRig
var walk_phase := 0.0
var flip := 1.0
var spawn_time := 0.0
var cast_time := 0.0
var hit_time := 0.0
var last_hit_gold_mult := 1.0


func setup(game_ref: Node, id: String, mult: float, path_curve: Curve2D, index: int, start_progress: float = 0.0) -> void:
	game = game_ref
	enemy_id = id
	def = Data.enemies[id]
	hp_mult = mult
	max_hp = float(def["hp"]) * mult
	hp = max_hp
	max_shield = float(def.get("shield", 0.0)) * mult
	shield = max_shield
	armor = float(def.get("armor", 0.0))
	flying = def.get("flying", false)
	is_boss = def.get("boss", false)
	stealth = def.get("stealth", false)
	slow_immune = def.get("slow_immune", false)
	regen = float(def.get("regen", 0.0))
	gold = int(def["gold"])
	lives_cost = int(def.get("lives", 1))
	radius = float(def.get("radius", 12))
	color = Color(def.get("color", "#ffffff"))
	speed = float(def["speed"]) * SPEED_UNIT
	resist = def.get("resist", {}).duplicate()
	for key in game.level_resist:
		if not is_boss:
			resist[key] = maxf(float(resist.get(key, 0.0)), float(game.level_resist[key]))
	for a in def.get("abilities", []):
		abilities.append({"def": a, "timer": float(a.get("interval", 0.0)) * randf_range(0.6, 1.0), "done": []})
	curve = path_curve
	path_index = index
	path_length = maxf(curve.get_baked_length(), 1.0)
	progress = start_progress
	position = curve.sample_baked(progress)
	z_index = 2 if flying else 0
	rig = MonsterRig.get_rig(String(def.get("art", id)))
	walk_phase = randf() * TAU
	add_to_group("enemies")


# ---------------------------------------------------------------- queries

func targetable() -> bool:
	return alive and burrowed_time <= 0.0 and (not stealth or revealed_time > 0.0)


func hittable_by_area() -> bool:
	return alive and burrowed_time <= 0.0


func progress_ratio() -> float:
	return progress / path_length


func hp_ratio() -> float:
	return hp / max_hp


func effective_armor() -> float:
	return clampf(armor + harden_armor * float(harden_time > 0.0) - shred, 0.0, 0.9)


func current_speed() -> float:
	if freeze_time > 0.0 or stun_time > 0.0:
		return 0.0
	var v := speed * speed_mult * (1.0 - slow_amount)
	if not flying:
		v *= game.ice_factor(position)
	return v


# ---------------------------------------------------------------- update

func _process(delta: float) -> void:
	if not alive:
		return
	flash_time = maxf(flash_time - delta, 0.0)
	spawn_time += delta
	cast_time = maxf(cast_time - delta, 0.0)
	hit_time = maxf(hit_time - delta, 0.0)
	freeze_time = maxf(freeze_time - delta, 0.0)
	stun_time = maxf(stun_time - delta, 0.0)
	revealed_time = maxf(revealed_time - delta, 0.0)
	burrowed_time = maxf(burrowed_time - delta, 0.0)
	harden_time = maxf(harden_time - delta, 0.0)
	if slow_time > 0.0:
		slow_time -= delta
		if slow_time <= 0.0:
			slow_amount = 0.0
	if shred_time > 0.0:
		shred_time -= delta
		if shred_time <= 0.0:
			shred = 0.0
	_tick_dots(delta)
	if not alive:
		return
	_update_abilities(delta)

	var v := current_speed()
	progress += v * delta
	anim += delta * (1.0 + v * 0.05)
	_check_rifts()
	if progress >= path_length:
		alive = false
		leaked.emit(self)
		queue_free()
		return
	var p := curve.sample_baked(progress)
	var ahead := curve.sample_baked(minf(progress + 6.0, path_length))
	if ahead.distance_squared_to(p) > 0.01:
		facing = (ahead - p).angle()
		var dx := (ahead - p).normalized().x
		if absf(dx) > 0.25:
			flip = signf(dx)
	if rig:
		walk_phase += v * delta / maxf(float(rig.motion.get("stride", 40.0)) * rig.unit_scale(radius), 1.0) * TAU
	position = p
	queue_redraw()


func _tick_dots(delta: float) -> void:
	var dot := 0.0
	if burn_time > 0.0:
		burn_time -= delta
		dot += burn_dps * delta * (1.0 - float(resist.get("fire", 0.0)))
	if poison_time > 0.0:
		poison_time -= delta
		dot += poison_dps * poison_stacks * delta * (1.0 - float(resist.get("poison", 0.0)))
		if poison_time <= 0.0:
			poison_stacks = 0
	elif regen > 0.0 and burn_time <= 0.0 and hp < max_hp:
		hp = minf(hp + max_hp * regen * delta, max_hp)
	if dot > 0.0:
		hp -= dot
		if hp <= 0.0:
			_die()


func _check_rifts() -> void:
	for i in game.rifts.size():
		var r: Dictionary = game.rifts[i]
		if flying or used_rifts.has(i) or int(r["path"]) != path_index:
			continue
		if progress_ratio() >= float(r["at"]):
			used_rifts[i] = true
			var to := int(r["to_path"])
			game.spawn_rift_fx(position)
			curve = game.paths[to]
			path_index = to
			path_length = maxf(curve.get_baked_length(), 1.0)
			progress = float(r["to"]) * path_length
			position = curve.sample_baked(progress)
			game.spawn_rift_fx(position)
			return


func _update_abilities(delta: float) -> void:
	for a in abilities:
		var d: Dictionary = a["def"]
		var kind: String = d["type"]
		if kind == "shed":
			for t in d["thresholds"]:
				if hp_ratio() <= float(t) and not t in a["done"]:
					a["done"].append(t)
					armor = maxf(armor - float(d["armor_loss"]), 0.0)
					speed_mult += float(d["speed_gain"])
					game.flash_text(position, "ENRAGED", Color(1, 0.4, 0.3))
			continue
		if hp_ratio() > float(d.get("below", 1.01)):
			continue
		a["timer"] -= delta
		if a["timer"] > 0.0:
			continue
		a["timer"] = float(d.get("interval", 1.0))
		cast_time = 0.6
		match kind:
			"harden":
				harden_time = float(d["duration"])
				harden_armor = float(d.get("armor", 0.35))
			"burrow":
				burrowed_time = float(d["duration"])
			"burrow_jump":
				burrowed_time = float(d["duration"])
				progress = minf(progress + float(d["jump"]), path_length - 40.0)
			"heal":
				for e in game.enemies_near(position, float(d["radius"])):
					if e != self and not e.is_boss:
						e.hp = minf(e.hp + e.max_hp * float(d["pct"]), e.max_hp)
				game.spawn_ring(position, float(d["radius"]), Color(0.4, 1.0, 0.6))
			"shield_aura":
				for e in game.enemies_near(position, float(d["radius"])):
					e.shield = minf(e.shield + float(d["amount"]) * hp_mult, maxf(e.max_shield, float(d["amount"]) * hp_mult * 2.0))
				game.spawn_ring(position, float(d["radius"]), Color(0.4, 0.6, 1.0))
			"summon":
				for i in int(d["count"]):
					game.spawn_enemy_at(String(d["enemy"]), curve, path_index, maxf(progress - 20.0 - i * 18.0, 0.0), hp_mult)
			"drop":
				var spot: Array = game.ground_spot_near(position)
				if not spot.is_empty():
					for i in int(d["count"]):
						game.spawn_enemy_at(String(d["enemy"]), spot[0], spot[1], maxf(spot[2] - i * 20.0, 0.0), hp_mult)
			"freeze_tower":
				var t: Tower = game.nearest_tower(position, float(d.get("radius", 220.0)))
				if t:
					t.disable(float(d["duration"]), Color(0.6, 0.9, 1.0))
			"emp":
				for t in game.towers_near(position, float(d["radius"])):
					t.disable(float(d["duration"]), Color(0.9, 0.4, 1.0))
				game.spawn_ring(position, float(d["radius"]), Color(0.9, 0.4, 1.0))
			"teleport":
				if game.paths.size() > 1:
					var to: int = (path_index + 1 + randi() % (game.paths.size() - 1)) % game.paths.size()
					var ratio := progress_ratio()
					game.spawn_rift_fx(position)
					curve = game.paths[to]
					path_index = to
					path_length = maxf(curve.get_baked_length(), 1.0)
					progress = ratio * path_length
					position = curve.sample_baked(progress)
					game.spawn_rift_fx(position)


# ---------------------------------------------------------------- effects

func apply_slow(amount: float, duration: float) -> void:
	if slow_immune:
		return
	amount *= 1.0 - float(resist.get("frost", 0.0))
	if is_boss:
		duration *= 0.5
	slow_amount = maxf(slow_amount, amount) if slow_time > 0.0 else amount
	slow_time = maxf(slow_time, duration)


func apply_freeze(duration: float, shatter: float) -> void:
	if is_boss or slow_immune or resist.get("frost", 0.0) >= 1.0:
		return
	freeze_time = maxf(freeze_time, duration)
	shatter_bonus = shatter


func apply_stun(duration: float) -> void:
	if is_boss:
		duration *= 0.5
	stun_time = maxf(stun_time, duration)


func apply_burn(dps: float, duration: float, spreads: bool) -> void:
	burn_dps = maxf(burn_dps if burn_time > 0.0 else 0.0, dps)
	burn_time = maxf(burn_time, duration)
	burn_spreads = burn_spreads or spreads


func apply_poison(dps: float, duration: float, max_stacks: int, spreads: bool) -> void:
	poison_dps = maxf(poison_dps if poison_time > 0.0 else 0.0, dps)
	poison_stacks = mini(poison_stacks + 1, max_stacks)
	poison_time = duration
	poison_spreads = poison_spreads or spreads


func apply_shred(amount: float, duration: float) -> void:
	shred = maxf(shred, amount)
	shred_time = maxf(shred_time, duration)


func reveal(duration: float = 0.3) -> void:
	revealed_time = maxf(revealed_time, duration)


## Applies damage after shields, armor and resistances. Returns damage dealt to HP.
func take_damage(amount: float, damage_type: String, opts: Dictionary = {}) -> float:
	if not alive:
		return 0.0
	var dmg := amount * (1.0 - float(resist.get(damage_type, 0.0)))
	if freeze_time > 0.0:
		dmg *= 1.0 + shatter_bonus
	if opts.get("shield_break", false) and shield > 0.0:
		shield = 0.0
		game.spawn_ring(position, radius * 2.0, Color(0.5, 0.7, 1.0))
	if shield > 0.0:
		var soak := dmg * (0.5 if damage_type == "energy" else 1.0)
		if soak <= shield:
			shield -= soak
			flash_time = 0.04
			return 0.0
		dmg = (soak - shield) / (0.5 if damage_type == "energy" else 1.0)
		shield = 0.0
	if damage_type == "physical":
		dmg *= 1.0 - effective_armor() * (1.0 - float(opts.get("armor_pierce", 0.0)))
	hp -= dmg
	flash_time = 0.06
	hit_time = 0.12
	if stealth:
		reveal(1.5)  # area hits briefly expose stealthed enemies
	last_hit_gold_mult = maxf(float(opts.get("gold_mult", 1.0)), 1.0)
	if hp <= 0.0:
		_die()
	return dmg


func _die() -> void:
	if not alive:
		return
	alive = false
	var split: Dictionary = def.get("split", {})
	if not split.is_empty() and not flying:
		for i in int(split["count"]):
			game.spawn_enemy_at(String(split["enemy"]), curve, path_index, maxf(progress - i * 16.0, 0.0), hp_mult)
	if burn_spreads or poison_spreads:
		for e in game.enemies_near(position, 70.0):
			if e != self:
				if burn_spreads:
					e.apply_burn(burn_dps, 2.0, false)
				if poison_spreads:
					e.apply_poison(poison_dps, 3.0, 5, false)
	if rig and get_parent():
		var corpse := MonsterCorpse.new()
		corpse.setup(self)
		get_parent().add_child(corpse)
	died.emit(self)
	queue_free()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	if rig and burrowed_time <= 0.0:
		_draw_rig()
	else:
		_draw_blob()
	_draw_status()


## Where the rig's feet go, relative to the path point.
func feet() -> Vector2:
	return Vector2(0, radius * (1.6 if flying else 0.85))


func rig_scale() -> float:
	var sc := rig.unit_scale(radius)
	var pop := clampf(spawn_time / 0.25, 0.0, 1.0)
	return sc * (0.4 + 0.6 * pop + 0.12 * sin(pop * PI))


func status_overlay() -> Color:
	if flash_time > 0.0:
		return Color(1, 1, 1, 0.85)
	if freeze_time > 0.0:
		return Color(0.65, 0.92, 1.0, 0.65)
	if harden_time > 0.0:
		return Color(1.0, 0.85, 0.25, 0.35 + 0.15 * sin(anim * 8.0))
	if burn_time > 0.0:
		return Color(1.0, 0.45, 0.1, 0.25 + 0.12 * sin(anim * 20.0))
	if poison_time > 0.0:
		return Color(0.5, 1.0, 0.2, 0.35)
	if slow_amount > 0.0:
		return Color(0.45, 0.75, 1.0, 0.3)
	return Color(1, 1, 1, 0)


func _draw_rig() -> void:
	var alpha := 0.3 if stealth and revealed_time <= 0.0 else 1.0
	var sc := rig_scale()
	var squash := Vector2(1.0 + hit_time * 1.2, 1.0 - hit_time * 1.0)
	var lift := Vector2.ZERO
	if flying:
		draw_set_transform(Vector2(2, radius + 4), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, radius * 0.9, Color(0, 0, 0, 0.22 * alpha))
		draw_set_transform(Vector2.ZERO, 0.0)
	var base := Transform2D(0.0, Vector2(flip * squash.x, squash.y) * sc, 0.0, feet() + lift)
	if is_boss:
		var pulse := 0.5 + 0.5 * sin(anim * 3.0)
		draw_set_transform(feet(), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, radius * 1.5, Color(color, 0.12 + 0.08 * pulse))
		draw_arc(Vector2.ZERO, radius * 1.5, 0, TAU, 32, Color(color, 0.45 * alpha), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0)
	rig.draw(self, base, walk_phase, anim, clampf(cast_time / 0.25, 0.0, 1.0), Color(1, 1, 1, alpha), status_overlay())


## Top of the monster's head, for bars and effects.
func top_y() -> float:
	if rig and burrowed_time <= 0.0:
		return feet().y - rig.height * rig.unit_scale(radius)
	return -radius


func _draw_status() -> void:
	var alpha := 0.3 if stealth and revealed_time <= 0.0 else 1.0
	var mid := Vector2(0, (feet().y + top_y()) * 0.5) if rig else Vector2.ZERO
	var half := maxf((feet().y - top_y()) * 0.55, radius + 4.0) if rig else radius + 5.0
	if burrowed_time > 0.0:
		mid = Vector2.ZERO
		half = radius + 5.0
	if shield > 0.0:
		draw_set_transform(mid, 0.0, Vector2(maxf(radius * 1.3, half * 0.85) / half, 1.0))
		draw_circle(Vector2.ZERO, half, Color(0.45, 0.7, 1.0, 0.12 * alpha))
		draw_arc(Vector2.ZERO, half, 0.0, TAU, 32, Color(0.55, 0.8, 1.0, 0.8 * alpha), 2.5)
		draw_arc(Vector2.ZERO, half - 3.0, -2.4, -1.6, 8, Color(1, 1, 1, 0.6 * alpha), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0)
	if burn_time > 0.0:
		for i in 4:
			var fp := mid + Vector2(sin(anim * 9.0 + i * 2.1) * radius * 0.6, half * 0.3 - fmod(anim * 40.0 + i * 9.0, half * 1.2))
			draw_circle(fp, 3.0, Color(1.0, 0.55, 0.1, 0.9))
			draw_circle(fp, 1.5, Color(1.0, 0.9, 0.4, 0.9))
	if poison_time > 0.0:
		for i in 3:
			var bp := mid + Vector2(sin(anim * 3.0 + i * 2.0) * radius * 0.7, half * 0.2 - fmod(anim * 18.0 + i * 11.0, half))
			draw_circle(bp, 2.2, Color(0.55, 1.0, 0.25, 0.8))
	if regen > 0.0 and hp < max_hp and burn_time <= 0.0 and poison_time <= 0.0:
		for i in 2:
			var rp := mid + Vector2(cos(anim * 2.0 + i * PI) * radius, -fmod(anim * 14.0 + i * 13.0, half * 1.4) + half * 0.5)
			draw_circle(rp, 2.0, Color(0.4, 1.0, 0.7, 0.75))
	if hp < max_hp or (max_shield > 0.0 and shield < max_shield):
		var w2 := radius * 2.0 + 8.0
		var top := Vector2(-w2 * 0.5, top_y() - 8.0)
		draw_rect(Rect2(top - Vector2(1, 1), Vector2(w2 + 2, 6)), OUTLINE)
		var r := clampf(hp_ratio(), 0.0, 1.0)
		var c := Color(0.35, 0.9, 0.3) if r > 0.5 else Color(1.0, 0.75, 0.2) if r > 0.25 else Color(1.0, 0.3, 0.25)
		draw_rect(Rect2(top, Vector2(w2 * r, 4)), c)
		if max_shield > 0.0 and shield > 0.0:
			draw_rect(Rect2(top + Vector2(0, -4), Vector2(w2 * clampf(shield / max_shield, 0.0, 1.0), 3)), Color(0.45, 0.7, 1.0))


## Fallback look for enemies without monster art.
func _draw_blob() -> void:
	var body := color
	if flash_time > 0.0:
		body = Color.WHITE
	elif freeze_time > 0.0:
		body = body.lerp(Color(0.75, 0.95, 1.0), 0.75)
	elif poison_time > 0.0:
		body = body.lerp(Color(0.45, 0.95, 0.25), 0.35)
	elif slow_amount > 0.0:
		body = body.lerp(Color(0.45, 0.8, 1.0), 0.4)
	var alpha := 1.0
	if stealth and revealed_time <= 0.0:
		alpha = 0.3

	if burrowed_time > 0.0:
		draw_circle(Vector2.ZERO, radius * 1.1, Color(0.35, 0.25, 0.15, 0.85))
		for i in 5:
			var a := TAU * i / 5.0 + anim
			draw_circle(Vector2.from_angle(a) * radius * 0.8, 3.0, Color(0.5, 0.38, 0.22))
		return

	var lift := Vector2.ZERO
	if flying:
		draw_circle(Vector2(4, radius + 6), radius * 0.8, Color(0, 0, 0, 0.25 * alpha))
		lift = Vector2(0, -6 + sin(anim * 4.0) * 2.0)
	else:
		draw_circle(Vector2(2, 4), radius, Color(0, 0, 0, 0.2 * alpha))

	var outline := Color(OUTLINE, alpha)
	body.a = alpha
	draw_set_transform(lift, facing)
	if flying:
		var w := radius * 1.6
		var flap := 0.6 + 0.4 * absf(sin(anim * 12.0))
		for side in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(-2, 0), Vector2(-radius * 0.6, side * w * flap), Vector2(radius * 0.4, side * 2.0)]), outline)
			draw_colored_polygon(PackedVector2Array([Vector2(-2, side), Vector2(-radius * 0.5, side * (w * flap - 3.0)), Vector2(radius * 0.3, side * 3.0)]), Color(body.lightened(0.3), alpha))
	else:
		var step := sin(anim * 10.0) * radius * 0.25
		for side in [-1.0, 1.0]:
			draw_circle(Vector2(step * side, side * radius * 0.85), radius * 0.3, outline)
			draw_circle(Vector2(-step * side - radius * 0.4, side * radius * 0.8), radius * 0.28, outline)
	if is_boss:
		for i in 8:
			var a := TAU * i / 8.0
			var tip := Vector2.from_angle(a) * (radius + 9)
			draw_colored_polygon(PackedVector2Array([Vector2.from_angle(a - 0.25) * (radius - 2), tip, Vector2.from_angle(a + 0.25) * (radius - 2)]), outline)
	draw_circle(Vector2.ZERO, radius + 2.5, outline)
	draw_circle(Vector2.ZERO, radius, body)
	draw_circle(Vector2(-radius * 0.25, -radius * 0.25), radius * 0.45, Color(body.lightened(0.25), alpha))
	if armor > 0.0:
		draw_arc(Vector2.ZERO, radius - 3.0, 0.0, TAU, 24, Color(0.8, 0.83, 0.9, alpha), 3.0)
	if harden_time > 0.0:
		draw_arc(Vector2.ZERO, radius + 6.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.2), 4.0)
	var eye := radius * 0.22
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(radius * 0.45, side * radius * 0.35), eye, Color(1, 1, 1, alpha))
		draw_circle(Vector2(radius * 0.55, side * radius * 0.35), eye * 0.5, outline)
	draw_set_transform(Vector2.ZERO, 0.0)
