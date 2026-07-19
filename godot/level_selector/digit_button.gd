class_name DigitButton
extends TextureButton

enum FrameType {
	Frame_0,
	Frame_1,
	Frame_2,
	Frame_3,
	Frame_4,
	Frame_5,
	Frame_6,
	Frame_7,
	Frame_8,
	Frame_9,
	Frame_Human,
	Frame_Colon,
	Frame_Left,
	Frame_Right,
	Frame_Back,
	Frame_Reset
}

@export var frame: FrameType = FrameType.Frame_0
@onready var _sprite: Sprite2D = $Sprite

func _ready() -> void:
	_sprite.frame = frame
