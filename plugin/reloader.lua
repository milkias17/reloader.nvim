vim.api.nvim_create_user_command(
	"Reload",
	require("reload-nvim").Reload,
	{ desc = "Manually reload your neovim config" }
)

if vim.g.auto_reload_config then
	local reloader_augroup = vim.api.nvim_create_augroup("reloader", { clear = true })
	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		pattern = os.getenv("HOME") .. "/.config/nvim/*",
		callback = require("reload-nvim").Reload,
		group = reloader_augroup,
	})
end
