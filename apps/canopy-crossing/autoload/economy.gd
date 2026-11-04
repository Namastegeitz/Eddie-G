extends Node
## Two currencies: Berries (soft, earned in runs) and Amber (premium, bought
## or occasionally earned). Unlocks, consumables and cosmetics are priced in
## the content files; this script only applies them.

signal currency_changed
signal unlocked(kind: String, id: String)

const RUN_ROWS_PER_BERRY := 4


func berries() -> int:
	return int(Save.data.berries)


func amber() -> int:
	return int(Save.data.amber)


func add(currency: String, amount: int, reason := "") -> void:
	if amount == 0:
		return
	Save.data[currency] = maxi(0, int(Save.data.get(currency, 0)) + amount)
	Save.mark()
	Analytics.event("currency", {"currency": currency, "amount": amount, "reason": reason})
	currency_changed.emit()


func can_afford(price: Dictionary) -> bool:
	for c in price:
		if int(Save.data.get(c, 0)) < int(price[c]):
			return false
	return true


func spend(price: Dictionary, reason := "") -> bool:
	if price.is_empty() or not can_afford(price):
		return false
	for c in price:
		add(String(c), -int(price[c]), reason)
	return true


## Pick one currency out of a {"berries": a, "amber": b} price.
func price_in(price: Dictionary, currency: String) -> Dictionary:
	if price.has(currency):
		return {currency: int(price[currency])}
	return {}


# ------------------------------------------------------------------ animals

## How an animal can be unlocked: {"kind": "owned"|"free"|"berries"|"amber"|"pack", "price": {...}, "product": id, "discount": f}
func animal_offer(id: String) -> Dictionary:
	var a := Content.animal(id)
	if a.is_empty():
		return {}
	if Save.owns_animal(id):
		return {"kind": "owned"}
	var u: Dictionary = a.get("unlock", {})
	var discount := Store.animal_discount(id)
	match String(u.get("type", "")):
		"free":
			return {"kind": "free", "price": {}}
		"berries":
			return {"kind": "berries", "price": {"berries": _disc(int(u.price), discount)}, "discount": discount}
		"amber":
			return {"kind": "amber", "price": {"amber": _disc(int(u.price), discount)}, "discount": discount}
		"pack":
			var prod := Store.pack_product_for_animal(id)
			return {"kind": "pack", "price": {"amber": _disc(int(u.get("amber", 150)), discount)}, "product": prod, "discount": discount}
	return {}


func _disc(price: int, discount: float) -> int:
	return int(roundf(price * (1.0 - discount)))


func unlock_animal(id: String) -> bool:
	var offer := animal_offer(id)
	if offer.is_empty() or offer.kind == "owned":
		return false
	if offer.kind != "free" and not spend(offer.price, "unlock_" + id):
		return false
	give_animal(id, "currency")
	return true


func give_animal(id: String, source: String) -> void:
	if Save.owns_animal(id) or not Content.animals.has(id):
		return
	Save.data.owned_animals.append(id)
	Save.mark()
	Analytics.event("unlock", {"kind": "animal", "id": id, "source": source})
	Analytics.funnel("first_unlock", {"id": id})
	unlocked.emit("animal", id)


func give_map(id: String, source: String) -> void:
	if Save.owns_map(id) or not Content.maps.has(id):
		return
	Save.data.owned_maps.append(id)
	Save.mark()
	Analytics.event("unlock", {"kind": "map", "id": id, "source": source})
	unlocked.emit("map", id)


func give_cosmetic(id: String, source: String) -> void:
	if id in Save.data.owned_cosmetics:
		return
	Save.data.owned_cosmetics.append(id)
	Save.mark()
	Analytics.event("unlock", {"kind": "cosmetic", "id": id, "source": source})
	unlocked.emit("cosmetic", id)


func give_item(id: String, count: int, source: String) -> void:
	Save.data.inventory[id] = Save.item_count(id) + count
	Save.mark()
	Analytics.event("item", {"id": id, "count": count, "source": source})
	currency_changed.emit()


func use_item(id: String) -> bool:
	if Save.item_count(id) <= 0:
		return false
	Save.data.inventory[id] = Save.item_count(id) - 1
	Save.mark()
	Analytics.event("item_used", {"id": id})
	currency_changed.emit()
	return true


## Apply one reward dict ({"berries": n} / {"amber": n} / {"item": id, "count": n} / {"animal": id} / {"cosmetic": id}).
func give_reward(r: Dictionary, source: String) -> void:
	if r.has("berries"):
		add("berries", int(r.berries), source)
	if r.has("amber"):
		add("amber", int(r.amber), source)
	if r.has("item"):
		give_item(String(r.item), int(r.get("count", 1)), source)
	if r.has("animal"):
		give_animal(String(r.animal), source)
	if r.has("cosmetic"):
		give_cosmetic(String(r.cosmetic), source)


# ------------------------------------------------------------------ shop items

func buy_consumable(id: String, currency: String) -> bool:
	var c := Content.consumable(id)
	if c.is_empty():
		return false
	var price := price_in(Store.consumable_price(id), currency)
	if price.is_empty() or not spend(price, "buy_" + id):
		return false
	if id == "berry_doubler":
		var now := int(Time.get_unix_time_from_system())
		Save.data.berry_doubler_until = maxi(now, int(Save.data.berry_doubler_until)) + int(c.get("duration_h", 24)) * 3600
		Save.mark()
	else:
		give_item(id, 1, "shop")
	return true


func buy_cosmetic(id: String) -> bool:
	var c := Content.cosmetic(id)
	if c.is_empty() or id in Save.data.owned_cosmetics:
		return false
	if not spend(Store.cosmetic_price(id), "cosmetic_" + id):
		return false
	give_cosmetic(id, "shop")
	return true


func exchange(index: int) -> bool:
	var ex: Array = Content.catalog.get("exchange", [])
	if index < 0 or index >= ex.size():
		return false
	var e: Dictionary = ex[index]
	if not spend({"amber": int(e.amber)}, "exchange"):
		return false
	add("berries", int(e.berries), "exchange")
	return true


# ------------------------------------------------------------------ runs

func berry_multiplier() -> float:
	var m := 1.0
	if Store.is_weekend():
		m *= float(Content.live_ops.get("weekend", {}).get("berry_multiplier", 2.0))
	if int(Save.data.berry_doubler_until) > int(Time.get_unix_time_from_system()):
		m *= 2.0
	return m


## Berries for a finished run, before any "double it" ad.
func run_berries(collected: int, rows: int, cleared: bool) -> int:
	var base := collected + rows / RUN_ROWS_PER_BERRY + (15 if cleared else 0)
	return int(roundf(base * berry_multiplier()))
