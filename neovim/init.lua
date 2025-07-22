require("user.colorscheme")
require("user.options")
require("user.keymaps")
require("user.autocommands")
require("user.floating-terminal")

-- NOTE : the above are default configs that do not rely on any plugins or access to a plugin manager.
-- Thus, it is important to require the lazy config only at end, to allow it to override the default options
-- and keymaps
require("user.lazy")
