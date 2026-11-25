local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local StudioTest = game:GetService("StudioTestService")
local Http = game:GetService("HttpService")
local bus = Replicated:WaitForChild("NativeTestBus")
local args = StudioTest:GetTestArgs() or { clients = 4 }
local replies, ready, checks = {}, {}, {}
local errors = {}
local platformErrors = {}
local conn = game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError then
		if message:find("[Roblox]", 1, true) then
			table.insert(platformErrors, message)
		else
			table.insert(errors, message)
		end
	end
end)
bus.OnServerEvent:Connect(function(player, data)
	if data.ready then
		ready[player.UserId] = data.result
	else
		replies[data.sequence] = { player = player, data = data }
	end
end)
local function check(condition, label)
	assert(condition, label)
	table.insert(checks, label)
	print("GTB_NATIVE_PASS " .. label)
end
local function waitFor(callback, seconds, label)
	local expires = os.clock() + seconds
	repeat
		if callback() then
			return
		end
		task.wait(0.1)
	until os.clock() > expires
	error("Timed out: " .. label)
end
local sequence = 0
local function client(player, command)
	sequence += 1
	local id = sequence
	command.sequence = id
	bus:FireClient(player, command)
	waitFor(function()
		return replies[id] ~= nil
	end, 15, "client command " .. command.kind .. " for " .. player.Name)
	local response = replies[id]
	replies[id] = nil
	assert(response.player == player and response.data.ok, tostring(response.data.result))
	return response.data.result
end
local function move(player, cf)
	local root = player.Character.HumanoidRootPart
	root.Anchored = false
	root.AssemblyLinearVelocity = Vector3.zero
	player.Character:PivotTo(cf)
	task.wait(0.6)
end
local runtime
local ok, result = xpcall(function()
	local Map = require(game.ServerScriptService.Core.Map)
	local Economy = require(game.ServerScriptService.Core.Economy)
	local Game = require(game.ServerScriptService.Core.Game)
	local Match = require(Replicated.Shared.Match)
	local old = workspace:FindFirstChild("ThriftyAcres")
	if old then
		old:Destroy()
	end
	runtime = Game.start(Map.build(workspace), Economy.new())
	if args.suite == "classes" then
		runtime.deadline = workspace:GetServerTimeNow() + 120
	end
	waitFor(function()
		return #Players:GetPlayers() >= args.clients
	end, 60, "multiplayer clients")
	waitFor(function()
		for _, p in Players:GetPlayers() do
			if not ready[p.UserId] or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
				return false
			end
		end
		return true
	end, 45, "all characters and client HUDs")
	check(#Players:GetPlayers() == args.clients, "native multiplayer clients joined")
	if args.suite == "classes" then
		return require(script.Parent.NativeClassCases)(runtime, client, move, check, waitFor, ready, args, errors)
	end
	if args.suite == "mobile" then
		return require(script.Parent.NativeMobileCases)(runtime, client, check, waitFor, errors)
	end
	waitFor(function()
		return runtime.phase == "Heist"
	end, 45, "normal lobby and Buick intro")
	local grans, cops = {}, {}
	for _, player in Players:GetPlayers() do
		table.insert(if runtime:state(player).role == "Gran" then grans else cops, player)
	end
	check(#cops == 2 and #grans == args.clients - 2, "two Mall Cops and asymmetric Gran team")
	local gran, rescuer, cop = grans[1], grans[2], cops[1]
	check(runtime.match.started + 240 == runtime.deadline, "native heist clock is 240 seconds")
	local inspect = client(gran, { kind = "Inspect" })
	check(inspect.hud and table.concat(inspect.labels, " "):find("HEIST", 1, true), "client HUD renders Heist snapshot")
	for _, player in Players:GetPlayers() do
		if player ~= gran then
			move(player, CFrame.new(60, 4, 60))
		end
	end
	local lootId, item
	for id, value in runtime.world.loot do
		if value.data.fragile then
			lootId = id
			item = value
			break
		end
	end
	move(gran, CFrame.lookAt(item.part.Position + Vector3.new(0, -1.2, 5), item.part.Position))
	client(gran, { kind = "Prompt", prompt = item.prompt })
	check(runtime.match.loot[lootId].owner == gran.UserId, "real ProximityPrompt stashes loot")
	local initialBulk = runtime:state(gran).bulk
	check(gran.Character.ThriftProps.Bloomers.Size.X > 3.5, "native bloomer accessory expands")
	move(gran, CFrame.new(-37, 3, -6))
	client(gran, { kind = "Prompt", prompt = runtime.world.prompts.Cooler })
	check(
		runtime:state(gran).fizz > 90 and gran.Character.Humanoid.WalkSpeed > 16,
		"Fizz changes native capacity and movement (fizz="
			.. runtime:state(gran).fizz
			.. ", speed="
			.. gran.Character.Humanoid.WalkSpeed
			.. ", position="
			.. tostring(gran.Character.HumanoidRootPart.Position)
			.. ")"
	)
	move(gran, CFrame.lookAt(Vector3.new(0, 3, -15), Vector3.new(0, 3, -20)))
	move(cop, CFrame.new(0, 3, -20))
	client(gran, { kind = "Key", key = "Q" })
	check(runtime:state(cop).stunUntil > workspace:GetServerTimeNow(), "Manager keyboard ability stuns cop in cone")
	check(
		runtime.world.scanners[1]:GetAttribute("DisabledUntil") > workspace:GetServerTimeNow(),
		"Manager disables nearby exit scanners"
	)
	task.wait(3.3)
	client(cop, { kind = "Action", action = "Tag" })
	check(runtime:state(gran).hits == 1, "first native baton tag slows Gran")
	task.wait(1.3)
	client(cop, { kind = "Action", action = "Tag" })
	check(
		runtime:state(gran).status == "Detained" and runtime:state(gran).bulk == 0,
		"second native tag detains and confiscates loot"
	)
	check(runtime.match.loot[lootId].owner == nil, "captured loot returns to store shelf")
	move(rescuer, CFrame.new(60, 3, -89))
	client(rescuer, { kind = "Prompt", prompt = runtime.world.prompts.Rescue })
	check(runtime:state(gran).status == "Active", "held detention prompt rescues teammate")
	move(cop, CFrame.new(5, 3, -35))
	move(gran, CFrame.new(5, 3, -45))
	client(cop, { kind = "Action", action = "Segway" })
	check(
		runtime:state(cop).segway and cop.Character.ThriftProps:FindFirstChild("SegwayDeck"),
		"native Segway mount creates vehicle props"
	)
	move(cop, CFrame.new(runtime.world.puddles[1].Position + Vector3.new(0, 3, 0)))
	check(
		runtime:state(cop).slipUntil > workspace:GetServerTimeNow() and cop.Character.Humanoid.WalkSpeed <= 10,
		"Fizz puddle reduces Segway traction"
	)
	move(cop, CFrame.new(5, 3, -35))
	client(cop, { kind = "Action", action = "Wand" })
	check(client(cop, { kind = "Inspect" }).highlights > 0, "tag wand highlights Grans through store racks")
	client(cop, { kind = "Action", action = "CCTV", id = 1 })
	check(client(cop, { kind = "Inspect" }).camera == "Scriptable", "CCTV activates native camera")
	client(cop, { kind = "Button", text = "EXIT CCTV" })
	local cameraReport = client(cop, { kind = "Inspect" })
	check(
		cameraReport.camera == "Custom",
		"visible CCTV exit restores character camera " .. Http:JSONEncode(cameraReport.lastInput)
	)
	-- Approach from inside the last fitting room, not across its solid divider.
	move(gran, CFrame.new(-67, 3, -99))
	client(gran, { kind = "Prompt", prompt = runtime.world.prompts.Shortcut })
	check(gran.Character.HumanoidRootPart.Position.X < -75, "donation vent bypasses scanners onto exterior walkway")
	-- Accumulate real prompted pickups in several trunk trips until the win threshold is met.
	local car = runtime.world.cars[1]
	for _, player in { gran, rescuer } do
		for id, entry in runtime.world.loot do
			if runtime.match.loot[id].owner == nil and runtime.match.cars[1].cargo < 550 then
				if runtime:state(player).bulk + entry.data.bulk > 10 then
					move(player, CFrame.new(car.trunk.Position + Vector3.new(0, 0, 5)))
					client(player, { kind = "Prompt", prompt = car.prompts.Bank })
				end
				move(player, CFrame.lookAt(entry.part.Position + Vector3.new(0, -1.2, 5), entry.part.Position))
				client(player, { kind = "Prompt", prompt = entry.prompt })
			end
			if runtime.match.cars[1].cargo >= 550 then
				break
			end
		end
		move(player, CFrame.new(car.trunk.Position + Vector3.new(0, 0, 5)))
		client(player, { kind = "Prompt", prompt = car.prompts.Bank })
		if runtime.match.cars[1].cargo >= 550 then
			break
		end
	end
	check(runtime.match.cars[1].cargo >= 500, "native prompted loot banking reaches team win threshold")
	move(gran, CFrame.new(car.body.Position + Vector3.new(-8, 1, 0)))
	client(gran, { kind = "Prompt", prompt = car.prompts.Seat })
	move(rescuer, CFrame.new(car.bumper.Position + Vector3.new(0, 1, 3)))
	client(rescuer, { kind = "Prompt", prompt = car.prompts.Hitch })
	check(
		runtime:state(gran).car == 1 and runtime:state(rescuer).seat == "Hitch",
		"native seat boarding and rear bumper hitching work"
	)
	client(gran, { kind = "Prompt", prompt = car.prompts.Depart })
	check(runtime.match.cars[1].leavesAt ~= nil, "seated driver can start departure prompt")
	client(rescuer, { kind = "Action", action = "LeaveCar" })
	task.wait(8)
	check(
		runtime:state(gran).status == "Escaped" and runtime:state(rescuer).status == "Active",
		"Buick extracts boarded Gran and leaves straggler behind"
	)
	check(runtime.match.extracted >= 500, "departed Buick contributes its actual cargo")
	task.wait(3)
	check(
		gran.Character.HumanoidRootPart.Position.Z > 55 and gran.Character.HumanoidRootPart.Position.Z < 80,
		"escaped rider returns to lobby after departure animation"
	)
	runtime.match.started = workspace:GetServerTimeNow() - 240
	waitFor(function()
		return runtime.phase == "Payout"
	end, 4, "round timeout payout")
	check(runtime.match.result == "Grans", "native extraction round awards Gran team win")
	waitFor(function()
		return runtime.economy:snapshot(gran).bucks == runtime:state(gran).reward
	end, 5, "Studio reward wallet")
	check(runtime:state(gran).reward >= 75, "payout includes escape bonus and banked loot")
	local after = client(gran, { kind = "Inspect" })
	check(
		after.camera == "Custom" and table.concat(after.labels, " "):find("RECEIPT", 1, true),
		"payout receipt and camera reset render on client"
	)
	for _, player in Players:GetPlayers() do
		local report = client(player, { kind = "Inspect" })
		for _, message in report.platformErrors do
			table.insert(platformErrors, message)
		end
		check(
			#report.errors == 0,
			"no client script errors for " .. player.Name .. ": " .. table.concat(report.errors, " | ")
		)
	end
	check(#errors == 0, "no server script errors during native scenario")
	return {
		passed = true,
		checks = checks,
		players = args.clients,
		bulk = initialBulk,
		extracted = runtime.match.extracted,
		result = runtime.match.result,
		errors = errors,
	}
end, debug.traceback)
conn:Disconnect()
if ok and type(result) == "table" then
	result.checks = checks
	result.errors = errors
	for _, message in result.platformErrors or {} do
		table.insert(platformErrors, message)
	end
	result.platformErrors = platformErrors
end
if not ok then
	result = { passed = false, error = result, checks = checks, errors = errors, phase = runtime and runtime.phase }
end
print("GTB_MULTIPLAYER_RESULT " .. Http:JSONEncode(result))
StudioTest:EndTest(result)
