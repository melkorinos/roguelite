class_name DragLoc

# Uniform drag-payload shape: {"zone": "grid"|"inventory"|"shop", "slot": int}.
# Mirrors the from_loc / to_loc shape that ShopSystem.transfer and can_transfer
# already use, so ShopSystem.drag_to_loc needs no key translation — it just
# validates and passes through.
#
# Shop payloads additionally carry "element_id" and "price" for the
# InventorySlot buy-signal path (InventorySlot reads them directly).

static func grid(slot: int) -> Dictionary:
	return {"zone": "grid", "slot": slot}


static func inventory(slot: int) -> Dictionary:
	return {"zone": "inventory", "slot": slot}


static func shop(slot: int, element_id: String, price: int) -> Dictionary:
	return {"zone": "shop", "slot": slot, "element_id": element_id, "price": price}
