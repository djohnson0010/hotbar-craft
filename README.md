# Hotbar Craft

**Point at something. Press one key. It gets handcrafted.**

If you can't craft it, a tooltip shows exactly what you're missing.

---

## How to use

1. **Point** at an item, building, ghost, or recipe.
2. **Press** the *Craft hovered item* key (**Alt + Q** by default, **Option + Q** on Mac).
3. **Done.** It's added to your crafting queue.

That's it.

## What you can point at

- 🎯 **Hotbar or inventory slots**
- 🏭 **Buildings** in the world
- 👻 **Ghosts** from blueprints
- 📜 **Recipe buttons** in the crafting menu
- ✋ **Nothing.** Crafts the ghost or item in your hand

## When you can't craft it

A tooltip pops up next to your cursor, styled like the game's own:

- ⚪ **White:** you have enough
- 🟡 **Yellow:** you don't have it, but can craft it from what you carry
- 🔴 **Red:** you're short, and this is what you need to go get

Short intermediates expand underneath, so you can follow the chain down to the raw material you're missing.

The tooltip goes away when you move off, like a normal tooltip.

## Bonus: hover ghosts

Point at a ghost you can't build yet and the tooltip shows up by itself. No key needed. It only appears when something is actually missing.

## Settings

All per player, under **Settings → Mod settings → Per player**:

| Setting | What it does |
|---|---|
| **Craft count** | How many to queue per key press |
| **Missing-ingredients tooltip time** | Backup timer for hiding the tooltip |
| **Show on hover** | Turn the ghost-hover tooltip on or off |

Change the key under **Settings → Controls**.

## Compatibility

- Works with any mod that adds normal handcraftable recipes.
- Supported game version: see the mod portal page or `info.json`.

## Found a bug?

Open an issue on GitHub. A screenshot and the error message help a lot.

## License

GNU GPLv3. See [LICENSE](LICENSE).
