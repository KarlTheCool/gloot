class_name CtrlInventoryGridEx
extends CtrlInventoryGrid
tool

const Verify = preload("res://addons/gloot/verify.gd")

export(StyleBox) var field_style: StyleBox setget _set_field_style
export(StyleBox) var field_highlighted_style: StyleBox setget _set_field_highlighted_style
export(StyleBox) var field_selected_style: StyleBox setget _set_field_selected_style
export(StyleBox) var selection_style: StyleBox setget _set_selection_style
var _field_background_grid: Control
var _field_backgrounds: Array
var _selection_panel: Panel
var _pending_highlights: Array = []


func _set_field_style(new_field_style: StyleBox) -> void:
    field_style = new_field_style
    _refresh()


func _set_field_highlighted_style(new_field_highlighted_style: StyleBox) -> void:
    field_highlighted_style = new_field_highlighted_style
    _refresh()


func _set_field_selected_style(new_field_selected_style: StyleBox) -> void:
    field_selected_style = new_field_selected_style
    _refresh()


func _set_selection_style(new_selection_style: StyleBox) -> void:
    selection_style = new_selection_style
    _refresh()


func _queue_highlight(rect_: Rect2, style_: StyleBox) -> void:
    _pending_highlights.push_back({
        rect = rect_,
        style = style_
    })


func _dequeue_highlight() -> Dictionary:
    return _pending_highlights.pop_front()


func _refresh() -> void:
    ._refresh()


func _refresh_selection() -> void:
    ._refresh_selection()
    if !_selection_panel:
        return
    _selection_panel.visible = (_selected_item != null) && (selection_style != null)
    if _selected_item:
        move_child(_selection_panel, get_child_count() - 1)

        var selection_pos = _get_field_position(inventory.get_item_position(_selected_item))
        var selection_size = _get_streched_item_sprite_size(_selected_item)
        _selection_panel.rect_position = selection_pos
        _selection_panel.rect_size = selection_size


func _refresh_field_background_grid() -> void:
    if _field_background_grid:
        remove_child(_field_background_grid)
        _field_background_grid.queue_free()
        _field_background_grid = null
        _field_backgrounds = []

    _create_field_background_grid()


func _create_field_background_grid() -> void:
    if !inventory:
        return

    _field_background_grid = Control.new()
    add_child(_field_background_grid)
    move_child(_field_background_grid, 0)

    for i in range(inventory.size.x):
        _field_backgrounds.append([])
        for j in range(inventory.size.y):
            var field_panel: Panel = Panel.new()
            _set_panel_style(field_panel, field_style)
            field_panel.visible = (field_style != null)
            field_panel.rect_size = field_dimensions
            field_panel.rect_position = _get_field_position(Vector2(i, j))
            _field_background_grid.add_child(field_panel)
            _field_backgrounds[i].append(field_panel)


func _create_selection_panel() -> void:
    _selection_panel = Panel.new()
    add_child(_selection_panel);
    move_child(_selection_panel, get_child_count() - 1)
    _set_panel_style(_selection_panel, selection_style)
    _selection_panel.visible = (_selected_item != null) && (selection_style != null)
    _selection_panel.connect("mouse_entered", self, "_on_selection_mouse_entered")
    _selection_panel.connect("mouse_exited", self, "_on_selection_mouse_exited")


func _on_selection_mouse_entered() -> void:
    emit_signal("item_mouse_entered", _selected_item)


func _on_selection_mouse_exited() -> void:
    emit_signal("item_mouse_exited", _selected_item)


func _set_panel_style(panel: Panel, style: StyleBox) -> void:
    panel.remove_stylebox_override("panel")
    panel.add_stylebox_override("panel", style)


func _ready() -> void:
    _create_selection_panel()
    _create_field_background_grid()
    connect("item_selected", self, "_on_item_selected")
    connect("item_deselected", self, "_on_item_deselected")


func _on_item_selected(item: InventoryItem) -> void:
    if !inventory:
        return
    if field_selected_style:
        _queue_highlight(inventory.get_item_rect(item), field_selected_style)


func _on_item_deselected(item: InventoryItem) -> void:
    if !inventory:
        return
    if field_style:
        _queue_highlight(inventory.get_item_rect(item), field_style)


func _on_inventory_resized() -> void:
    ._on_inventory_resized()
    _refresh_field_background_grid()


func _input(event) -> void:
    if !(event is InputEventMouseMotion):
        return
    if !inventory:
        return
    
    var hovered_field_coords := Vector2(-1, -1)
    if _is_hovering(get_global_mouse_position()):
        hovered_field_coords = get_field_coords(get_global_mouse_position())

    _reset_highlights()
    if !field_highlighted_style:
        return
    if _highlight_grabbed_item(field_highlighted_style):
        return
    _highlight_hovered_fields(hovered_field_coords, field_highlighted_style)
        

func _reset_highlights() -> void:
    while true:
        var highlight := _dequeue_highlight()
        if !highlight:
            break
        _highlight_rect(highlight.rect, highlight.style, false)


func _highlight_hovered_fields(field_coords: Vector2, style: StyleBox) -> void:
    if !style || !Verify.vector_positive(field_coords):
        return

    if _highlight_item(inventory.get_item_at(field_coords), style):
        return

    _highlight_field(field_coords, style)


func _highlight_grabbed_item(style: StyleBox) -> bool:
    var grabbed_item: InventoryItem = _get_global_grabbed_item()
    if !grabbed_item:
        return false

    var global_grabbed_item_pos: Vector2 = _get_global_grabbed_item_global_pos()
    if !_is_hovering(global_grabbed_item_pos):
        return false

    var grabbed_item_coords: Vector2 = get_field_coords(global_grabbed_item_pos)
    var item_size: Vector2 = inventory.get_item_size(grabbed_item)
    var rect: Rect2 = Rect2(grabbed_item_coords, item_size)
    _highlight_rect(rect, style, true)
    return true


func _highlight_item(item: InventoryItem, style: StyleBox) -> bool:
    if !item || !style:
        return false
    if item == _selected_item:
        # Don't highlight the selected item (done in _on_item_selected())
        return false

    _highlight_rect(inventory.get_item_rect(item), style, true)
    return true


func _highlight_field(field_coords: Vector2, style: StyleBox) -> void:
    if _selected_item && inventory.get_item_rect(_selected_item).has_point(field_coords):
        # Don't highlight selected fields (done in _on_item_selected())
        return

    _highlight_rect(Rect2(field_coords, Vector2.ONE), style, true)


func _highlight_rect(rect: Rect2, style: StyleBox, queue_for_reset: bool) -> void:
    var h_range = min(rect.size.x + rect.position.x, inventory.size.x)
    for i in range(rect.position.x, h_range):
        var v_range = min(rect.size.y + rect.position.y, inventory.size.y)
        for j in range(rect.position.y, v_range):
            _set_panel_style(_field_backgrounds[i][j], style)
    if queue_for_reset:
        _queue_highlight(rect, field_style)


func _get_global_grabbed_item() -> InventoryItem:
    var grabbed_item: InventoryItem = get_grabbed_item()
    if !grabbed_item && _gloot:
        grabbed_item = _gloot._grabbed_inventory_item
    return grabbed_item


func _get_global_grabbed_item_global_pos() -> Vector2:
    if _gloot && _gloot._grabbed_inventory_item:
        return get_global_mouse_position() - _gloot._grab_offset + (field_dimensions / 2)
    return Vector2(-1, -1)
    
