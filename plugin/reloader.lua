vim.api.nvim_create_user_command(
	"Reload",
	require("reload-nvim").Reload,
	{ desc = "Manually reload your neovim config" }
)

vim.api.nvim_create_user_command(
	"Restart",
	require("reload-nvim").Restart,
	{ desc = "Manually restart your neovim config" }
)
