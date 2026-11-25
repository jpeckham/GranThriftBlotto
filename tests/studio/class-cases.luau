return function(runtime, client, move, check, waitFor, ready, args, errors)
	local Players = game:GetService("Players")
	local Test = game:GetService("StudioTestService")
	local bus = game:GetService("ReplicatedStorage").NativeTestBus
	local function roles()
		local grans, cops = {}, {}
		for _, player in Players:GetPlayers() do
			local state = runtime:state(player)
			if state then
				table.insert(if state.role == "Gran" then grans else cops, player)
			end
		end
		return grans, cops
	end
	local function action(player, kind, id)
		return client(player, { kind = "Action", action = kind, id = id })
	end
	local function pickup(player, item)
		move(player, CFrame.lookAt(item.part.Position + Vector3.new(0, -1.2, 5), item.part.Position))
		client(player, { kind = "Prompt", prompt = item.prompt })
	end
	for _, player in Players:GetPlayers() do
		action(player, "Class", "Hoarder")
		check(runtime.choices[player.UserId].class == "Hoarder", "lobby class selection accepted for " .. player.Name)
	end
	runtime.deadline = workspace:GetServerTimeNow()
	waitFor(function()
		return runtime.phase == "Heist"
	end, 15, "Hoarder round intro")
	local grans, cops = roles()
	local gran, rescuer = grans[1], grans[2]
	check(runtime:state(gran).class == "Hoarder", "selected Hoarder class applied to native round")
	local bag = {}
	-- 4 + 4 + 3 + 3 = 14 bulk, independently chosen from the catalog.
	for _, bulk in { 4, 4, 3, 3 } do
		for id, item in runtime.world.loot do
			if item.data.bulk == bulk and not bag[id] then
				bag[id] = true
				pickup(gran, item)
				break
			end
		end
	end
	check(runtime:state(gran).bulk == 14, "Hoarder holds fourteen bulk without Fizz")
	local crashes = 0
	for _, alert in runtime.alerts do
		if alert.text:find("CRASH", 1, true) then
			crashes += 1
		end
	end
	check(crashes == 0, "Hoarder fragile pickups do not trigger crash alerts")
	local extraId, extra
	for id, item in runtime.world.loot do
		if not runtime.match.loot[id].owner and item.data.bulk == 1 then
			extraId = id
			extra = item
			break
		end
	end
	pickup(gran, extra)
	check(
		runtime:state(gran).bulk == 14 and runtime.match.loot[extraId].owner == nil,
		"native pickup rejects a full Hoarder bag"
	)
	move(gran, CFrame.new(-37, 3, -6))
	client(gran, { kind = "Prompt", prompt = runtime.world.prompts.Cooler })
	pickup(gran, extra)
	check(runtime:state(gran).bulk == 15, "Fizz temporarily permits the extra carried item")
	runtime.match.updated = workspace:GetServerTimeNow() - 51
	task.wait(0.4)
	check(
		runtime:state(gran).fizz == 0 and runtime:state(gran).bulk == 15,
		"simulated Fizz expiry preserves overcapacity native bag"
	)
	local oldCharacter = gran.Character
	oldCharacter.Humanoid.Health = 0
	waitFor(function()
		return runtime:state(gran).status == "Detained"
	end, 3, "death detention")
	gran:LoadCharacterAsync()
	waitFor(function()
		return gran.Character ~= oldCharacter and gran.Character:FindFirstChild("HumanoidRootPart") ~= nil
	end, 15, "character respawn")
	task.wait(0.7)
	check(
		runtime:state(gran).bulk == 0
			and (gran.Character.HumanoidRootPart.Position - runtime.world.detention.Position).Magnitude < 8,
		"respawn retains detention and clears unbanked stash"
	)
	check(client(gran, { kind = "Inspect" }).camera == "Custom", "respawn restores the client character camera")
	move(rescuer, CFrame.new(60, 3, -89))
	client(rescuer, { kind = "Prompt", prompt = runtime.world.prompts.Rescue })
	check(runtime:state(gran).status == "Active", "respawned detained player can be rescued")
	local original = {}
	for _, player in Players:GetPlayers() do
		original[player.UserId] = true
	end
	Test:AddPlayers(2)
	waitFor(function()
		return #Players:GetPlayers() == args.clients + 2
	end, 35, "late-joining clients")
	local late = {}
	for _, player in Players:GetPlayers() do
		if not original[player.UserId] then
			table.insert(late, player)
		end
	end
	waitFor(function()
		for _, player in late do
			if not ready[player.UserId] then
				return false
			end
		end
		return true
	end, 35, "late client HUDs")
	for _, player in late do
		check(runtime:state(player) == nil, "late join waits outside active match for " .. player.Name)
		local report = client(player, { kind = "Inspect" })
		check(
			table.concat(report.labels, " "):find("LOBBY", 1, true),
			"late join renders lobby HUD for " .. player.Name
		)
	end
	runtime.match.started = workspace:GetServerTimeNow() - 240
	waitFor(function()
		return runtime.phase == "Payout"
	end, 3, "first round payout")
	for _, player in Players:GetPlayers() do
		action(player, "Class", "Turbo")
	end
	runtime.deadline = workspace:GetServerTimeNow()
	waitFor(function()
		return runtime.phase == "Intermission"
	end, 3, "payout to intermission")
	runtime.deadline = workspace:GetServerTimeNow()
	waitFor(function()
		return runtime.phase == "Heist"
	end, 15, "Turbo round intro")
	grans, cops = roles()
	gran = grans[1]
	local cop = cops[1]
	check(#grans == args.clients and #cops == 2, "next round includes late joins with two cops")
	check(runtime:state(gran).class == "Turbo", "Turbo selection applied on the next round")
	move(gran, CFrame.new(0, 3, 20))
	check(
		math.abs(gran.Character.Humanoid.WalkSpeed - 19.2) < 0.05,
		"Turbo native parking speed is twenty percent faster"
	)
	move(gran, CFrame.lookAt(Vector3.new(0, 3, -32), Vector3.new(0, 3, -42)))
	check(gran.Character.Humanoid.WalkSpeed == 16, "Turbo native store speed returns to base")
	move(cop, CFrame.new(0, 3, -38))
	action(cop, "Segway")
	local before = gran.Character.HumanoidRootPart.Position
	client(gran, { kind = "Key", key = "Q" })
	check(
		not runtime:state(cop).segway and runtime:state(cop).stunUntil > workspace:GetServerTimeNow(),
		"Turbo dash ram dismounts and stuns a nearby cop"
	)
	check(
		(gran.Character.HumanoidRootPart.Position - before).Magnitude > 1,
		"Turbo dash moves the native character (distance="
			.. (gran.Character.HumanoidRootPart.Position - before).Magnitude
			.. ")"
	)
	local cooldown = runtime:state(gran).gates.ability
	action(gran, "Ability")
	check(runtime:state(gran).gates.ability == cooldown, "Turbo ability cannot bypass cooldown")
	local leaveId, leaveItem
	for id, item in runtime.world.loot do
		if not runtime.match.loot[id].owner then
			leaveId = id
			leaveItem = item
			break
		end
	end
	pickup(gran, leaveItem)
	check(runtime.match.loot[leaveId].owner == gran.UserId, "departing test player carries real loot")
	local departedId = gran.UserId
	local beforeCount = #Players:GetPlayers()
	bus:FireClient(gran, { kind = "Leave", sequence = -100 })
	waitFor(function()
		return #Players:GetPlayers() == beforeCount - 1
	end, 15, "test client departure")
	check(
		not runtime.match.players[departedId].connected and runtime.match.loot[leaveId].owner == nil,
		"disconnect releases unbanked native loot and match membership"
	)
	runtime.match.started = workspace:GetServerTimeNow() - 240
	waitFor(function()
		return runtime.phase == "Payout"
	end, 3, "round resolution after disconnect")
	check(runtime.match.result == "Cops", "round resolves after a player disconnects")
	for _, player in Players:GetPlayers() do
		check(
			#client(player, { kind = "Inspect" }).errors == 0,
			"no client errors in class/lifecycle test for " .. player.Name
		)
	end
	check(#errors == 0, "no server errors in class/lifecycle test")
	return { passed = true, suite = "classes-and-lifecycle", players = beforeCount }
end
