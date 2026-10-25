data:extend({
  {
    type = "int-setting",
    name = "hotbar-craft-count",
    setting_type = "runtime-per-user",
    default_value = 1,
    minimum_value = 1,
    maximum_value = 100,
    order = "a",
  },
  {
    type = "int-setting",
    name = "hotbar-craft-popup-seconds",
    setting_type = "runtime-per-user",
    default_value = 5,
    minimum_value = 1,
    maximum_value = 60,
    order = "b",
  },
  {
    type = "bool-setting",
    name = "hotbar-craft-hover",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "c",
  },
})
