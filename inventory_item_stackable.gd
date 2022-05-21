extends InventoryItem
class_name InventoryItemStackable

signal stack_size_changed

const KEY_STACK_SIZE: String = "default_stack_size";

export(int) var stack_size = 1 setget _set_stack_size;


func _set_stack_size(new_stack_size: int) -> void:
    stack_size = new_stack_size;
    emit_signal("stack_size_changed");
    if get_inventory():
        get_inventory().emit_signal("contents_changed");


func apply(item_definition: Dictionary) -> void:
    .apply(item_definition);
    if item_definition.has(KEY_STACK_SIZE):
        stack_size = item_definition[KEY_STACK_SIZE];
    
    
func split(new_stack_size: int) -> bool:
    assert(new_stack_size >= 1, "New stack size must be greater or equal to 1!");
    assert(new_stack_size < stack_size, "New stack size must be smaller than the original stack size!");
    assert(get_inventory() != null, "The stack doesn't belong to an inventory!")

    var new_item = duplicate();
    new_item._set_stack_size(new_stack_size);
    _set_stack_size(stack_size - new_stack_size);
    return get_inventory().add_item(new_item);


func join(new_stack: InventoryItem) -> bool:
    assert(get_inventory() == new_stack.get_inventory(), "The two stacks must be in the same inventory!");
    assert(get_inventory() != null, "The stack doesn't belong to an inventory!");
    assert(new_stack.item_id == item_id, "The two stacks must be of the same type!");

    if get_inventory().remove_item(new_stack):
        _set_stack_size(stack_size + new_stack.stack_size);
        new_stack.queue_free();
        return true;

    return false;

