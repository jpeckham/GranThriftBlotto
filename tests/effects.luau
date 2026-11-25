local rb = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local function fixture()
	local render, characterAdded
	local hum = { CameraOffset = rb.Vector3.zero, MoveDirection = rb.Vector3.zero }
	local char = {
		FindFirstChildOfClass = function()
			return hum
		end,
	}
	local camera = { CameraType = rb.Enum.CameraType.Custom, CFrame = rb.CFrame.new(), CameraSubject = hum }
	local services = {
		Players = {
			LocalPlayer = {
				UserId = 7,
				Character = char,
				CharacterAdded = {
					Connect = function(_, callback)
						characterAdded = callback
					end,
				},
			},
		},
		RunService = {
			BindToRenderStep = function(_, _, _, callback)
				render = callback
			end,
		},
		Debris = {},
	}
	local env = {
		game = {
			GetService = function(_, name)
				return assert(services[name], name)
			end,
		},
		workspace = { CurrentCamera = camera },
		Enum = rb.Enum,
		Vector3 = rb.Vector3,
		CFrame = rb.CFrame,
		os = {
			clock = function()
				return 1
			end,
		},
	}
	local Effects = luau.load(
		fs.readFile("src/StarterPlayer/StarterPlayerScripts/Effects.luau"),
		{ environment = env, debugName = "Effects service-boundary tests" }
	)()
	local effects = Effects.new()
	return effects,
		camera,
		hum,
		function()
			render()
		end,
		function()
			hum = { CameraOffset = rb.Vector3.zero, MoveDirection = rb.Vector3.zero }
			characterAdded()
			return hum
		end
end
local function snapshot(phase, status)
	return { phase = phase, players = { { id = 7, connected = true, role = "Gran", status = status, fizz = 100 } } }
end
return {
	["Detention restores the character camera after CCTV"] = function()
		local fx, camera, hum, render = fixture()
		fx:event({ kind = "Camera", index = 1, cf = rb.CFrame.new(10, 10, 10) })
		render()
		assert(camera.CameraType == rb.Enum.CameraType.Scriptable)
		fx:update(snapshot("Heist", "Detained"))
		assert(camera.CameraType == rb.Enum.CameraType.Custom and camera.CameraSubject == hum)
	end,
	["Round payout clears Fizz camera offset"] = function()
		local fx, camera, hum, render = fixture()
		fx:update(snapshot("Heist", "Active"))
		render()
		assert(hum.CameraOffset.Magnitude > 0)
		fx:update(snapshot("Payout", "Active"))
		assert(hum.CameraOffset == rb.Vector3.zero and camera.CameraType == rb.Enum.CameraType.Custom)
	end,
	["Character replacement releases CCTV and rebinds camera subject"] = function()
		local fx, camera, _, render, respawn = fixture()
		fx:event({ kind = "Camera", index = 1, cf = rb.CFrame.new(10, 10, 10) })
		render()
		local newHumanoid = respawn()
		assert(camera.CameraType == rb.Enum.CameraType.Custom and camera.CameraSubject == newHumanoid)
	end,
}
