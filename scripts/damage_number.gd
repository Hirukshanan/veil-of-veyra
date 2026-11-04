extends RefCounted

# Sibling ownership keeps a finishing-hit number alive after its victim is freed.
static func show_hit(victim: Node3D, amount: int, height: float) -> void:
 if amount <= 0 or not victim.is_inside_tree():
  return
 var active := victim.get_tree().get_nodes_in_group("damage_numbers")
 if active.size() >= 24:
  active[0].free()
 var popup := Label3D.new()
 popup.text = str(amount)
 popup.font_size = 48
 popup.outline_size = 8
 popup.pixel_size = 0.004
 popup.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 popup.modulate = Color(1.0, 0.85, 0.35)
 victim.get_parent().add_child(popup)
 popup.add_to_group("damage_numbers")
 popup.global_position = victim.global_position + Vector3(0, height, 0)
 var tween := popup.create_tween().set_parallel(true)
 tween.tween_property(popup, "position:y", popup.position.y + 0.8, 0.65)
 tween.tween_property(popup, "modulate:a", 0.0, 0.3).set_delay(0.35)
 tween.chain().tween_callback(popup.queue_free)
