local scan = require("plenary.scandir")
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

M.unload_user_config = function()
	local loaded_modules = get_loaded_modules()
	local all_modules = get_modules_in_path(fn.stdpath("config"))
	local unloaded_modules = {}

	for _, module in ipairs(all_modules) do
		if loaded_modules[module] then
			package.loaded[module] = nil
			table.insert(unloaded_modules, module)
		end
	end

	return unloaded_modules
end

return M
