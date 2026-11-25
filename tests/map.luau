local rb = require("@lune/roblox")
local Map = require("../src/ServerScriptService/Core/Map")
return {
	["Monitor wall displays aisle alerts and clears expired motion"] = function()
		local w = Map.build(rb.Instance.new("Folder"))
		Map.alert(w, rb.Vector3.new(0, 3, -43), "Motion detected", 10)
		assert(w.monitors[2].label.Text:find("Motion detected", 1, true))
		Map.updateMonitors(w, 19)
		assert(w.monitors[2].label.Text:find("CLEAR", 1, true))
	end,
	["Round reset restores car colors and reenables scanners"] = function()
		local w = Map.build(rb.Instance.new("Folder"))
		local original = w.cars[1].body.Color
		w.cars[1].body.Color = rb.Color3.new(1, 1, 0)
		w.scanners[1]:SetAttribute("DisabledUntil", 100)
		Map.reset(w)
		assert(w.cars[1].body.Color == original and w.scanners[1]:GetAttribute("DisabledUntil") == 0)
	end,
	["Donation shortcut exits beyond the scanners onto a supported walkway"] = function()
		local w = Map.build(rb.Instance.new("Folder"))
		assert(w.shortcutExit.Position.X < -75)
		local walkway = w.root.Parking:FindFirstChild("SideWalkway")
		assert(walkway and math.abs(w.shortcutExit.Position.X - walkway.CFrame.Position.X) < walkway.Size.X / 2)
		assert(math.abs(w.shortcutExit.Position.Z - walkway.CFrame.Position.Z) < walkway.Size.Z / 2)
		assert(w.shortcutEntrance.Position.X > -75)
	end,
	["Generated map roundtrips through Roblox binary format"] = function()
		local w = Map.build(rb.Instance.new("Folder"))
		local encoded = rb.serializeModel({ w.root })
		local decoded = rb.deserializeModel(encoded)
		assert(decoded[1]:FindFirstChild("Parking"):FindFirstChild("Buick1"))
	end,
	["Store builds four zones and unique interactable loot"] = function()
		local workspace = rb.Instance.new("Folder")
		local w = Map.build(workspace)
		for _, name in { "Parking", "ThriftFloor", "FittingRooms", "Security" } do
			assert(w.root:FindFirstChild(name))
		end
		local count = 0
		for id, item in w.loot do
			assert(item.part and item.prompt and item.data.value > 0 and id == item.part:GetAttribute("LootId"))
			count += 1
		end
		assert(count >= 35)
		assert(#w.cameras == 4 and #w.scanners == 2)
		assert(w.prompts.Cooler and w.prompts.Rescue and w.prompts.Shortcut)
	end,
	["Each Buick has complete extraction interactions"] = function()
		local w = Map.build(rb.Instance.new("Folder"))
		assert(#w.cars == 3)
		for _, car in w.cars do
			assert(car.prompts.Bank and car.prompts.Seat and car.prompts.Hitch and car.prompts.Depart)
			assert(car.home.Position.Y > 0 and car.model.PrimaryPart)
			assert(not car.prompts.Depart.RequiresLineOfSight)
		end
	end,
}
