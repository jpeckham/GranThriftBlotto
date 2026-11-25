local fs = require("@lune/fs")
local luau = require("@lune/luau")
local count = 0
local function visit(path)
	for _, name in fs.readDir(path) do
		local child = path .. "/" .. name
		if fs.isDir(child) then
			visit(child)
		elseif name:match("%.luau$") then
			luau.compile(fs.readFile(child))
			count += 1
		end
	end
end
visit("src")
print("Compiled " .. count .. " Luau source files")
