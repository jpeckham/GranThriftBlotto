local Map = require(script.Parent.Core.Map)
local Economy = require(script.Parent.Core.Economy)
local Game = require(script.Parent.Core.Game)
local preview = workspace:FindFirstChild("ThriftyAcres")
if preview then
	preview:Destroy()
end
Game.start(Map.build(workspace), Economy.new())
