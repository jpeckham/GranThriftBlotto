local suites = {"rules", "match", "profile", "map"}
local fs = require("@lune/fs")
local total = 0
for _, name in suites do
    if fs.isFile("tests/" .. name .. ".luau") then
        local tests = require("./" .. name)
        for label, test in tests do
            local ok, err = pcall(test)
            if not ok then error(name .. ": " .. label .. "\n" .. tostring(err)) end
            total += 1
            print("PASS " .. name .. ": " .. label)
        end
    end
end
print(tostring(total) .. " tests passed")
