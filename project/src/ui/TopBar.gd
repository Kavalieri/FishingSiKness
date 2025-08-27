extends Container
signal open_requested(alias:String)

@onready var btn_money  : Button      = %BtnMoney
@onready var btn_gems   : Button      = %BtnGems
@onready var btn_zone   : Button      = %BtnZone
@onready var btn_level  : Button      = %BtnLevel
@onready var xp_bar     : ProgressBar = %XPBar
@onready var btn_xp     : Button      = %BtnXP
@onready var btn_options: Button      = %BtnOptions

func _ready() -> void:
    # Tooltips (desktop); móvil usa long-press si lo implementas fuera
    btn_money.hint_tooltip   = tr("Dinero. Toca para ver detalles.")
    btn_gems.hint_tooltip    = tr("Diamantes. Tienda.")
    btn_zone.hint_tooltip    = tr("Zona actual.")
    btn_level.hint_tooltip   = tr("Nivel de jugador.")
    btn_xp.hint_tooltip      = tr("Progreso hacia el siguiente nivel.")
    btn_options.hint_tooltip = tr("Opciones")

    # Botones → solicitud de apertura (WindowManager decide ventana real)
    btn_money.pressed.connect(func(): emit_signal("open_requested", "money"))
    btn_gems.pressed.connect(func(): emit_signal("open_requested", "diamonds"))
    btn_zone.pressed.connect(func(): emit_signal("open_requested", "zone"))
    btn_level.pressed.connect(func(): emit_signal("open_requested", "level"))
    btn_xp.pressed.connect(func(): emit_signal("open_requested", "xp"))
    btn_options.pressed.connect(func(): emit_signal("open_requested", "options"))

    # Connect to Save and Experience autoloads
    if Save:
        Save.coins_changed.connect(set_money)
        Save.gems_changed.connect(set_diamonds)
        Save.data_loaded.connect(func(_slot): sync_from_state(Save, Experience)) # Update on game load
        # Zone updates will be handled by ScreenManager calling set_zone directly
    if Experience:
        Experience.level_up.connect(_on_experience_level_up)
    # Initial sync
    if Save and Experience:
        sync_from_state(Save, Experience)

# ---- setters públicos (para wiring externo si no usas self‑wiring) ----
func set_money(v:int) -> void:
    btn_money.text = _fmt_money(v)

func set_diamonds(v:int) -> void:
    btn_gems.text = str(v)

func set_zone(name:String) -> void:
    btn_zone.text = tr("Zona: ") + name

func set_level(l:int) -> void:
    btn_level.text = tr("Lvl ") + str(l)

func set_xp(current:int, required:int) -> void:
    var p := (required > 0) ? float(current)/float(required) : 0.0
    xp_bar.value = clampf(p * 100.0, 0.0, 100.0)
    xp_bar.tooltip_text = "%d / %d (%.0f%%)" % [current, required, xp_bar.value]

func sync_from_state(save_data: Node, experience_data: Node) -> void:
    set_money(save_data.get_coins())
    set_diamonds(save_data.get_gems())
    set_zone(save_data._get_zone_display_name(save_data.game_data.current_zone))
    set_level(experience_data.current_level)
    var xp_progress = experience_data.get_xp_progress()
    set_xp(xp_progress.current_xp, xp_progress.required_xp)

func _on_experience_level_up(new_level: int) -> void:
    set_level(new_level)
    var xp_progress = Experience.get_xp_progress()
    set_xp(xp_progress.current_xp, xp_progress.required_xp)

# ---- utilidades ----
func _fmt_money(n:int) -> String:
    var f := float(n)
    if f >= 1_000_000_000.0: return "%.2fB" % (f/1_000_000_000.0)
    if f >= 1_000_000.0:     return "%.2fM" % (f/1_000_000.0)
    if f >= 1_000.0:         return "%.2fK" % (f/1_000.0)
    return str(n)
