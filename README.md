# Reloader.nvim

A simple plugin that reloads your neovim configuration painlessly.
No more closing neovim and starting it again when you make a change in your configuration
or when a new plugin update comes, a simple `:Reload` and you are off!

This is an [nvim-reload](https://github.com/famiu/nvim-reload) fork.

## Installation

### Requirements

- Neovim >= 0.7
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

### How to install?

Use your favorite package manager and install this plugin as you would any other.

Using [packer](https://github.com/wbthomason/packer.nvim):

```lua
use({ "milkias17/reloader.nvim", requires = { { "nvim-lua/plenary.nvim" } } })
```

Using [plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'milkias17/reloader.nvim'
```

## Usage/Examples

After installation, a `:Reload` command will be available, just call that command
whenever you want to reload your configuration.

### Want to reload your configuration automatically

Just set a global variable named `auto_reload_config` to true and reloader.nvim
will create an autocommand to do this for you!

```lua
vim.g.auto_reload_config = true
```

### Wanted to run something before/after reloading

Reloader.nvim exposes two hooks: `pre_reload_hook` and `post_reload_hook` which
are functions to run before and after reloading.

```lua
local reloader = require("reload-nvim")
reloader.post_reload_hook = function()
    require("feline").reset_highlights()
end
```
