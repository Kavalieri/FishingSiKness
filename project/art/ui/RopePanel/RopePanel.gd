extends Control

@export var border_thickness := 80

@onready var center := $CenterFill
@onready var top    := $SideTop
@onready var bottom := $SideBottom
@onready var left   := $SideLeft
@onready var right  := $SideRight
@onready var nw     := $CornerNW
@onready var ne     := $CornerNE
@onready var sw     := $CornerSW
@onready var se     := $CornerSE

func _ready():
    _layout()

func _notification(what):
    if what == NOTIFICATION_RESIZED:
        _layout()

func _layout():
    var W = size.x
    var H = size.y
    var t = border_thickness

    # Esquinas fijas t x t
    nw.position = Vector2(0, 0);        nw.size = Vector2(t, t)
    ne.position = Vector2(W - t, 0);    ne.size = Vector2(t, t)
    sw.position = Vector2(0, H - t);    sw.size = Vector2(t, t)
    se.position = Vector2(W - t, H - t);se.size = Vector2(t, t)

    # Laterales tileados
    top.position = Vector2(t, 0);           top.size = Vector2(W - 2.0 * t, t)
    bottom.position = Vector2(t, H - t);    bottom.size = Vector2(W - 2.0 * t, t)
    left.position = Vector2(0, t);          left.size = Vector2(t, H - 2.0 * t)
    right.position = Vector2(W - t, t);     right.size = Vector2(t, H - 2.0 * t)

    # Centro
    center.position = Vector2(t, t)
    center.size     = Vector2(W - 2.0 * t, H - 2.0 * t)