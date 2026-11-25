local UserInputService = game:GetService("UserInputService")
local UI = require(script.Parent:WaitForChild("UI"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("ThriftRemotes")
local action = remotes:WaitForChild("actionRemote")
local effects
local function send(kind, id)
	if kind == "CCTV" and id == 0 and effects then
		effects:reset()
	end
	action:FireServer({ kind = kind, id = id })
end
local ui = UI.new(send)
effects = Effects.new()
remotes:WaitForChild("snapshot").OnClientEvent:Connect(function(snapshot)
	ui:resize(workspace.CurrentCamera.ViewportSize)
	ui:render(snapshot)
	effects:update(snapshot)
end)
remotes:WaitForChild("notice").OnClientEvent:Connect(function(text)
	ui:notify(text)
end)
remotes:WaitForChild("fx").OnClientEvent:Connect(function(data)
	effects:event(data)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	local key = input.KeyCode
	if key == Enum.KeyCode.M or key == Enum.KeyCode.ButtonSelect then
		ui:toggle()
	elseif key == Enum.KeyCode.Q or key == Enum.KeyCode.ButtonY then
		send(if ui.isCop then "Tag" else "Ability")
	elseif
		key == Enum.KeyCode.F
		or key == Enum.KeyCode.ButtonR2
		or input.UserInputType == Enum.UserInputType.MouseButton1
	then
		if ui.isCop then
			send("Tag")
		end
	elseif key == Enum.KeyCode.R or key == Enum.KeyCode.ButtonL2 then
		send("Wand")
	elseif key == Enum.KeyCode.G or key == Enum.KeyCode.ButtonB then
		send(if ui.isCop then "Segway" else "LeaveCar")
	elseif key == Enum.KeyCode.B then
		send("LeaveCar")
	elseif key == Enum.KeyCode.H or key == Enum.KeyCode.ButtonL3 then
		send("Horn")
	elseif key == Enum.KeyCode.C or key == Enum.KeyCode.ButtonL1 then
		ui:cycleCamera()
	elseif key == Enum.KeyCode.X or key == Enum.KeyCode.ButtonR1 then
		ui:exitCamera()
	end
end)
task.defer(function()
	send("Ready")
end)
