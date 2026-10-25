local IngredientTree = require("scripts.ingredient_tree")
local SOURCE = require("scripts.sources")

local Tooltip = {}

local FRAME_NAME = "hotbar-craft-missing"
local SENSOR_NAME = "hotbar-craft-sensor"
local TIMEOUT_SETTING = "hotbar-craft-popup-seconds"

local SENSOR_SIZE = 40
local ICON_SIZE = 32
local ROW_HEIGHT = 36
local WIDTH = 300
local CHROME_HEIGHT = 80
local CURSOR_GAP = 20
local HOTBAR_CLEARANCE = 190
local TICKS_PER_SECOND = 60

local STATUS_COLORS = {
  [IngredientTree.STATUS.CRAFTABLE] = { 1, 0.8, 0.25 },
  [IngredientTree.STATUS.MISSING] = { 1, 0.35, 0.35 },
}

local function state_of(player)
  storage.tooltips = storage.tooltips or {}
  storage.tooltips[player.index] = storage.tooltips[player.index] or {}
  return storage.tooltips[player.index]
end

local function tracks_entity(source)
  return source == SOURCE.ENTITY or source == SOURCE.HOVER
end

local function destroy_child(parent, name)
  local child = parent[name]
  if child then child.destroy() end
end

local function item_display_name(item_name)
  local item = prototypes.item[item_name]
  return item and item.localised_name or item_name
end

local function count_text(node)
  if node.status == IngredientTree.STATUS.HAVE then return tostring(node.need) end
  return node.have .. "/" .. node.need
end

local function add_indent(row, depth)
  if depth == 0 then return end
  local indent = row.add({ type = "empty-widget" })
  indent.style.width = depth * ICON_SIZE
end

local function add_icon(row, item_name)
  local icon = row.add({ type = "sprite", sprite = "item/" .. item_name, resize_to_sprite = false })
  icon.style.size = ICON_SIZE
  icon.style.stretch_image_to_widget_size = true
end

local function add_count_label(row, node)
  local label = row.add({
    type = "label",
    caption = { "", "[font=default-bold]" .. count_text(node) .. "[/font] × ", item_display_name(node.name) },
  })
  local color = STATUS_COLORS[node.status]
  if color then label.style.font_color = color end
end

local function add_row(list, node, depth)
  local row = list.add({ type = "flow", direction = "horizontal" })
  row.style.vertical_align = "center"
  row.style.horizontal_spacing = 8
  row.style.height = ROW_HEIGHT
  add_indent(row, depth)
  add_icon(row, node.name)
  add_count_label(row, node)
end

local function add_rows(list, nodes, depth)
  for _, node in pairs(nodes) do
    add_row(list, node, depth)
    if IngredientTree.shows_children(node) then add_rows(list, node.children, depth + 1) end
  end
end

local function fill_rows(list, tree)
  list.clear()
  add_rows(list, tree, 0)
end

local function add_frame(player)
  local frame = player.gui.screen.add({
    type = "frame", name = FRAME_NAME, direction = "vertical", ignored_by_interaction = true,
  })
  frame.style.padding = 8
  return frame
end

local function add_title(frame, recipe)
  local title = frame.add({ type = "label", caption = { "hotbar-craft.window-title", recipe.localised_name } })
  title.style.font = "heading-2"
  title.style.bottom_padding = 4
end

local function add_ingredient_list(frame)
  local body = frame.add({
    type = "frame", name = "body", style = "inside_shallow_frame_with_padding", direction = "vertical",
  })
  local heading = body.add({ type = "label", caption = { "hotbar-craft.ingredients" } })
  heading.style.font = "default-bold"
  local list = body.add({ type = "flow", name = "list", direction = "vertical" })
  list.style.vertical_spacing = 0
  return list
end

local function clamp(value, low, high)
  return math.floor(math.max(low, math.min(value, high)))
end

local function scaled_size(player, row_count)
  local scale = player.display_scale
  return { width = WIDTH * scale, height = (row_count * ROW_HEIGHT + CHROME_HEIGHT) * scale }
end

local function beside_cursor(player, size, cursor)
  local screen = player.display_resolution
  local gap = CURSOR_GAP * player.display_scale
  local x = cursor.x + gap
  if x + size.width > screen.width then x = cursor.x - gap - size.width end
  local y = cursor.y - size.height - gap
  if y < 0 then y = cursor.y + gap end
  return {
    x = clamp(x, 0, screen.width - size.width),
    y = clamp(y, 0, screen.height - size.height),
  }
end

local function above_hotbar(player, size)
  local screen = player.display_resolution
  return {
    x = math.floor((screen.width - size.width) / 2),
    y = math.floor(screen.height - size.height - HOTBAR_CLEARANCE * player.display_scale),
  }
end

local function place(player, frame, row_count, cursor)
  local size = scaled_size(player, row_count)
  frame.location = cursor and beside_cursor(player, size, cursor) or above_hotbar(player, size)
end

local function add_sensor(player, cursor)
  local half = SENSOR_SIZE * player.display_scale / 2
  local sensor = player.gui.screen.add({ type = "empty-widget", name = SENSOR_NAME, raise_hover_events = true })
  sensor.style.size = SENSOR_SIZE
  sensor.location = { x = math.floor(cursor.x - half), y = math.floor(cursor.y - half) }
end

local function start_timeout(player)
  local seconds = player.mod_settings[TIMEOUT_SETTING].value
  state_of(player).close_tick = game.tick + seconds * TICKS_PER_SECOND
end

local function remember(player, recipe, source)
  local state = state_of(player)
  state.recipe = recipe.name
  state.source = source
  state.entity = tracks_entity(source) and player.selected or nil
end

local function is_still_on_entity(player, state)
  return state.entity and state.entity.valid and player.selected == state.entity
end

local function current_missing_tree(player, recipe)
  if player.get_craftable_count(recipe) > 0 then return nil end
  local tree = IngredientTree.build(player, recipe)
  if IngredientTree.has_missing(tree) then return tree end
end

function Tooltip.show(player, recipe, tree, source, cursor)
  Tooltip.close(player)
  local frame = add_frame(player)
  add_title(frame, recipe)
  fill_rows(add_ingredient_list(frame), tree)
  place(player, frame, IngredientTree.visible_row_count(tree), cursor)
  remember(player, recipe, source)

  if cursor and not tracks_entity(source) then
    add_sensor(player, cursor)
    start_timeout(player)
  end
end

function Tooltip.close(player)
  destroy_child(player.gui.screen, FRAME_NAME)
  destroy_child(player.gui.screen, SENSOR_NAME)
  storage.tooltips = storage.tooltips or {}
  storage.tooltips[player.index] = nil
end

function Tooltip.is_open(player)
  return state_of(player).recipe ~= nil
end

function Tooltip.shown(player)
  local state = state_of(player)
  return state.recipe, state.source
end

function Tooltip.refresh(player)
  local state = state_of(player)
  local frame = player.gui.screen[FRAME_NAME]
  if not (frame and state.recipe and player.character) then return end

  local recipe = player.force.recipes[state.recipe]
  local tree = recipe and current_missing_tree(player, recipe)
  if not tree then
    Tooltip.close(player)
    return
  end
  fill_rows(frame.body.list, tree)
end

function Tooltip.is_sensor(element)
  return element ~= nil and element.valid and element.name == SENSOR_NAME
end

function Tooltip.keep_open(player)
  state_of(player).close_tick = nil
end

function Tooltip.close_if_moved_off(player)
  local state = state_of(player)
  if tracks_entity(state.source) and not is_still_on_entity(player, state) then
    Tooltip.close(player)
  elseif state.source == SOURCE.GUI and player.selected then
    Tooltip.close(player)
  end
end

function Tooltip.close_if_source(player, source)
  if state_of(player).source == source then Tooltip.close(player) end
end

function Tooltip.close_expired(tick)
  for player_index, state in pairs(storage.tooltips or {}) do
    if state.close_tick and tick >= state.close_tick then
      local player = game.get_player(player_index)
      if player then Tooltip.close(player) end
    end
  end
end

return Tooltip
