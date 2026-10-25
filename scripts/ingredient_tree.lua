local Recipes = require("scripts.recipes")

local IngredientTree = {}

local MAX_DEPTH = 8

IngredientTree.STATUS = {
  HAVE = "have",
  CRAFTABLE = "craft",
  MISSING = "missing",
}
local STATUS = IngredientTree.STATUS

local function inventory_stock(player)
  local stock = {}
  for _, entry in pairs(player.get_main_inventory().get_contents()) do
    stock[entry.name] = (stock[entry.name] or 0) + entry.count
  end
  return stock
end

local function new_builder(player)
  return { player = player, stock = inventory_stock(player), visiting = {} }
end

local function take_from_stock(builder, item_name, need)
  local have = builder.stock[item_name] or 0
  local used = math.min(have, need)
  builder.stock[item_name] = have - used
  return have, need - used
end

local function return_leftover_to_stock(builder, node, made)
  builder.stock[node.name] = builder.stock[node.name] + made - node.short
end

local expand_recipe

local function expand_shortfall(builder, node, depth)
  local recipe = Recipes.find_handcraft_recipe(builder.player, node.name)
  if not recipe or builder.visiting[recipe.name] then
    node.status = STATUS.MISSING
    return
  end

  local per_craft = Recipes.produced_amount(recipe, node.name)
  local crafts = math.ceil(node.short / per_craft)
  return_leftover_to_stock(builder, node, crafts * per_craft)
  node.children = expand_recipe(builder, recipe, crafts, depth + 1)
  node.status = IngredientTree.has_missing(node.children) and STATUS.MISSING or STATUS.CRAFTABLE
end

local function ingredient_node(builder, ingredient, crafts, depth)
  local need = ingredient.amount * crafts
  local have, short = take_from_stock(builder, ingredient.name, need)
  local node = { name = ingredient.name, need = need, have = have, short = short, status = STATUS.HAVE }
  if short > 0 then expand_shortfall(builder, node, depth) end
  return node
end

expand_recipe = function(builder, recipe, crafts, depth)
  local nodes = {}
  if depth > MAX_DEPTH then return nodes end

  builder.visiting[recipe.name] = true
  for _, ingredient in pairs(recipe.ingredients) do
    if ingredient.type == "item" then
      nodes[#nodes + 1] = ingredient_node(builder, ingredient, crafts, depth)
    end
  end
  builder.visiting[recipe.name] = nil
  return nodes
end

function IngredientTree.build(player, recipe)
  return expand_recipe(new_builder(player), recipe, 1, 0)
end

function IngredientTree.has_missing(nodes)
  for _, node in pairs(nodes) do
    if node.status == STATUS.MISSING then return true end
  end
  return false
end

function IngredientTree.shows_children(node)
  return node.children ~= nil and node.status ~= STATUS.HAVE
end

function IngredientTree.visible_row_count(nodes)
  local rows = 0
  for _, node in pairs(nodes) do
    rows = rows + 1
    if IngredientTree.shows_children(node) then
      rows = rows + IngredientTree.visible_row_count(node.children)
    end
  end
  return rows
end

return IngredientTree
