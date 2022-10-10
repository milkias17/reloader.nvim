local utils = require("reload-nvim.utils")
local cmd = vim.cmd

local M = {}

M.Reload = function()
	cmd([[highlight clear]])

	local unloaded_modules = utils.unload_user_config()

	for _, module in ipairs(unloaded_modules) do
		require(module)
	end

	cmd([[LspRestart]])
end

M.Restart = function()
	M.Reload()

	cmd("doautocmd VimEnter")
end

return M
