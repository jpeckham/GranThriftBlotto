local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(Replicated.Shared.Config)
local Catalog = require(Replicated.Shared.Catalog)
local Rules = require(Replicated.Shared.Rules)
local Match = require(Replicated.Shared.Match)
local Map = require(script.Parent.Map)
local Characters = require(script.Parent.Characters)
local Game = {}
Game.__index = Game
local function root(player)
	return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end
local function move(player, cf)
	local r = root(player)
	if r then
		r.Anchored = false
		r.AssemblyLinearVelocity = Vector3.zero
		player.Character:PivotTo(cf)
	end
end
function Game:state(player)
	local p = self.match and self.match.players[player.UserId]
	return if p and p.connected then p else nil
end
function Game:active(player, role)
	local p = self:state(player)
	return p and not self.match.result and p.role == role and p.status == "Active" and p
end
function Game:near(player, part, range, throughWalls)
	local r = root(player)
	if not r or not part then
		return false
	end
	local delta = part.Position - r.Position
	if delta.Magnitude > (range or 12) then
		return false
	end
	if not throughWalls and delta.Magnitude > 0.1 then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character }
		local hit = workspace:Raycast(r.Position, delta, params)
		if hit and hit.Instance ~= part then
			local model = part:FindFirstAncestorOfClass("Model")
			if
				not model
				or (not model:FindFirstChildOfClass("Humanoid") and not model:GetAttribute("InteractionGroup"))
				or not hit.Instance:IsDescendantOf(model)
			then
				return false
			end
		end
	end
	return true
end
function Game:notify(player, text)
	if player and player.Parent then
		self.notice:FireClient(player, text)
	end
end
function Game:sound(part, name, speed)
	if not part then
		return
	end
	local id = Config.Audio[name]
	if not id or id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = 0.7
	sound.PlaybackSpeed = speed or 1
	sound.RollOffMaxDistance = 80
	sound.Parent = part
	sound:Play()
	Debris:AddItem(sound, 5)
end
function Game:alert(text, position)
	Map.alert(self.world, position, text, workspace:GetServerTimeNow())
	table.insert(self.alerts, { text = text, at = workspace:GetServerTimeNow(), position = position })
	if #self.alerts > 8 then
		table.remove(self.alerts, 1)
	end
end
function Game:syncLoot()
	if not self.match then
		return
	end
	for id, item in self.world.loot do
		local visible = self.match.loot[id].owner == nil
		item.part.Transparency = if visible then 0 else 1
		item.part.CanCollide = visible
		item.prompt.Enabled = visible
	end
end
function Game:prompt(prompt, handler)
	prompt.Triggered:Connect(function(player)
		if not self:near(player, prompt.Parent, prompt.MaxActivationDistance + 2) then
			return
		end
		local gates = self.gates[player.UserId]
		if gates and Rules.allow(gates, "prompt", os.clock(), 0.25) then
			handler(player)
		end
	end)
end
function Game:tag(player, now)
	if not self:active(player, "Cop") then
		return
	end
	local closest, best = nil, Config.TagRange + 0.01
	for _, target in Players:GetPlayers() do
		if self:active(target, "Gran") and self:near(player, root(target), Config.TagRange) then
			local distance = (root(target).Position - root(player).Position).Magnitude
			if distance < best then
				best = distance
				closest = target
			end
		end
	end
	if closest and Match.tag(self.match, player.UserId, closest.UserId, now) then
		local p = self:state(closest)
		self:notify(
			closest,
			if p.status == "Detained"
				then "Detained! A teammate can pick the lock."
				else "Tagged! Get clear before the second tag!"
		)
		if p.status == "Detained" then
			move(closest, self.world.detention)
			self:syncLoot()
		end
		self:notify(
			player,
			if p.status == "Detained" then "Gran detained. Unbanked loot returned." else "One tag! Tag again to detain."
		)
	end
end
function Game:ability(player, now)
	local p = self:active(player, "Gran")
	local r = root(player)
	if not p or not r or not Match.ability(self.match, player.UserId, now) then
		return
	end
	if p.class == "Manager" then
		self:sound(r, if self.economy:snapshot(player).passes.VIP then "VIPComplaint" else "Complaint", 0.8)
		self:alert("EXCUSE ME, I KNOW THE OWNER!", r.Position)
		for _, cop in Players:GetPlayers() do
			local c = self:active(cop, "Cop")
			local cr = root(cop)
			if c and cr and self:near(player, cr, 28) then
				local delta = cr.Position - r.Position
				if delta.Magnitude < 0.1 or r.CFrame.LookVector:Dot(delta.Unit) > 0.45 then
					c.stunUntil = now + Config.Stun
					c.segway = false
				end
			end
		end
		for _, scanner in self.world.scanners do
			if (scanner.Position - r.Position).Magnitude < 45 then
				scanner:SetAttribute("DisabledUntil", now + 6)
			end
		end
	elseif p.class == "Turbo" then
		local direction = r.CFrame.LookVector
		-- A replicated actuator keeps the dash active on the character's physics
		-- owner; a one-off server velocity assignment can be overwritten by it.
		local attachment = Instance.new("Attachment")
		attachment.Name = "TurboDashAttachment"
		attachment.Parent = r
		local velocity = Instance.new("LinearVelocity")
		velocity.Name = "TurboDashVelocity"
		velocity.Attachment0 = attachment
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.VectorVelocity = direction * 62 + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0)
		velocity.MaxForce = r.AssemblyMass * 2000
		velocity.Parent = r
		Debris:AddItem(velocity, 0.35)
		Debris:AddItem(attachment, 0.4)
		p.dashUntil = now + 0.5
		task.spawn(function()
			for _ = 1, 5 do
				if not self.match or self.match.result or not self:active(player, "Gran") then
					break
				end
				for _, cop in Players:GetPlayers() do
					local c = self:active(cop, "Cop")
					if c and self:near(player, root(cop), 9) then
						c.segway = false
						c.stunUntil = workspace:GetServerTimeNow() + 1.5
					end
				end
				task.wait(0.1)
			end
		end)
	end
end
function Game:action(player, payload)
	if not Rules.request(payload) then
		return
	end
	local gates = self.gates[player.UserId]
	if not gates or not Rules.allow(gates, "remote", os.clock(), 0.12) then
		return
	end
	local kind, id = payload.kind, payload.id
	if kind == "Ready" then
		self:send(player)
		return
	end
	if
		kind == "Class"
		and Catalog.Classes[id]
		and (not self:state(player) or self.phase == "Intermission" or self.phase == "Payout")
	then
		self.choices[player.UserId].class = id
	elseif kind == "Preference" and (id == "Cop" or id == "Gran") then
		self.choices[player.UserId].preference = id
	elseif kind == "Buy" or kind == "Equip" then
		if not Catalog.Cosmetics[id] or not Rules.allow(gates, "shop", os.clock(), 1) then
			return
		end
		local ok = if kind == "Buy" then self.economy:buy(player, id) else self.economy:equip(player, id)
		self:notify(
			player,
			if ok then "Wardrobe updated." else "Couldn't update wardrobe. Check funds, ownership and profile status."
		)
	elseif kind == "Pass" and Catalog.Passes[id] and Rules.allow(gates, "shop", os.clock(), 2) then
		self.economy:promptPass(player, id)
	else
		local p = self:state(player)
		local now = workspace:GetServerTimeNow()
		if not p or self.match.result or p.status ~= "Active" or (self.phase ~= "Heist" and self.phase ~= "Escape") then
			return
		end
		if kind == "Tag" then
			self:tag(player, now)
		elseif kind == "Ability" then
			self:ability(player, now)
		elseif
			kind == "Segway"
			and p.role == "Cop"
			and p.stunUntil <= now
			and Rules.allow(p.gates, "mount", now, 1)
		then
			p.segway = not p.segway
		elseif
			kind == "Horn"
			and p.car
			and self.match.cars[p.car].driver == p.id
			and Rules.allow(p.gates, "horn", now, 2)
		then
			self:sound(
				self.world.cars[p.car].body,
				"Horn",
				if self.economy:snapshot(player).passes.GoldenBuick then 0.65 else 1
			)
		elseif kind == "LeaveCar" then
			if Match.leaveCar(self.match, player.UserId) and root(player) then
				move(player, root(player).CFrame + Vector3.new(8, 1, 0))
			end
		elseif
			kind == "Wand"
			and p.role == "Cop"
			and p.stunUntil <= now
			and Rules.allow(p.gates, "wand", now, Config.WandCooldown)
		then
			local ids = {}
			local r = root(player)
			if r then
				for _, target in Players:GetPlayers() do
					if self:active(target, "Gran") and self:near(player, root(target), 55, true) then
						table.insert(ids, target.UserId)
					end
				end
			end
			self.fx:FireClient(player, { kind = "Reveal", ids = ids })
		elseif kind == "CCTV" and p.role == "Cop" and p.stunUntil <= now then
			if id == 0 then
				self.fx:FireClient(player, { kind = "Camera", index = 0 })
			elseif self:near(player, self.world.cameras[1], 170, true) then
				self.fx:FireClient(player, { kind = "Camera", index = id, cf = self.world.cameras[id].CFrame })
			end
		end
	end
	self:send(player)
end
function Game:send(player)
	local snapshot = if self.match then Match.snapshot(self.match) else { players = {}, cars = {}, extracted = 0 }
	snapshot.phase = self.phase
	snapshot.remaining = math.max(0, self.deadline - workspace:GetServerTimeNow())
	if self.phase == "Heist" or self.phase == "Escape" then
		snapshot.remaining = math.max(0, Config.Heist - (workspace:GetServerTimeNow() - self.match.started))
	end
	snapshot.now = workspace:GetServerTimeNow()
	snapshot.alerts = self.alerts
	snapshot.profile = self.economy:snapshot(player)
	snapshot.choice = self.choices[player.UserId]
	snapshot.practice = RunService:IsStudio() and Config.Practice
	self.snapshot:FireClient(player, snapshot)
end
function Game:character(player, char)
	local hum = char:WaitForChild("Humanoid", 10)
	local r = char:WaitForChild("HumanoidRootPart", 10)
	if not hum or not r then
		return
	end
	hum.UseJumpPower = true
	local p = self:state(player)
	move(
		player,
		if p and p.status == "Detained"
			then self.world.detention
			elseif p and p.status == "Active" and not self.match.result then self.world.spawns[p.role]
			else self.world.spawns.Lobby
	)
	hum.Died:Connect(function()
		local current = self:state(player)
		if current and self.match and not self.match.result then
			if current.role == "Gran" then
				Match.capture(self.match, player.UserId)
				self:syncLoot()
			else
				current.segway = false
			end
		end
	end)
end
function Game:join(player)
	self.gates[player.UserId] = {}
	self.choices[player.UserId] = { class = "Manager", preference = "Gran" }
	player.CharacterAdded:Connect(function(char)
		self:character(player, char)
	end)
	if player.Character then
		task.spawn(function()
			self:character(player, player.Character)
		end)
	end
	task.spawn(function()
		self.economy:load(player)
		if player.Parent then
			self:send(player)
		end
	end)
end
function Game:animateCar(index, destination, duration)
	local car = self.world.cars[index]
	local value = Instance.new("CFrameValue")
	value.Value = car.model:GetPivot()
	local conn = value.Changed:Connect(function(cf)
		car.model:PivotTo(cf)
	end)
	local tween = TweenService:Create(
		value,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Value = destination }
	)
	tween:Play()
	tween.Completed:Once(function()
		conn:Disconnect()
		value:Destroy()
	end)
end
function Game:beginRound()
	Map.reset(self.world)
	self.alerts = {}
	local participants = {}
	for i, player in Players:GetPlayers() do
		if i <= Config.MaxPlayers then
			local choice = self.choices[player.UserId]
			local profile = self.economy:snapshot(player)
			table.insert(participants, {
				id = player.UserId,
				name = player.DisplayName,
				class = choice.class,
				preference = choice.preference,
				priority = profile.passes.RolePriority,
			})
		end
	end
	local roles = Rules.roles(participants)
	for _, p in participants do
		p.role = roles[p.id]
	end
	local loot = {}
	for id, item in self.world.loot do
		loot[id] = item.data
	end
	self.match = Match.new(participants, workspace:GetServerTimeNow() + Config.Intro, loot)
	self.roundId = HttpService:GenerateGUID(false)
	self.phase = "Buick Intro"
	self.deadline = self.match.started
	for _, car in self.world.cars do
		car.model:PivotTo(car.home + Vector3.new(0, 0, 32))
		self:animateCar(table.find(self.world.cars, car), car.home, 4)
		for n = 1, 3 do
			local bottle = Instance.new("Part")
			bottle.Name = "EmptyFizzBottle"
			bottle.Size = Vector3.new(0.5, 1.3, 0.5)
			bottle.Color = Color3.fromRGB(233, 172, 95)
			bottle.CFrame = car.home * CFrame.new(n - 2, 4, 1)
			bottle.Parent = self.world.root
			bottle.AssemblyLinearVelocity = Vector3.new(n * 3, 10, 5)
			Debris:AddItem(bottle, 8)
		end
	end
	for _, player in Players:GetPlayers() do
		local p = self:state(player)
		if p then
			move(player, self.world.spawns[p.role] + Vector3.new(math.random(-5, 5), 0, 0))
		end
	end
	self.fx:FireAllClients({
		kind = "Intro",
		cf = CFrame.lookAt(Vector3.new(50, 22, 66), Vector3.new(0, 3, 27)),
		duration = Config.Intro,
	})
end
function Game:update(now)
	Map.updateMonitors(self.world, now)
	if self.phase == "Buick Intro" and now >= self.deadline then
		self.phase = "Heist"
		self.deadline = self.match.started + Config.Heist
	end
	if self.match and (self.phase == "Heist" or self.phase == "Escape") then
		local departed = {}
		for i, car in self.match.cars do
			departed[i] = car.departed
		end
		Match.tick(self.match, now)
		self:syncLoot()
		self.phase = self.match.phase
		for i, car in self.match.cars do
			if car.departed and not departed[i] then
				self:animateCar(i, self.world.cars[i].home + Vector3.new(0, 0, 150), 3)
			end
		end
		if self.match.result then
			self.deadline = now + Config.Payout
			for _, player in Players:GetPlayers() do
				local p = self:state(player)
				if p then
					if not Match.rider(self.match, player.UserId, now) then
						move(player, self.world.spawns.Lobby)
					end
					task.spawn(function()
						for attempt = 1, 3 do
							if self.economy:reward(player, self.roundId, p.reward) then
								break
							end
							if attempt < 3 then
								task.wait(2)
							end
						end
					end)
				end
			end
		end
	elseif self.phase == "Payout" and now >= self.deadline then
		self.match = nil
		self.phase = "Intermission"
		self.deadline = now + Config.Intermission
		Map.reset(self.world)
	elseif self.phase == "Intermission" then
		local minimum = if RunService:IsStudio() and Config.Practice then 1 else Config.MinPlayers
		if #Players:GetPlayers() < minimum then
			self.deadline = now + Config.Intermission
		elseif now >= self.deadline then
			self:beginRound()
		end
	end
	if self.match then
		for _, player in Players:GetPlayers() do
			local p = self:state(player)
			local r = root(player)
			if p and r then
				if p.role == "Gran" and p.status == "Active" and r.Position.Z < -8 then
					if not p.motionPosition or (r.Position - p.motionPosition).Magnitude > 5 then
						p.motionPosition = r.Position
						if Rules.allow(p.gates, "motion", now, 8) then
							self:alert("Motion detected", r.Position)
						end
					end
				end
				local riderCar, riderSeat = Match.rider(self.match, player.UserId, now)
				if riderCar then
					local car = self.world.cars[riderCar]
					local offset = if riderSeat == "Hitch"
						then Vector3.new((player.UserId % 3 - 1) * 2, 1.5, 11)
						else Vector3.new((player.UserId % 3 - 1) * 2, 4, 0)
					r.Anchored = true
					r.CFrame = car.body.CFrame * CFrame.new(offset)
				elseif p.status == "Detained" and not self.match.result then
					r.Anchored = true
					r.CFrame = self.world.detention * CFrame.new((player.UserId % 4 - 1.5) * 3, 0, 0)
				else
					r.Anchored = false
				end
				if p.segway then
					for _, puddle in self.world.puddles do
						if
							(Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(
								puddle.Position.X,
								0,
								puddle.Position.Z
							)).Magnitude < 5
						then
							p.slipUntil = now + 1
							r.AssemblyLinearVelocity += r.CFrame.RightVector * 4
						end
					end
				end
				Characters.apply(player, p, self.economy:snapshot(player), now)
				if p.fizz > 0 and p.status == "Active" and Rules.allow(p.gates, "hiccup", now, 7) then
					self:sound(r, "Hiccup", 1.25)
				end
				if p.status == "Escaped" and not riderCar and not p.escapeFinished then
					move(player, self.world.spawns.Lobby)
					p.escapeFinished = true
				end
			end
		end
	else
		for _, player in Players:GetPlayers() do
			Characters.apply(player, {
				role = "Gran",
				class = self.choices[player.UserId].class,
				bulk = 0,
				fizz = 0,
				hits = 0,
				lastHit = 0,
				stunUntil = 0,
				status = "Active",
			}, self.economy:snapshot(player), now)
		end
	end
end
function Game.start(world, economy)
	local remotes = Instance.new("Folder")
	remotes.Name = "ThriftRemotes"
	remotes.Parent = Replicated
	local self = setmetatable({
		world = world,
		economy = economy,
		phase = "Intermission",
		deadline = workspace:GetServerTimeNow() + Config.Intermission,
		gates = {},
		choices = {},
		alerts = {},
	}, Game)
	for _, key in { "snapshot", "actionRemote", "notice", "fx" } do
		local event = Instance.new("RemoteEvent")
		event.Name = key
		event.Parent = remotes
		self[key] = event
	end
	self.actionRemote.OnServerEvent:Connect(function(player, payload)
		self:action(player, payload)
	end)
	for id, item in world.loot do
		self:prompt(item.prompt, function(player)
			if self.phase ~= "Heist" and self.phase ~= "Escape" then
				return
			end
			if Match.pickup(self.match, player.UserId, id) then
				self:syncLoot()
				local p = self:state(player)
				if item.data.fragile and p.class ~= "Hoarder" then
					self:alert("CRASH! Fragile shelf disturbed", item.part.Position)
					self:sound(item.part, "Crash")
				end
			else
				self:notify(player, "Can't stash that. Check your capacity and role.")
			end
		end)
	end
	for i, car in world.cars do
		for kind, p in car.prompts do
			self:prompt(p, function(player)
				if self.phase ~= "Heist" and self.phase ~= "Escape" then
					return
				end
				local ok
				if kind == "Bank" then
					ok = Match.bank(self.match, player.UserId, i)
					self:syncLoot()
				elseif kind == "Seat" or kind == "Hitch" then
					ok = Match.board(self.match, player.UserId, i, kind)
				elseif kind == "Depart" then
					ok = Match.depart(self.match, player.UserId, i, workspace:GetServerTimeNow())
					if ok then
						self:alert("BUICK " .. i .. " LEAVES IN 7 SECONDS!", car.body.Position)
					end
				end
				if ok and (kind == "Seat" or kind == "Hitch") then
					local driver = self.match.cars[i].driver
					local driverPlayer = driver and Players:GetPlayerByUserId(driver)
					if driverPlayer then
						self:notify(
							player,
							"Driver: " .. driverPlayer.DisplayName .. ". Use the driver-side prompt to depart."
						)
					end
					if driverPlayer and self.economy:snapshot(driverPlayer).passes.GoldenBuick then
						for _, part in car.model:GetDescendants() do
							if
								part:IsA("BasePart")
								and (
									part.Name == "Chassis"
									or part.Name == "Cabin"
									or part.Name == "Boarding"
									or part.Name == "Departure"
								)
							then
								part.Color = Color3.fromRGB(234, 188, 64)
							end
						end
						self:animateCar(i, car.home + Vector3.new(0, 0.65, 0), 0.25)
						task.delay(0.3, function()
							if self.match and not self.match.cars[i].leavesAt then
								self:animateCar(i, car.home, 0.25)
							end
						end)
					end
				end
				if not ok then
					self:notify(player, "Only the chosen seated driver can depart. Bank loot at the trunk.")
				end
			end)
		end
	end
	self:prompt(world.prompts.Cooler, function(player)
		if
			self.match
			and (self.phase == "Heist" or self.phase == "Escape")
			and Match.drink(self.match, player.UserId)
		then
			self:notify(player, "Sparkling Peach Fizz! Speed up, steer carefully.")
			self:sound(root(player), "Fizz")
		end
	end)
	self:prompt(world.prompts.Rescue, function(player)
		if not self:active(player, "Gran") or (self.phase ~= "Heist" and self.phase ~= "Escape") then
			return
		end
		for id, p in self.match.players do
			if p.status == "Detained" and Match.rescue(self.match, player.UserId, id) then
				move(Players:GetPlayerByUserId(id), world.spawns.Cop + Vector3.new(-10, 0, 0))
				self:alert("DETENTION LOCK PICKED!", world.detention.Position)
			end
		end
	end)
	for _, key in { "Shortcut", "Return" } do
		self:prompt(world.prompts[key], function(player)
			if self:active(player, "Gran") then
				move(player, if key == "Shortcut" then world.shortcutExit else world.shortcutEntrance)
			end
		end)
	end
	for _, object in world.root:GetDescendants() do
		if object:IsA("ProximityPrompt") and object.Name == "CCTV" then
			self:prompt(object, function(player)
				self:action(player, { kind = "CCTV", id = 1 })
			end)
		end
	end
	for _, scanner in world.scanners do
		scanner.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			local p = player and self:active(player, "Gran")
			if
				p
				and p.bulk > 0
				and (scanner:GetAttribute("DisabledUntil") or 0) < workspace:GetServerTimeNow()
				and Rules.allow(p.gates, "alarm", workspace:GetServerTimeNow(), 4)
			then
				self:alert("EXIT ALARM! Loaded bloomers at the doors", scanner.Position)
				self:sound(scanner, "Alarm")
			end
		end)
	end
	Players.PlayerAdded:Connect(function(player)
		self:join(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local p = self:state(player)
		if p and self.match then
			local amount = p.banked + (if p.status == "Escaped" then Config.EscapeBonus else 0)
			Match.disconnect(self.match, player.UserId)
			self:syncLoot()
			if amount > 0 then
				self.economy:reward(player, self.roundId, amount)
			end
		end
		self.economy:save(player, true)
		self.gates[player.UserId] = nil
		self.choices[player.UserId] = nil
	end)
	for _, player in Players:GetPlayers() do
		self:join(player)
	end
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.15 then
			return
		end
		elapsed = 0
		self:update(workspace:GetServerTimeNow())
		for _, player in Players:GetPlayers() do
			self:send(player)
		end
	end)
	return self
end
return Game
