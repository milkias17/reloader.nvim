local utils = require("reload-nvim.utils")
local cmd = vim.cmd

local M = {}

M.Reload = function()
	cmd([[highlight clear]])

	local unloaded_modules = utils.unload_user_config()

	for _, module in ipairs(unloaded_modules) do
		require(module)
	end

	if vim.fn.exists(":LspStatus") ~= 0 then
		cmd([[LspRestart]])
	end

	vim.notify("Reloaded Config!")
end

M.Restart = function()
	M.Reload()

	cmd("doautocmd VimEnter")
end

return M
