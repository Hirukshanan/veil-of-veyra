extends HBoxContainer

const SHARD := preload("res://assets/ui/currency/tide_shard.png")
const GEM := preload("res://assets/ui/currency/veil_gem.png")
var shard_label: Label
var gem_label: Label

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	add_theme_constant_override("separation", 10)
	shard_label = _balance(SHARD, "Tide Shards")
	gem_label = _balance(GEM, "Veil Gems")

func _balance(icon: Texture2D, currency: String) -> Label:
	var image := TextureRect.new()
	image.texture = icon
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(30, 30)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	var amount := Label.new()
	amount.name = currency.replace(" ", "")
	amount.tooltip_text = currency
	amount.accessibility_name = currency
	amount.add_theme_font_size_override("font_size", 22)
	amount.add_theme_color_override("font_color", Color("ead8b2"))
	add_child(amount)
	return amount

func update_balances(shards: int, gems: int) -> void:
	shard_label.text = str(shards)
	gem_label.text = str(gems)

static func style_price(button: Button) -> void:
	button.icon = SHARD
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", 25)
