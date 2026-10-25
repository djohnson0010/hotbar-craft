local DEFAULT_CATEGORY = "crafting"

local FALLBACK_ITEM_TYPES = {
  "item", "item-with-entity-data", "ammo", "capsule", "gun", "armor",
  "module", "tool", "repair-tool", "rail-planner", "space-platform-starter-pack",
  "spidertron-remote", "selection-tool", "blueprint", "item-with-tags",
}

local function handcraft_categories()
  local character = data.raw["character"] and data.raw["character"]["character"]
  local categories = {}
  for _, category in pairs(character and character.crafting_categories or { DEFAULT_CATEGORY }) do
    categories[category] = true
  end
  return categories
end

local function item_prototype_types()
  if not (defines and defines.prototypes and defines.prototypes.item) then
    return FALLBACK_ITEM_TYPES
  end
  local item_types = {}
  for item_type in pairs(defines.prototypes.item) do
    item_types[#item_types + 1] = item_type
  end
  return item_types
end

local function find_item(item_types, name)
  for _, item_type in pairs(item_types) do
    local item = data.raw[item_type] and data.raw[item_type][name]
    if item then return item end
  end
end

local function product_amount(recipe, item_name)
  for _, result in pairs(recipe.results or {}) do
    if result.type == "item" and result.name == item_name then
      return result.amount or result.amount_max or 1
    end
  end
  return 0
end

local function handcraftable(recipe, categories)
  if recipe.categories then
    for _, category in pairs(recipe.categories) do
      if categories[category] then return true end
    end
    return false
  end
  return categories[recipe.category or DEFAULT_CATEGORY] == true
end

local function choose_recipe_per_item(categories)
  local chosen = {}
  for recipe_name, recipe in pairs(data.raw["recipe"]) do
    if not recipe.hidden and handcraftable(recipe, categories) then
      for _, result in pairs(recipe.results or {}) do
        if result.type == "item" and (not chosen[result.name] or recipe_name == result.name) then
          chosen[result.name] = recipe
        end
      end
    end
  end
  return chosen
end

local function format_recipe(recipe, item_name)
  local parts = {}
  for _, ingredient in pairs(recipe.ingredients or {}) do
    if ingredient.type == "item" then
      parts[#parts + 1] = ingredient.amount .. " × [item=" .. ingredient.name .. "]"
    end
  end
  if #parts == 0 then return nil end

  local text = table.concat(parts, "  ")
  local output = product_amount(recipe, item_name)
  if output > 1 then text = text .. "  → " .. output end
  return text
end

local function add_recipe_tooltip(item, recipe_text)
  item.custom_tooltip_fields = item.custom_tooltip_fields or {}
  table.insert(item.custom_tooltip_fields, {
    name = { "hotbar-craft.recipe-field" },
    value = recipe_text,
    order = 0,
  })
end

local item_types = item_prototype_types()
for item_name, recipe in pairs(choose_recipe_per_item(handcraft_categories())) do
  local item = find_item(item_types, item_name)
  local recipe_text = item and format_recipe(recipe, item_name)
  if recipe_text then add_recipe_tooltip(item, recipe_text) end
end
