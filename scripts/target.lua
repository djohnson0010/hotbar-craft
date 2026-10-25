local SOURCE = require("scripts.sources")

local Target = {}

local function first_item_to_place(prototype)
  local items = prototype and prototype.items_to_place_this
  return items and items[1] and items[1].name
end

local function ghost_in_hand(player)
  local ghost = player.cursor_ghost
  if not ghost then return nil end
  return type(ghost.name) == "string" and ghost.name or ghost.name.name
end

local function selected_prototype_item(player, selected)
  local base_type, name = selected.base_type, selected.name
  if base_type == "item" then return name end
  if base_type == "entity" and player.selected then
    local item = Target.item_to_build(player.selected)
    if item then return item end
  end
  if base_type == "entity" then return first_item_to_place(prototypes.entity[name]) end
  if base_type == "tile" then return first_item_to_place(prototypes.tile[name]) end
end

function Target.is_ghost(entity)
  return entity.type == "entity-ghost" or entity.type == "tile-ghost"
end

function Target.item_to_build(entity)
  if entity.type == "entity-ghost" then return first_item_to_place(prototypes.entity[entity.ghost_name]) end
  if entity.type == "tile-ghost" then return first_item_to_place(prototypes.tile[entity.ghost_name]) end
  return first_item_to_place(prototypes.entity[entity.name])
end

function Target.item_in_hand(player)
  local stack = player.cursor_stack
  return stack and stack.valid_for_read and stack.name or nil
end

function Target.item_name(player, selected)
  return (selected and selected_prototype_item(player, selected))
    or ghost_in_hand(player)
    or Target.item_in_hand(player)
end

function Target.source(player, selected)
  if not selected then return SOURCE.CURSOR end
  if selected.base_type == "entity" and player.selected then return SOURCE.ENTITY end
  return SOURCE.GUI
end

return Target
