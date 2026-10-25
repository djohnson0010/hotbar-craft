local IngredientTree = require("scripts.ingredient_tree")
local Recipes = require("scripts.recipes")
local SOURCE = require("scripts.sources")
local Target = require("scripts.target")
local Tooltip = require("scripts.tooltip")

local CRAFT_INPUT = "hotbar-craft"
local CRAFT_COUNT_SETTING = "hotbar-craft-count"
local HOVER_SETTING = "hotbar-craft-hover"
local CANNOT_BUILD_SOUND = "utility/cannot_build"

local function player_of(event)
  return game.get_player(event.player_index)
end

local function setting(player, name)
  return player.mod_settings[name].value
end

local function play_cannot_build(player)
  player.play_sound({ path = CANNOT_BUILD_SOUND })
end

local function show_failure(player, message)
  player.create_local_flying_text({ text = message, create_at_cursor = true })
  play_cannot_build(player)
end

local function missing_tree(player, recipe)
  local tree = IngredientTree.build(player, recipe)
  if IngredientTree.has_missing(tree) then return tree end
end

local function explain_cannot_craft(player, recipe, source, cursor)
  local tree = missing_tree(player, recipe)
  if not tree then
    show_failure(player, { "hotbar-craft.cannot-handcraft", "[recipe=" .. recipe.name .. "]" })
    return
  end
  play_cannot_build(player)
  Tooltip.show(player, recipe, tree, source, cursor)
end

local function begin_crafting(player, recipe, craftable)
  Tooltip.close(player)
  local count = math.min(setting(player, CRAFT_COUNT_SETTING), craftable)
  player.begin_crafting({ count = count, recipe = recipe, silent = true })
end

local function recipe_shown_in_tooltip(player)
  local recipe_name, source = Tooltip.shown(player)
  return recipe_name and player.force.recipes[recipe_name], source
end

local function requested_recipe(player, event)
  if Tooltip.is_sensor(event.element) then return recipe_shown_in_tooltip(player) end

  local selected = event.selected_prototype
  local source = Target.source(player, selected)
  if selected and selected.base_type == "recipe" then
    return player.force.recipes[selected.name], source
  end

  local item_name = Target.item_name(player, selected)
  if not item_name then return nil end
  local recipe = Recipes.find_handcraft_recipe(player, item_name)
  if not recipe then return nil, nil, item_name end
  return recipe, source
end

local function on_craft_input(event)
  local player = player_of(event)
  if not (player and player.character) then return end

  local recipe, source, uncraftable_item = requested_recipe(player, event)
  if uncraftable_item then
    show_failure(player, { "hotbar-craft.no-recipe", "[item=" .. uncraftable_item .. "]" })
    return
  end
  if not recipe then return end

  local craftable = player.get_craftable_count(recipe)
  if craftable == 0 then
    explain_cannot_craft(player, recipe, source, event.cursor_display_location)
  else
    begin_crafting(player, recipe, craftable)
  end
end

local function is_carrying(player, item_name)
  return player.get_item_count(item_name) > 0 or Target.item_in_hand(player) == item_name
end

local function hover_preview_enabled(player)
  return player.character ~= nil and setting(player, HOVER_SETTING)
end

local function hovered_ghost_recipe(player)
  local entity = player.selected
  if not (entity and Target.is_ghost(entity) and hover_preview_enabled(player)) then return nil end

  local item_name = Target.item_to_build(entity)
  if not item_name or is_carrying(player, item_name) then return nil end

  local recipe = Recipes.find_handcraft_recipe(player, item_name)
  if recipe and player.get_craftable_count(recipe) == 0 then return recipe end
end

local function preview_hovered_ghost(player)
  local recipe = hovered_ghost_recipe(player)
  local tree = recipe and missing_tree(player, recipe)
  if tree then Tooltip.show(player, recipe, tree, SOURCE.HOVER) end
end

local function on_selected_entity_changed(event)
  local player = player_of(event)
  Tooltip.close_if_moved_off(player)
  if not Tooltip.is_open(player) then preview_hovered_ghost(player) end
end

local function on_cursor_stack_changed(event)
  Tooltip.close_if_source(player_of(event), SOURCE.CURSOR)
end

local function on_gui_hover(event)
  if Tooltip.is_sensor(event.element) then Tooltip.keep_open(player_of(event)) end
end

local function close_when_sensor(event)
  if Tooltip.is_sensor(event.element) then Tooltip.close(player_of(event)) end
end

local function on_inventory_changed(event)
  Tooltip.refresh(player_of(event))
end

local function on_timer(event)
  Tooltip.close_expired(event.tick)
end

script.on_event(CRAFT_INPUT, on_craft_input)
script.on_event(defines.events.on_selected_entity_changed, on_selected_entity_changed)
script.on_event(defines.events.on_player_cursor_stack_changed, on_cursor_stack_changed)
script.on_event(defines.events.on_gui_hover, on_gui_hover)
script.on_event(defines.events.on_gui_leave, close_when_sensor)
script.on_event(defines.events.on_gui_click, close_when_sensor)
script.on_event(defines.events.on_player_main_inventory_changed, on_inventory_changed)
script.on_nth_tick(10, on_timer)
