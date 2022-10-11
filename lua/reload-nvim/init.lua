local utils = require("reload-nvim.utils")
local M = {}

M.pre_reload_hook = nil
M.post_reload_hook = nil

M.Reload = function()
	-- notify user of error if pre_reload_hook is not a function
	if type(M.pre_reload_hook) == "function" then
		M.pre_reload_hook()
	elseif M.pre_reload_hook ~= nil then
		vim.notify("pre_reload hook is not a function", vim.log.levels.ERROR, { title = "reload-nvim" })
	end

	local has_lsp, _ = pcall(require, "lspconfig")

	vim.cmd([[highlight clear]])

	if has_lsp then
		utils.stop_lsp_clients()
	end

	utils.unload_user_config()

	vim.cmd([[source $MYVIMRC]])

	if has_lsp then
		utils.start_lsp_clients()
	end

	utils.reload_vimscript_runtime()

	utils.compile_packer()

	if type(M.post_reload_hook) == "function" then
		M.post_reload_hook()
	elseif M.post_reload_hook ~= nil then
		vim.notify("post_reload hook is not a function", vim.log.levels.ERROR, { title = "reload-nvim" })
	end

	vim.notify("Reloaded Config!", vim.log.levels.INFO, { title = "reload-nvim" })
end

return M
