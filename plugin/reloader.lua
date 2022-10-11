vim.api.nvim_create_user_command(
	"Reload",
	require("reload-nvim").Reload,
	{ desc = "Manually reload your neovim config" }
)
