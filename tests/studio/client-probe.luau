local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remote = Replicated:WaitForChild("NativeTestBus")
local gameRemotes = Replicated:WaitForChild("ThriftRemotes")
local failures = {}
game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError then
		table.insert(failures, message)
	end
end)
local function inspect()
	local hud = player:WaitForChild("PlayerGui"):FindFirstChild("GranThriftHUD")
	local labels = {}
	local highlights = 0
	if hud then
		for _, v in hud:GetDescendants() do
			if v:IsA("TextLabel") or v:IsA("TextButton") then
				table.insert(labels, v.Text)
			end
		end
	end
	for _, v in workspace:GetDescendants() do
		if v:IsA("Highlight") then
			highlights += 1
		end
	end
	return {
		hud = hud ~= nil,
		labels = labels,
		highlights = highlights,
		camera = workspace.CurrentCamera.CameraType.Name,
		errors = failures,
		viewport = { workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y },
	}
end
remote.OnClientEvent:Connect(function(command)
	local ok, result = xpcall(function()
		if command.kind == "Prompt" then
			local prompt = command.prompt
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				workspace.CurrentCamera.CFrame =
					CFrame.lookAt(root.Position + Vector3.new(0, 4, 8), prompt.Parent.Position)
			end
			task.wait(0.2)
			prompt:InputHoldBegin()
			task.wait(prompt.HoldDuration + 0.3)
			prompt:InputHoldEnd()
			task.wait(0.35)
		elseif command.kind == "Action" then
			gameRemotes.actionRemote:FireServer({ kind = command.action, id = command.id })
			task.wait(0.35)
		elseif command.kind == "Key" then
			local input = game:GetService("UserInputService"):CreateVirtualInput()
			input:SendKey(true, Enum.KeyCode[command.key], false)
			task.wait(0.1)
			input:SendKey(false, Enum.KeyCode[command.key], false)
			task.wait(0.35)
		elseif command.kind == "Button" then
			local hud = player.PlayerGui:FindFirstChild("GranThriftHUD")
			local found
			for _, v in hud:GetDescendants() do
				if v:IsA("TextButton") and v.Text:find(command.text, 1, true) then
					found = v
					break
				end
			end
			assert(found and found.Visible, "Button not available: " .. command.text)
			local input = game:GetService("UserInputService"):CreateVirtualInput()
			local pos = found.AbsolutePosition + found.AbsoluteSize / 2
			input:SendMouseButton(pos, Enum.UserInputType.MouseButton1, true, 0)
			task.wait(0.1)
			input:SendMouseButton(pos, Enum.UserInputType.MouseButton1, false, 0)
			task.wait(0.4)
		elseif command.kind == "Leave" then
			if game:GetService("StudioTestService"):CanLeaveTest() then
				game:GetService("StudioTestService"):LeaveTest()
			end
		end
		return inspect()
	end, debug.traceback)
	remote:FireServer({ sequence = command.sequence, ok = ok, result = result })
end)
task.spawn(function()
	local expires = os.clock() + 40
	repeat
		task.wait(0.2)
	until player.PlayerGui:FindFirstChild("GranThriftHUD") or os.clock() > expires
	remote:FireServer({ ready = true, result = inspect() })
end)
