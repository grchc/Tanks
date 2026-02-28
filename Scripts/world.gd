extends Node2D

const MAIN_MENU_SCENE = "res://Scenes/main_menu.tscn"

var _cb_lock_change
var _cb_lock_error
var _intentional_unlock := false
var _lock_retry_timer: SceneTreeTimer = null

func _ready() -> void:
	if OS.get_name() == "Web":
		_init_js_state()
		_cb_lock_change = JavaScriptBridge.create_callback(_on_js_lock_change)
		_cb_lock_error  = JavaScriptBridge.create_callback(_on_js_lock_error)
		JavaScriptBridge.get_interface("document").addEventListener("pointerlockchange", _cb_lock_change)
		JavaScriptBridge.get_interface("document").addEventListener("pointerlockerror",  _cb_lock_error)
		_request_pointer_lock()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _exit_tree() -> void:
	if OS.get_name() == "Web":
		JavaScriptBridge.get_interface("document").removeEventListener("pointerlockchange", _cb_lock_change)
		JavaScriptBridge.get_interface("document").removeEventListener("pointerlockerror",  _cb_lock_error)
		if _lock_retry_timer != null:
			_lock_retry_timer = null

func _input(event: InputEvent) -> void:
	if OS.get_name() != "Web":
		if event.is_action_pressed("ui_cancel"):
			_return_to_menu()

# ── JS helpers ────────────────────────────────────────────────

func _init_js_state() -> void:
	# Инициализируем глобальный объект состояния один раз
	JavaScriptBridge.eval("""
        if (!window.__plState) {
            window.__plState = {
                status: 'unlocked',
                lastNativeUnlockAt: 0
            };
        }
	""")

func _request_pointer_lock() -> void:
	# Проверяем cooldown: если нативный unlock был < 1200ms назад — ждём
	var is_in_cooldown: bool = JavaScriptBridge.eval("""
        (function() {
            var elapsed = performance.now() - window.__plState.lastNativeUnlockAt;
            return (window.__plState.lastNativeUnlockAt > 0 && elapsed < 1200);
        })()
	""")

	if is_in_cooldown:
		# Подождём до окончания cooldown и попробуем снова
		var remaining_ms: float = JavaScriptBridge.eval("""
            Math.max(0, 1200 - (performance.now() - window.__plState.lastNativeUnlockAt))
		""")
		var wait_sec = remaining_ms / 1000.0 + 0.05  # +50ms запас
		_lock_retry_timer = get_tree().create_timer(wait_sec)
		_lock_retry_timer.timeout.connect(_do_request_pointer_lock)
	else:
		_do_request_pointer_lock()

func _do_request_pointer_lock() -> void:
	_lock_retry_timer = null
	JavaScriptBridge.eval("""
        window.__plState.status = 'pending';
        document.body.requestPointerLock({ unadjustedMovement: true })
            .catch(function(e) {
                if (e.name === 'NotSupportedError') {
                    // unadjustedMovement не поддерживается — fallback
                    return document.body.requestPointerLock();
                }
                // SecurityError или другое — пробросим для pointerlockerror
                throw e;
            })
            .catch(function(e) {
                window.__plState.status = 'unlocked';
                console.warn('[PLock] requestPointerLock failed:', e.name, e.message);
            });
	""")

func _on_js_lock_change(_args) -> void:
	var is_locked: bool = JavaScriptBridge.eval("!!document.pointerLockElement")

	if is_locked:
		JavaScriptBridge.eval("window.__plState.status = 'locked';")
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_intentional_unlock = false
	else:
		JavaScriptBridge.eval("window.__plState.status = 'unlocked';")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		if not _intentional_unlock:
			# Нативный выход (ESC пользователя) — сохраняем timestamp
			JavaScriptBridge.eval("window.__plState.lastNativeUnlockAt = performance.now();")
			_return_to_menu()

func _on_js_lock_error(_args) -> void:
	# pointerlockerror — lock не получен, но мы ещё в World
	# Если это не intentional — попробуем повторно через паузу
	JavaScriptBridge.eval("window.__plState.status = 'unlocked';")
	if not _intentional_unlock and is_inside_tree():
		push_warning("[World] pointerlockerror — retrying after cooldown")
		_lock_retry_timer = get_tree().create_timer(1.2)
		_lock_retry_timer.timeout.connect(_do_request_pointer_lock)

# ── Общее ─────────────────────────────────────────────────────

func _return_to_menu() -> void:
	if OS.get_name() == "Web":
		_intentional_unlock = true
		# Программный exitPointerLock — cooldown НЕ устанавливаем
		# (браузер разрешит немедленный re-lock после программного выхода)
		JavaScriptBridge.eval("""
            window.__plState.lastNativeUnlockAt = 0;
            document.exitPointerLock();
		""")
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
