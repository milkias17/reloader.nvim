local scan = require("plenary.scandir")
local fn = vim.fn
local M = {}

M.runtime_subdirs = { "compiler", "doc", "keymap", "syntax", "plugin", "spell" }

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

	local modules = scan.scan_dir(luapath, { search_pattern = "(.+)%.lua$", silent = true })

	for i, module in ipairs(modules) do
		modules[i] = get_module_name(module, luapath)
	end
	return modules
end

local function get_autoloaded_modules_in_path(path)
	local luapath = string.format("%s/plugin", path)

	if fn.isdirectory(path) ~= 1 then
		return {}
	end

	local modules = scan.scan_dir(luapath, { search_pattern = "(.+)%.lua$", silent = true })

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

local function get_viml_files_in_path(path)
	local viml_files = {}

	for _, dir in ipairs(M.runtime_subdirs) do
		local vim_path = string.format("%s/%s", path, dir)

		if fn.isdirectory(path) == 1 then
			local files = scan.scan_dir(vim_path, { search_pattern = "%.vim$", silent = true })

			for _, file in ipairs(files) do
				table.insert(viml_files, file)
			end
		end
	end

	return viml_files
end

local function get_lua_files_in_path(path)
	local lua_files = {}

	local lua_path = string.format("%s/plugin", path)

	if fn.isdirectory(lua_path) ~= 1 then
		return
	end

	for _, file in ipairs(scan.scan_dir(lua_path, { search_pattern = "(.+)%.lua$", silent = true })) do
		table.insert(lua_files, file)
	end

	return lua_files
end

M.unload_user_config = function()
	local loaded_modules = get_loaded_modules()
	local modules = get_modules_in_path(fn.stdpath("config"))
	local luacache = (_G.__luacache or {}).cache

	for _, module in ipairs(modules) do
		if loaded_modules[module] then
			package.loaded[module] = nil
			if luacache then
				luacache[module] = nil
			end
		end
	end
end

M.unload_keybindings = function()
	local modes = { "n", "i", "v", "s", "x", "o", "l", "c", "t" }

	for _, mode in ipairs(modes) do
		for _, keymap in ipairs(vim.api.nvim_get_keymap(mode)) do
			vim.api.nvim_del_keymap(mode, keymap.lhs)
		end
	end
end

M.stop_lsp_clients = function()
	vim.lsp.stop_client(vim.lsp.get_active_clients(), true)
end

M.start_lsp_clients = vim.schedule_wrap(function()
	local configs = require("lspconfig.configs")

	for _, config in pairs(configs) do
		if table_contains(config.filetypes, vim.bo.filetype) then
			config.launch()
		end
	end
end)

M.reload_vimscript_runtime = function()
	local runtime_paths = {}

	for _, runtime_path in ipairs(vim.api.nvim_list_runtime_paths()) do
		if
			string.match(runtime_path, "(.+)/.local/share/nvim/site/pack/(.+)/start")
			or string.match(runtime_path, "(.+)/.config/nvim")
		then
			table.insert(runtime_paths, runtime_path)
		end
	end

	for _, path in ipairs(runtime_paths) do
		local viml_files = get_viml_files_in_path(path)

		for _, file in ipairs(viml_files) do
			vim.cmd("source " .. file)
		end
	end
end

M.reload_lua_runtime = function()
	local runtime_paths = {}

	for _, runtime_path in ipairs(vim.api.nvim_list_runtime_paths()) do
		if string.match(runtime_path, "(.+)/.local/share/nvim/site/pack/(.+)/start") then
			table.insert(runtime_paths, runtime_path)
		end
	end

	for _, path in ipairs(runtime_paths) do
		local files = get_lua_files_in_path(path)

		if files ~= nil and not vim.tbl_isempty(files) then
			for _, file in ipairs(files) do
				vim.cmd("source " .. file)
			end
		end
	end
end

M.compile_packer = function()
	local has_packer, packer = pcall(require, "packer")

	if not has_packer then
		return
	end

	packer.compile()
end

return M
