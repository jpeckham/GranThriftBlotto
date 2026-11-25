local fs = require("@lune/fs")
local rb = require("@lune/roblox")
local Map = require("../src/ServerScriptService/Core/Map")
local place = rb.deserializePlace(fs.readFile("build/GranThriftBlotto.rbxlx"))
local workspace = place:FindFirstChildOfClass("Workspace")
assert(workspace, "Rojo place has no Workspace")
local chat = place:FindFirstChildOfClass("TextChatService")
assert(
	chat and chat.ChatVersion == rb.Enum.ChatVersion.TextChatService,
	"Place must initialize current TextChatService rather than legacy ChatScript"
)
Map.build(workspace)
fs.writeFile("build/GranThriftBlotto.rbxl", rb.serializePlace(place))
local check = rb.deserializePlace(fs.readFile("build/GranThriftBlotto.rbxl"))
assert(check:FindFirstChildOfClass("Workspace"):FindFirstChild("ThriftyAcres"))
assert(check:FindFirstChildOfClass("ServerScriptService"):FindFirstChild("Main"))
print("Baked editor map and game scripts into build/GranThriftBlotto.rbxl")
