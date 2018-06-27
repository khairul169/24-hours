extends Control

export (PackedScene) var item_list_scene;
export (Texture) var dragdrop_placeholder;

const DRAG_PREVIEW_SIZE = 48.0;

# Nodes
onready var player = get_node("../../");
onready var inventory = get_node("../../inventory");
onready var item_picker = get_node("../../item_picker");

# UI node
onready var near_item_container = $near/base/scroll_container/container;
onready var bag_item_container = $bag/base/scroll_container/container;
onready var bag_capacity_label = $bag/capacity;
onready var label_health = $state/label_health;
onready var label_hunger = $state/label_hunger;
onready var label_thirst = $state/label_thirst;

# Drag n drop icon preview
var drag_preview;

# Variables
var near_items = [];
var bag_items = [];
var next_update = 0.0;
var itemdrop_controls = [];
var item_dragged = -1;

func _ready():
	reset();
	register_itemdrop_control($near/base, self, "on_item_dropped_to_near");
	call_deferred("_later_setup");

func _later_setup():
	# Create drag and drop preview control
	drag_preview = TextureRect.new();
	get_parent().add_child(drag_preview);
	
	drag_preview.name = "drag_preview"
	drag_preview.texture = dragdrop_placeholder;
	drag_preview.expand = true;
	drag_preview.rect_size = Vector2(1.0, 1.0) * DRAG_PREVIEW_SIZE;
	drag_preview.hide();

func _input(event):
	if (event is InputEventMouseButton):
		if (item_dragged >= 0 && !event.pressed && event.button_index == BUTTON_LEFT):
			item_drag_drop(event.global_position);
			item_dragged = -1;
			drag_preview.hide();
	
	if (event is InputEventMouseMotion):
		if (item_dragged >= 0):
			if (!drag_preview.visible):
				var icon = item_database.get_item_icon(inventory.items[item_dragged].id);
				if (icon):
					drag_preview.texture = icon;
				else:
					drag_preview.texture = dragdrop_placeholder;
				drag_preview.show();
			drag_preview.rect_global_position = event.global_position - (Vector2(1.0, 1.0) * DRAG_PREVIEW_SIZE / 2);

func reset():
	# Reset item
	near_items.clear();
	bag_items.clear();
	refresh_items();

func _process(delta):
	if (!visible):
		return;
	if (player):
		label_health.text = str(int(player.health)).pad_zeros(1) + "%";
		label_hunger.text = str(int(player.hunger * 100.0)).pad_zeros(1) + "%";
		label_thirst.text = str(int(player.thirst * 100.0)).pad_zeros(1) + "%";

func update_interface(container, item_list):
	for i in container.get_children():
		i.queue_free();
	
	if (!item_list_scene):
		return;
	
	for i in range(item_list.size()):
		# Instance item
		var instance = item_list_scene.instance();
		container.add_child(instance);
		
		# Update item data
		instance.update_item(item_list[i]);
		
		instance.connect("pick_item", self, "on_item_pick");
		instance.connect("item_used", self, "on_item_used");
		instance.connect("item_drop", self, "on_item_drop");
		instance.connect("item_pressed", self, "item_pressed");
	
	# Clear items
	item_list.clear();

func refresh_items():
	if (!item_picker || !inventory):
		return;
	
	# Nearest item
	var _near = item_picker.check_near_item();
	near_items.clear();
	
	for id in item_picker.nearest_item:
		var amount = item_picker.nearest_item[id].size();
		var item_size = 1;
		
		if (item_database.is_item_stackable(id) && amount > 1):
			item_size = amount;
			amount = 1;
		
		for i in range(amount):
			near_items.append({
			'id': id,
			'item_id': id,
			'size': item_size,
			'pickable': true,
			'usable': false
		});
	update_interface(near_item_container, near_items);
	
	# Bag item
	bag_items.clear();
	for i in range(inventory.items.size()):
		var item = inventory.items[i];
		var item_name = item_database.get_item_title(item.id);
		
		bag_items.append({
			'id': i,
			'item_id': item.id,
			'size': item.amount,
			'pickable': false,
			'usable': item_database.is_item_usable(item.id)
		});
	update_interface(bag_item_container, bag_items);
	
	# Bag capacity
	bag_capacity_label.text = str(inventory.cur_capacity).pad_decimals(1) + "/" + str(inventory.capacity).pad_decimals(1) + " kg";
	
	# Label color
	if (inventory.is_over_capacity()):
		bag_capacity_label.add_color_override("font_color", Color("#ff3a3a"));
	else:
		bag_capacity_label.add_color_override("font_color", Color(1,1,1));

func on_item_pick(id):
	if (item_picker && item_picker.has_method("pick_near_item")):
		if (Input.is_key_pressed(KEY_CONTROL) && item_picker.has_method("get_near_item_amount")):
			item_picker.pick_near_item(id, item_picker.get_near_item_amount(id));
		else:
			item_picker.pick_near_item(id, 1);
		refresh_items();

func on_item_used(id):
	if (inventory && inventory.has_method("use_item")):
		inventory.use_item(id);

func on_item_drop(id, all):
	if (inventory && inventory.has_method("drop_item")):
		if (all && inventory.has_method("get_item_amount")):
			inventory.drop_item(id, inventory.get_item_amount(id));
		else:
			inventory.drop_item(id, 1);

func register_itemdrop_control(node, target, method):
	itemdrop_controls.append({
		'node': node,
		'target': target,
		'method': method
	});

func item_drag_drop(pos):
	if (item_dragged < 0 || item_dragged >= inventory.items.size()):
		return;
	
	for i in itemdrop_controls:
		if (!i.node.visible || !i.node.get_global_rect().has_point(pos)):
			continue;
		if (i.target && i.target.has_method(i.method)):
			i.target.call(i.method, item_dragged);

func item_pressed(id):
	item_dragged = id;

func on_item_dropped_to_near(id):
	on_item_drop(id, true);
