local scan = require("plenary.scandir")
local Path = require("plenary.path")
local fn = vim.fn
local M = {}

M.runtime_reload_dirs = { fn.stdpath("config"), fn.stdpath("data") .. "/site/pack/*/start/*" }

local function escape_str(str)
	local patterns_to_escape = {
		"%^",
		"%$",
		"%(",
		"%)",
		"%%",
		"%.",
		"%[",
		"%]",
		"%*",
		"%+",
		"%-",
		"%?",
	}

	return string.gsub(str, string.format("([%s])", table.concat(patterns_to_escape)), "%%%1")
end

local function get_module_name(file_path, base_dir)
	local module_name = file_path
	-- just match the module part and ignore the base directory and extension
	module_name = string.match(module_name, string.format("%s/(.*)%%.lua", escape_str(base_dir)))
	module_name = string.gsub(module_name, "/", ".")
	-- remove .init part of file name
	module_name = string.gsub(module_name, "%.init$", "")

	return module_name
end

local function get_modules_in_path(path)
	local luapath = string.format("%s/lua", path)

	if fn.isdirectory(path) ~= 1 then
		return {}
	end

	local modules = scan.scan_dir(luapath, { search_pattern = "(.+)%.lua$", silent = true, hidden = true })

	for i, module in ipairs(modules) do
		modules[i] = get_module_name(module, luapath)
	end
	return modules
end

local function get_loaded_modules()
	local loaded_modules = {}
	for module in pairs(package.loaded) do
		loaded_modules[module] = true
	end

	return loaded_modules
end

local function table_contains(input_table, value)
	for _, el in ipairs(input_table) do
		if el == value then
			return true
		end
	end

	return false
end

local function get_lua_runtime_paths()
	--TODO: Figure out if nvim_get_runtime_file actually accepts regex
	local runtime_paths = vim.api.nvim_get_runtime_file("lua/*/*.lua", true)
	for _, path in ipairs(vim.api.nvim_get_runtime_file("lua/*.lua", true)) do
		table.insert(runtime_paths, path)
	end
	for _, path in ipairs(vim.api.nvim_get_runtime_file("plugin/*.lua", true)) do
		table.insert(runtime_paths, path)
	end
	for _, path in ipairs(vim.api.nvim_get_runtime_file("colors/*.lua", true)) do
		table.insert(runtime_paths, path)
	end

	return runtime_paths
end

local function get_vim_runtime_paths()
	local runtime_paths = vim.api.nvim_get_runtime_file("plugin/*.vim", true)

	return runtime_paths
end

M.unload_user_config = function()
	local loaded_modules = get_loaded_modules()
	local all_modules = get_modules_in_path(fn.stdpath("config"))
	local unloaded_modules = {}

	for i, module in ipairs(all_modules) do
		if loaded_modules[module] then
			package.loaded[module] = nil
			table.insert(unloaded_modules, module)
		end
	end

	return unloaded_modules
end

M.stop_lsp_clients = function()
	vim.lsp.stop_client(vim.lsp.get_active_clients())
end

M.start_lsp_clients = function()
	local configs = require("lspconfig.configs")

	for _, config in pairs(configs) do
		if table_contains(config.filetypes, vim.bo.filetype) then
			config.launch()
		end
	end
end

M.reload_runtime_dir = function()
	local runtime_paths = get_lua_runtime_paths()
	local loaded_modules = get_loaded_modules()
	local modules = {}

	for _, runtime_path in ipairs(runtime_paths) do
		local base_path = Path:new(runtime_path):parent().filename
		table.insert(modules, get_module_name(runtime_path, base_path))
	end

	for _, module in ipairs(modules) do
		if loaded_modules[module] then
			package.loaded[module] = nil
		end
	end

	for _, module in ipairs(modules) do
		if loaded_modules[module] then
			pcall(require, module)
		end
	end
end

return M
