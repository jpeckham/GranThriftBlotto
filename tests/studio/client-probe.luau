local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remote = Replicated:WaitForChild("NativeTestBus")
local gameRemotes = Replicated:WaitForChild("ThriftRemotes")
local failures = {}
local platformErrors = {}
local lastInput
game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError then
		if message:find("[Roblox]", 1, true) then
			table.insert(platformErrors, message)
		else
			table.insert(failures, message)
		end
	end
end)
local function inspect()
	local hud = player:WaitForChild("PlayerGui"):FindFirstChild("GranThriftHUD")
	local labels = {}
	local boxes, clipped = {}, {}
	local function box(object)
		return {
			x = object.AbsolutePosition.X,
			y = object.AbsolutePosition.Y,
			w = object.AbsoluteSize.X,
			h = object.AbsoluteSize.Y,
		}
	end
	local highlights = 0
	if hud then
		for _, v in hud:GetDescendants() do
			if v:IsA("TextLabel") or v:IsA("TextButton") then
				table.insert(labels, v.Text)
				local visible = true
				local ancestor = v
				while ancestor and ancestor ~= hud do
					if ancestor:IsA("GuiObject") and not ancestor.Visible then
						visible = false
						break
					end
					ancestor = ancestor.Parent
				end
				if visible then
					if not v.TextFits and v.Text ~= "" then
						table.insert(clipped, v.Text)
					end
					if v.Text:find("BLOOMERS", 1, true) then
						boxes.stats = box(v.Parent)
					end
					if v.Text:find("BUICK 1:", 1, true) then
						boxes.cars = box(v)
					end
					if v.Text == "MENU / M" then
						boxes.actions = box(v.Parent)
					end
					if v.Text:find("EXIT CCTV", 1, true) then
						boxes.cameraExit = box(v)
					end
					if v.Text:find("CCTV", 1, true) == 1 then
						boxes.cameraNext = box(v)
					end
				end
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
		platformErrors = platformErrors,
		viewport = { workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y },
		safeSize = if hud then { hud.AbsoluteSize.X, hud.AbsoluteSize.Y } else {},
		boxes = boxes,
		clipped = clipped,
		lastInput = lastInput,
	}
end
remote.OnClientEvent:Connect(function(command)
	local ok, result = xpcall(function()
		if command.kind == "Prompt" then
			local prompt = command.prompt
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local camera = workspace.CurrentCamera
			local previousType, previousFrame = camera.CameraType, camera.CFrame
			if root then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = CFrame.lookAt(root.Position + Vector3.new(0, 1, 0), prompt.Parent.Position)
			end
			task.wait(0.2)
			prompt:InputHoldBegin()
			task.wait(prompt.HoldDuration + 0.3)
			prompt:InputHoldEnd()
			camera.CameraType = previousType
			camera.CFrame = previousFrame
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
			local inset = game:GetService("GuiService"):GetGuiInset()
			local pos = found.AbsolutePosition + found.AbsoluteSize / 2 + inset
			local hits = {}
			for _, object in player.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y) do
				table.insert(hits, object:GetFullName())
			end
			lastInput = { x = pos.X, y = pos.Y, button = found.Text, hits = hits }
			input:SendMousePosition(pos)
			task.wait(0.1)
			input:SendMouseButton(pos, Enum.UserInputType.MouseButton1, true, 0)
			task.wait(0.1)
			input:SendMouseButton(pos, Enum.UserInputType.MouseButton1, false, 0)
			task.wait(0.7)
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
