class_name PresetPage extends Control

@export var presets_container: Container
@export var preset_info_card_res: Resource
@export_category("Pages")
@export var make_edit_preset_page_res: Resource

var presets: Array[Preset]
var cards: Array[PresetInfoCard]

func _ready():
	presets = PresetsManager.get_presets()
	for preset in presets:
		var card: PresetInfoCard = preset_info_card_res.instantiate()
		card.preset = preset
		presets_container.add_child(card)
		presets_container.move_child(card, 0)
		cards.append(card)

func load_make_edit_preset_page():
	Global.AppMan.load_gui_scene(make_edit_preset_page_res)
