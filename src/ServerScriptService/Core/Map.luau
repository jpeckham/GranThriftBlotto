local rb = if game then nil else require("@lune/roblox")
local Instance = if rb then rb.Instance else Instance
local Vector3 = if rb then rb.Vector3 else Vector3
local CFrame = if rb then rb.CFrame else CFrame
local Color3 = if rb then rb.Color3 else Color3
local Enum = if rb then rb.Enum else Enum
local Catalog = if game
	then require(game:GetService("ReplicatedStorage").Shared.Catalog)
	else require("../../ReplicatedStorage/Shared/Catalog")
local Map = {}
local palette = {
	cream = Color3.fromRGB(239, 224, 189),
	teal = Color3.fromRGB(31, 110, 104),
	pink = Color3.fromRGB(211, 109, 130),
	wood = Color3.fromRGB(141, 101, 68),
	dark = Color3.fromRGB(37, 42, 49),
}
local function folder(parent, name, class)
	local f = Instance.new(class or "Folder")
	f.Name = name
	f.Parent = parent
	return f
end
local function part(parent, name, size, pos, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(pos)
	p.Anchored = true
	p.Color = color or palette.cream
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end
local function sign(parent, text, pos, size, color)
	local p = part(parent, "Sign", size or Vector3.new(18, 4, 0.3), pos, color or palette.teal)
	local gui = folder(p, "Lettering", "SurfaceGui")
	gui.Face = Enum.NormalId.Back
	local label = folder(gui, "Text", "TextLabel")
	label.Size = UDim2 and UDim2.fromScale(1, 1) or rb.UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.FontFace = (if rb then rb.Font else Font).fromEnum(Enum.Font.GothamBold)
	label.TextColor3 = palette.cream
	return p
end
local function prompt(p, name, action, object, hold)
	local q = Instance.new("ProximityPrompt")
	q.Name = name
	q.ActionText = action
	q.ObjectText = object
	q.MaxActivationDistance = 10
	q.HoldDuration = hold or 0.25
	q.RequiresLineOfSight = true
	q.Parent = p
	return q
end
local function car(parent, index, origin)
	local model = folder(parent, "Buick" .. index, "Model")
	model:SetAttribute("InteractionGroup", true)
	local colors = {}
	local function piece(name, size, offset, color, shape)
		local p = part(model, name, size, origin + offset, color, shape)
		colors[p] = p.Color
		return p
	end
	local color = ({ palette.pink, Color3.fromRGB(126, 165, 133), Color3.fromRGB(183, 151, 92) })[index]
	local body = piece("Chassis", Vector3.new(9, 2, 18), Vector3.new(0, 2, 0), color)
	model.PrimaryPart = body
	piece("Cabin", Vector3.new(7.8, 2.5, 8), Vector3.new(0, 4, 0), color)
	local windshield =
		piece("Windshield", Vector3.new(7, 1.8, 0.2), Vector3.new(0, 4, -4.1), Color3.fromRGB(122, 194, 204))
	windshield.Transparency = 0.35
	for _, z in { -5, 5 } do
		for _, x in { -4.6, 4.6 } do
			local wheel =
				piece("Wheel", Vector3.new(3, 1.2, 3), Vector3.new(x, 1.5, z), palette.dark, Enum.PartType.Cylinder)
			wheel.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
		end
	end
	for _, x in { -2.7, 2.7 } do
		piece("Headlamp", Vector3.new(2, 0.6, 0.3), Vector3.new(x, 2, -9.2), Color3.fromRGB(255, 239, 159))
	end
	local trunk = piece("Trunk", Vector3.new(8, 0.6, 4), Vector3.new(0, 3, 6.5), palette.wood)
	local door = piece("Boarding", Vector3.new(0.3, 1, 2), Vector3.new(-4.8, 3, 0), color)
	local bumper = piece("Bumper", Vector3.new(8, 0.5, 0.5), Vector3.new(0, 1.7, 9.3), Color3.fromRGB(200, 200, 195))
	local dash = piece("Departure", Vector3.new(0.3, 1, 2), Vector3.new(4.8, 3, 0), color)
	sign(model, "BUICK " .. index .. "  •  BANK & ESCAPE", origin + Vector3.new(0, 8, 0), Vector3.new(14, 2, 0.2))
	local record = {
		model = model,
		colors = colors,
		home = body.CFrame,
		origin = origin,
		body = body,
		trunk = trunk,
		bumper = bumper,
		prompts = {
			Bank = prompt(trunk, "Bank", "Bank loot", "Buick " .. index),
			Seat = prompt(door, "Seat", "Board / choose driver", "Buick " .. index),
			Hitch = prompt(bumper, "Hitch", "Hitch onto bumper", "Buick " .. index),
			Depart = prompt(dash, "Depart", "Start 7s departure", "Driver only", 1),
		},
	}
	-- A seated rider is inside the car geometry; server validates driver and range.
	record.prompts.Depart.RequiresLineOfSight = false
	return record
end
function Map.build(workspace)
	local root = folder(workspace, "ThriftyAcres", "Model")
	local w = {
		root = root,
		loot = {},
		cars = {},
		prompts = {},
		spawns = {},
		cameras = {},
		monitors = {},
		scanners = {},
		puddles = {},
	}
	local parking = folder(root, "Parking")
	local floor = folder(root, "ThriftFloor")
	local fitting = folder(root, "FittingRooms")
	local security = folder(root, "Security")
	local ground = part(parking, "Asphalt", Vector3.new(180, 1, 90), Vector3.new(0, -0.5, 40), palette.dark)
	ground.Material = Enum.Material.Asphalt
	part(parking, "SideWalkway", Vector3.new(20, 1, 110), Vector3.new(-85, -0.5, -50), palette.dark).Material =
		Enum.Material.Asphalt
	part(floor, "Tile", Vector3.new(150, 1, 105), Vector3.new(0, -0.5, -57.5), palette.cream).Material =
		Enum.Material.Marble
	part(fitting, "Carpet", Vector3.new(32, 0.15, 65), Vector3.new(-59, 0.08, -70), Color3.fromRGB(124, 82, 106)).Material =
		Enum.Material.Carpet
	-- Front wall leaves a 20-stud central entrance; rear and side walls are closed.
	for _, x in { -43, 43 } do
		part(floor, "ShopFront", Vector3.new(64, 16, 1), Vector3.new(x, 8, -5), palette.teal)
	end
	part(floor, "FrontLintel", Vector3.new(20, 4, 1), Vector3.new(0, 14, -5), palette.teal)
	part(floor, "BackWall", Vector3.new(150, 16, 1), Vector3.new(0, 8, -110), palette.cream)
	part(floor, "EastWall", Vector3.new(1, 16, 105), Vector3.new(75, 8, -57.5), palette.cream)
	-- Donation chute opening in west wall, enough width and height for avatars.
	part(fitting, "WestWallNorth", Vector3.new(1, 16, 66), Vector3.new(-75, 8, -77), palette.cream)
	part(fitting, "WestWallSouth", Vector3.new(1, 16, 24), Vector3.new(-75, 8, -17), palette.cream)
	sign(floor, "THRIFTY ACRES", Vector3.new(0, 19, -4), Vector3.new(74, 7, 0.5))
	sign(floor, "GOOD FINDS. QUESTIONABLE GETAWAYS.", Vector3.new(0, 13, -4), Vector3.new(64, 3, 0.4), palette.pink)
	sign(floor, "ORTHOPEDIC SHOE WALL", Vector3.new(35, 10, -108), Vector3.new(36, 3, 0.3))
	sign(fitting, "FITTING ROOMS / DONATIONS", Vector3.new(-57, 10, -108), Vector3.new(34, 3, 0.3), palette.pink)
	sign(security, "SECURITY / DETENTION", Vector3.new(53, 10, -60), Vector3.new(33, 3, 0.3), palette.dark)
	for _, x in { -4.5, 4.5 } do
		part(floor, "ScannerFrame", Vector3.new(0.5, 7, 2), Vector3.new(x * 2, 3.5, -5), Color3.fromRGB(152, 185, 187))
		local scanner =
			part(floor, "ExitScanner", Vector3.new(9, 7, 2), Vector3.new(x, 3.5, -5), Color3.fromRGB(152, 185, 187))
		scanner.CanCollide = false
		scanner.Transparency = 1
		table.insert(w.scanners, scanner)
	end
	for row = 1, 4 do
		local z = -24 - (row - 1) * 19
		for col = 1, 3 do
			local x = -30 + (col - 1) * 26
			local shelf = part(floor, "Shelf", Vector3.new(19, 1, 5), Vector3.new(x, 3, z), palette.wood)
			for _, dx in { -8, 8 } do
				part(floor, "ShelfLeg", Vector3.new(0.5, 3, 4), Vector3.new(x + dx, 1.5, z), palette.wood)
			end
			for slot = 1, 3 do
				local kinds = { "Shoes", "Figurine", "Phone", "Painting", "Inserts" }
				local kind = kinds[(row + col + slot) % #kinds + 1]
				local data = table.clone(Catalog.Loot[kind])
				local id = "loot_" .. row .. "_" .. col .. "_" .. slot
				local p = part(
					floor,
					data.name,
					if kind == "Painting" then Vector3.new(3, 3, 0.4) else Vector3.new(1.5, 1.5, 1.5),
					Vector3.new(x + (slot - 2) * 5, 4.2, z),
					if kind == "Shoes"
						then Color3.fromRGB(211, 191, 155)
						elseif kind == "Figurine" then Color3.fromRGB(241, 222, 218)
						else palette.pink
				)
				if kind == "Figurine" then
					p.Shape = Enum.PartType.Ball
				end
				p:SetAttribute("LootId", id)
				w.loot[id] = {
					part = p,
					data = data,
					home = p.CFrame,
					prompt = prompt(p, "Loot", "Stash ($" .. data.value .. ")", data.name),
				}
			end
			shelf:SetAttribute("Aisle", row)
		end
	end
	local cooler = part(floor, "FizzCooler", Vector3.new(8, 7, 4), Vector3.new(-37, 3.5, -12), palette.teal)
	sign(floor, "SPARKLING PEACH FIZZ", Vector3.new(-37, 8, -9.7), Vector3.new(16, 2, 0.3), palette.pink)
	w.prompts.Cooler = prompt(cooler, "Cooler", "Drink & spill Fizz", "Sparkling Peach Fizz", 0.5)
	for i = 1, 3 do
		local puddle = part(
			floor,
			"FizzPuddle",
			Vector3.new(9, 0.05, 7),
			Vector3.new(-35 + i * 19, 0.06, -20 - i * 16),
			Color3.fromRGB(234, 167, 86)
		)
		puddle.Transparency = 0.5
		puddle.CanCollide = false
		table.insert(w.puddles, puddle)
	end
	for i = 1, 3 do
		local z = -42 - i * 16
		part(fitting, "RoomDivider", Vector3.new(18, 8, 0.5), Vector3.new(-64, 4, z), palette.wood)
		part(fitting, "Curtain", Vector3.new(0.3, 7, 9), Vector3.new(-54, 3.5, z + 5), palette.pink).CanCollide = false
	end
	local chute = part(parking, "DonationChute", Vector3.new(8, 3, 5), Vector3.new(-84, 1.5, -35), palette.teal)
	w.prompts.Return = prompt(chute, "Return", "Crawl into donations", "Shortcut into fitting rooms", 0.5)
	w.shortcutExit = CFrame.new(-84, 4, -28)
	local vent = part(fitting, "VentExit", Vector3.new(5, 0.4, 5), Vector3.new(-67, 0.2, -94), palette.dark)
	w.prompts.Shortcut = prompt(vent, "Shortcut", "Slip outside to donations", "Bypass exit scanners", 0.5)
	w.shortcutEntrance = CFrame.new(-68, 3, -91)
	-- Security room is open toward the main aisle; bench has no touch-trigger trap.
	part(security, "OfficeWall", Vector3.new(30, 10, 0.6), Vector3.new(60, 5, -62), palette.teal)
	local bench = part(security, "DetentionBench", Vector3.new(20, 1.5, 5), Vector3.new(60, 1.5, -96), palette.wood)
	w.detention = CFrame.new(60, 4, -96)
	w.prompts.Rescue = prompt(bench, "Rescue", "Pick detention lock", "Free captured teammates", 2)
	for i = 1, 4 do
		local camera = part(
			security,
			"Camera" .. i,
			Vector3.new(1, 1, 2),
			Vector3.new((if i % 2 == 0 then 35 else -35), 13, -20 - i * 17),
			palette.dark
		)
		camera.CFrame = CFrame.lookAt(camera.CFrame.Position, Vector3.new(0, 2, -50))
		table.insert(w.cameras, camera)
		local screen = part(
			security,
			"CCTVScreen" .. i,
			Vector3.new(5, 3, 0.3),
			Vector3.new(47 + (i - 1) * 6, 6, -108),
			palette.dark
		)
		prompt(screen, "CCTV", "Open CCTV tablet", "Aisle " .. i)
		local display = sign(
			security,
			"AISLE " .. i .. "\nCLEAR",
			screen.CFrame.Position + Vector3.new(0, 0, 0.2),
			Vector3.new(5, 3, 0.1),
			palette.dark
		)
		table.insert(w.monitors, { label = display.Lettering.Text, untilTime = 0, part = display })
	end
	for i = 1, 3 do
		local origin = Vector3.new(-40 + (i - 1) * 40, 0, 27)
		for _, x in { -7, 7 } do
			part(
				parking,
				"ParkingStripe",
				Vector3.new(0.3, 0.04, 24),
				origin + Vector3.new(x, 0.03, 0),
				Color3.fromRGB(239, 232, 197)
			)
		end
		table.insert(w.cars, car(parking, i, origin))
	end
	local lobby = part(parking, "Lobby", Vector3.new(30, 1, 20), Vector3.new(0, 0, 70), palette.teal)
	local spawn = folder(parking, "LobbySpawn", "SpawnLocation")
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(0, 1, 70)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.Neutral = true
	sign(parking, "GRAN THRIFT BLOTTO\nSTASH • RESCUE • SKEDADDLE", Vector3.new(0, 8, 80), Vector3.new(38, 8, 0.3))
	w.spawns.Lobby = CFrame.new(0, 4, 67)
	w.spawns.Gran = CFrame.new(0, 4, 43)
	w.spawns.Cop = CFrame.new(57, 4, -77)
	w.lobby = lobby
	return w
end
function Map.reset(w)
	for _, item in w.loot do
		item.part.Transparency = 0
		item.part.CanCollide = true
		item.prompt.Enabled = true
		item.part.CFrame = item.home
	end
	for _, scanner in w.scanners do
		scanner:SetAttribute("DisabledUntil", 0)
	end
	for _, vehicle in w.cars do
		for p, color in vehicle.colors do
			p.Color = color
		end
	end
	if game then
		for _, vehicle in w.cars do
			vehicle.model:PivotTo(vehicle.home)
		end
	end
end
function Map.alert(w, position, text, now)
	local aisle = math.clamp(math.floor((-position.Z - 24) / 19 + 0.5) + 1, 1, 4)
	local monitor = w.monitors[aisle]
	monitor.label.Text = "AISLE " .. aisle .. "\n" .. text
	monitor.part.Color = palette.pink
	monitor.untilTime = now + 8
end
function Map.updateMonitors(w, now)
	for i, monitor in w.monitors do
		if now >= monitor.untilTime then
			monitor.label.Text = "AISLE " .. i .. "\nCLEAR"
			monitor.part.Color = palette.dark
		end
	end
end
return Map
