extends Control

@export var presets_container: Container
@export var preset_info_card_res: Resource
@export_category("Pages")
@export var save_preset_page: Resource

var presets: Array[Preset]
var cards: Array[PresetInfoCard]

func _ready():
	presets = PresetsManager.get_presets()
	for _preset in presets:
		var card: PresetInfoCard = preset_info_card_res.instantiate()
		card.initialize({"preset": _preset})
		card.enter()
		presets_container.add_child(card)
		presets_container.move_child(card, 0)
		cards.append(card)

func _process(_delta):
	for card in cards:
		card.update()

func load_make_edit_preset_page():
	Global.AppMan.load_gui_scene(Global.SceneCont.preset_page_save_preset)
