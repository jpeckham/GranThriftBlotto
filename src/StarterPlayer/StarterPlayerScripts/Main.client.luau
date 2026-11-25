local UserInputService = game:GetService("UserInputService")
local UI = require(script.Parent.UI)
local Effects = require(script.Parent.Effects)
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("ThriftRemotes")
local action = remotes:WaitForChild("actionRemote")
local function send(kind, id)
	action:FireServer({ kind = kind, id = id })
end
local ui = UI.new(send)
local effects = Effects.new()
local camera = 0
remotes:WaitForChild("snapshot").OnClientEvent:Connect(function(snapshot)
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
		send("Segway")
	elseif key == Enum.KeyCode.B then
		send("LeaveCar")
	elseif key == Enum.KeyCode.H then
		send("Horn")
	elseif key == Enum.KeyCode.C then
		camera = camera % 4 + 1
		send("CCTV", camera)
	elseif key == Enum.KeyCode.X then
		camera = 0
		send("CCTV", 0)
		effects:reset()
	end
end)
task.defer(function()
	send("Ready")
end)
