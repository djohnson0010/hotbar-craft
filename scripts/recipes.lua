local Recipes = {}

local function read_optional(object, key)
  local ok, value = pcall(function() return object[key] end)
  if ok then return value end
end

local function category_name(key, value)
  if type(key) == "string" then return key end
  if type(value) == "string" then return value end
  if type(value) == "table" then return value.name end
end

local function category_names(recipe)
  local list = read_optional(recipe, "categories") or read_optional(recipe.prototype, "categories")
  if not list then return { read_optional(recipe, "category") } end

  local names = {}
  for key, value in pairs(list) do
    names[#names + 1] = category_name(key, value)
  end
  return names
end

local function belongs_to_any(recipe, categories)
  for _, name in pairs(category_names(recipe)) do
    if categories[name] then return true end
  end
  return false
end

local function handcraft_categories(player)
  return player.character.prototype.crafting_categories or {}
end

local function can_handcraft(recipe, categories, item_name)
  return recipe ~= nil
    and recipe.enabled
    and not recipe.hidden
    and belongs_to_any(recipe, categories)
    and Recipes.produced_amount(recipe, item_name) > 0
end

local function recipe_names_producing(item_name)
  return prototypes.get_recipe_filtered({
    { filter = "has-product-item", elem_filters = { { filter = "name", name = item_name } } },
  })
end

function Recipes.produced_amount(recipe, item_name)
  for _, product in pairs(recipe.products) do
    if product.type == "item" and product.name == item_name then
      return product.amount or product.amount_max or 1
    end
  end
  return 0
end

function Recipes.find_handcraft_recipe(player, item_name)
  local categories = handcraft_categories(player)
  local recipes = player.force.recipes

  local named_after_item = recipes[item_name]
  if can_handcraft(named_after_item, categories, item_name) then return named_after_item end

  local fallback
  for name in pairs(recipe_names_producing(item_name)) do
    local recipe = recipes[name]
    if can_handcraft(recipe, categories, item_name) then
      if player.get_craftable_count(recipe) > 0 then return recipe end
      fallback = fallback or recipe
    end
  end
  return fallback
end

return Recipes
