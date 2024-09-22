-- Formats a table of strings into a dot-separated string
local function format_namespace(stack)
	return table.concat(stack, '.')
end

-- Recursively search for a .csproj or .sln file in the directory or its parents
local function search(root, dir, stack)
	table.insert(stack, vim.fn.fnamemodify(dir, ':t')) -- Add directory name to stack

	local scan = vim.loop.fs_scandir(dir)
	if scan then
		while true do
			local name, type = vim.loop.fs_scandir_next(scan)
			if not name then break end
			if type == "file" then
				local ext = vim.fn.fnamemodify(name, ":e")
				if ext == "csproj" or ext == "sln" then
					return stack
				end
			end
		end
	end

	local parent = vim.fn.fnamemodify(dir, ':h') -- Get parent directory
	print("parent", parent)
	if parent == nil or parent == root then
		return nil
	end

	return search(root, parent, stack)
end

-- Gets the namespace from the project root and filepath
local function get_namespace()
	local proj_root = vim.fn.getcwd()
	local buf_dir = vim.api.nvim_buf_get_name(0)

	local filepath = vim.fn.fnamemodify(buf_dir, ':h')
	local stack = search(proj_root, filepath, {})

	if not stack then
		return nil
	end

	return format_namespace(stack)
end

local function fill_namespace()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local namespace = get_namespace()
	-- Notice the namespace is given as an array parameter, you can pass multiple strings.
	-- Params 2-5 are for start and end of row and columns.
	-- See earlier docs for param clarification or `:help nvim_buf_set_text.
	vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { namespace })
end


local function setup(opts)
	vim.api.nvim_create_user_command("FillNamespace", fill_namespace, {})
end

return {
	get_namespace = get_namespace,
	fill_namespace = fill_namespace,
	setup = setup
}
