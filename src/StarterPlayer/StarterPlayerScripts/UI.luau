local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local UI = {}
UI.__index = UI
local colors = {
	ink = Color3.fromRGB(28, 43, 46),
	cream = Color3.fromRGB(255, 241, 208),
	mint = Color3.fromRGB(117, 213, 182),
	pink = Color3.fromRGB(247, 151, 168),
	dim = Color3.fromRGB(170, 184, 176),
}
local function new(class, parent, props)
	local object = Instance.new(class)
	for key, value in props do
		object[key] = value
	end
	object.Parent = parent
	return object
end
local function round(object)
	new("UICorner", object, { CornerRadius = UDim.new(0, 12) })
	return object
end
local function label(parent, text, size, pos, fontSize, color)
	return new("TextLabel", parent, {
		Text = text,
		Size = size,
		Position = pos or UDim2.new(),
		BackgroundTransparency = 1,
		TextColor3 = color or colors.cream,
		Font = Enum.Font.GothamBold,
		TextSize = fontSize or 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end
local function button(parent, text, size, pos, callback)
	local b = round(new("TextButton", parent, {
		Text = text,
		Size = size,
		Position = pos or UDim2.new(),
		BackgroundColor3 = colors.mint,
		TextColor3 = colors.ink,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextWrapped = true,
		AutoButtonColor = true,
	}))
	b.Activated:Connect(callback)
	return b
end
local function bar(parent, y, title, color)
	local text = label(parent, title, UDim2.new(1, -24, 0, 21), UDim2.fromOffset(12, y), 13)
	local track = round(new("Frame", parent, {
		Size = UDim2.new(1, -24, 0, 10),
		Position = UDim2.fromOffset(12, y + 25),
		BackgroundColor3 = Color3.fromRGB(64, 78, 77),
		BorderSizePixel = 0,
	}))
	local fill =
		round(new("Frame", track, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = color, BorderSizePixel = 0 }))
	return { text = text, fill = fill }
end
function UI.new(send)
	local self = setmetatable({ send = send, tab = "Help", camera = 0 }, UI)
	local screen = new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {
		Name = "GranThriftHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		DisplayOrder = 10,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	self.screen = screen
	local top = round(new("Frame", screen, {
		Size = UDim2.new(0.96, 0, 0, 74),
		Position = UDim2.fromScale(0.02, 0.01),
		BackgroundColor3 = colors.ink,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
	}))
	self.top = top
	self.title =
		label(top, "GRAN THRIFT\nBLOTTO", UDim2.fromScale(0.29, 0.9), UDim2.fromScale(0.025, 0.05), 18, colors.mint)
	self.timer = label(top, "LOADING…", UDim2.fromScale(0.36, 0.88), UDim2.fromScale(0.32, 0.06), 21)
	self.team =
		label(top, "$0 / $500\nEXTRACTED", UDim2.fromScale(0.26, 0.9), UDim2.fromScale(0.72, 0.05), 17, colors.pink)
	local stats = round(new("Frame", screen, {
		Size = UDim2.new(0.38, 0, 0, 154),
		Position = UDim2.new(0.02, 0, 0, 88),
		BackgroundColor3 = colors.ink,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}))
	self.stats = stats
	self.statsConstraint =
		new("UISizeConstraint", stats, { MaxSize = Vector2.new(330, 154), MinSize = Vector2.new(160, 154) })
	self.role = label(stats, "WELCOME, GRAN", UDim2.new(1, -24, 0, 32), UDim2.fromOffset(12, 4), 16, colors.mint)
	self.capacity = bar(stats, 40, "BLOOMERS", colors.pink)
	self.fizz = bar(stats, 86, "FIZZ", colors.mint)
	self.bank = label(stats, "Banked $0", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 130), 12)
	self.alert = label(screen, "", UDim2.fromScale(0.55, 0.12), UDim2.fromScale(0.43, 0.14), 16, colors.pink)
	self.cars = label(screen, "", UDim2.fromScale(0.55, 0.14), UDim2.fromScale(0.43, 0.26), 14)
	self.cameraNext = button(
		screen,
		"CCTV • C / LB",
		UDim2.new(0.25, 0, 0, 38),
		UDim2.new(0.43, 0, 1, -222),
		function()
			self:cycleCamera()
		end
	)
	self.cameraExit = button(
		screen,
		"EXIT CCTV • X / RB",
		UDim2.new(0.27, 0, 0, 38),
		UDim2.new(0.71, 0, 1, -222),
		function()
			self:exitCamera()
		end
	)
	self.cameraNext.Visible = false
	self.cameraExit.Visible = false
	local bottom = round(new("Frame", screen, {
		Size = UDim2.new(0.96, 0, 0, 96),
		Position = UDim2.new(0.02, 0, 1, -104),
		BackgroundColor3 = colors.ink,
		BorderSizePixel = 0,
		BackgroundTransparency = 0.05,
	}))
	self.bottom = bottom
	self.primary = button(bottom, "Q / ABILITY", UDim2.fromScale(0.24, 0.48), UDim2.fromScale(0.015, 0.08), function()
		send(if self.isCop then "Tag" else "Ability")
	end)
	self.secondary = button(bottom, "R / WAND", UDim2.fromScale(0.22, 0.48), UDim2.fromScale(0.27, 0.08), function()
		send(if self.isCop then "Wand" else "LeaveCar")
	end)
	self.mount = button(bottom, "G / SEGWAY", UDim2.fromScale(0.22, 0.48), UDim2.fromScale(0.50, 0.08), function()
		send(if self.isCop then "Segway" else "Horn")
	end)
	button(bottom, "MENU / M", UDim2.fromScale(0.24, 0.48), UDim2.fromScale(0.735, 0.08), function()
		self.panel.Visible = not self.panel.Visible
		self:rebuild()
	end)
	self.hint = label(
		bottom,
		"E / tap prompts: stash, bank, board, rescue",
		UDim2.new(1, -24, 0, 26),
		UDim2.fromScale(0.015, 0.65),
		12,
		colors.dim
	)
	self.toast = round(label(screen, "", UDim2.new(0.8, 0, 0, 52), UDim2.new(0.1, 0, 1, -168), 16))
	self.toast.BackgroundColor3 = colors.ink
	self.toast.Visible = false
	self.toast.BackgroundTransparency = 0.1
	local panel = round(new("Frame", screen, {
		Size = UDim2.fromScale(0.92, 0.69),
		Position = UDim2.fromScale(0.04, 0.13),
		BackgroundColor3 = colors.ink,
		BorderSizePixel = 0,
		Visible = true,
		ZIndex = 3,
	}))
	self.panel = panel
	self.menuTitle = label(
		panel,
		"THRIFTY ACRES • FIELD GUIDE",
		UDim2.new(0.84, 0, 0, 38),
		UDim2.fromOffset(16, 6),
		18,
		colors.mint
	)
	button(panel, "×", UDim2.fromOffset(36, 34), UDim2.new(1, -46, 0, 8), function()
		panel.Visible = false
	end)
	for i, tab in { "Help", "Classes", "Wardrobe", "Receipt" } do
		button(panel, tab, UDim2.new(0.235, 0, 0, 35), UDim2.new((i - 1) * 0.245 + 0.015, 0, 0, 50), function()
			self.tab = tab
			self:rebuild()
		end)
	end
	local content = new("ScrollingFrame", panel, {
		Name = "Content",
		Size = UDim2.new(1, -28, 1, -112),
		Position = UDim2.fromOffset(14, 96),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	})
	new("UIListLayout", content, { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder })
	self.content = content
	self:rebuild()
	return self
end
function UI:row(text, action, callback)
	local frame = new("Frame", self.content, {
		Size = UDim2.new(1, -8, 0, if self.compact then 120 else 76),
		BackgroundColor3 = Color3.fromRGB(43, 62, 62),
		BorderSizePixel = 0,
	})
	round(frame)
	label(
		frame,
		text,
		UDim2.new(if action then 0.71 else 0.96, -16, 1, -12),
		UDim2.fromOffset(10, 6),
		if self.compact then 12 else 14
	)
	if action then
		return button(frame, action, UDim2.fromScale(0.26, 0.78), UDim2.fromScale(0.73, 0.11), callback)
	end
end
function UI:rebuild()
	for _, child in self.content:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local snapshot = self.last or {}
	local profile = snapshot.profile or { owned = {}, equipped = {}, passes = {}, prices = {}, bucks = 0 }
	if self.tab == "Help" then
		self:row(
			"GRANS: Stash thrift goods in your bloomers. Bank at a Buick trunk, board a seat or hitch to the bumper, then start departure. Extract $500 as a team."
		)
		self:row(
			"COPS: Tag a Gran twice within 8 seconds to detain. G mounts your Segway; R scans through racks. C cycles CCTV; X exits the tablet."
		)
		self:row(
			"Fizz boosts speed and capacity but makes steering wobbly. A teammate can hold the detention prompt to rescue captured Grans. Unbanked loot is lost on capture."
		)
		self:row(
			"Q = class ability / cop baton. F / click = baton. R = wand. G = Segway. B = leave Buick. M = menu. E / gamepad X / tap = nearby interactions."
		)
		self:row("Select your preferred role for the next match.", "Prefer Gran", function()
			self.send("Preference", "Gran")
		end)
		self:row("Role priority increases selection weight. Roles are never guaranteed.", "Prefer Cop", function()
			self.send("Preference", "Cop")
		end)
	elseif self.tab == "Classes" then
		for _, id in { "Manager", "Hoarder", "Turbo" } do
			local data = Catalog.Classes[id]
			self:row(
				data.name .. "\n" .. data.description,
				if snapshot.choice and snapshot.choice.class == id then "Selected" else "Select",
				function()
					self.send("Class", id)
				end
			)
		end
	elseif self.tab == "Wardrobe" then
		self:row("THRIFT BUCKS: $" .. profile.bucks .. "\n" .. (profile.status or ""))
		for _, id in { "PlumDress", "MintDress", "PinkWig", "BlueWalker" } do
			local data = Catalog.Cosmetics[id]
			local owned = profile.owned[id]
			local equipped = profile.equipped[data.slot] == id
			self:row(
				data.name .. "\n" .. (if owned then "Owned" else "$" .. data.price .. " Thrift Bucks"),
				if equipped then "Equipped" elseif owned then "Equip" else "Buy",
				function()
					self.send(if owned then "Equip" else "Buy", id)
				end
			)
		end
		for _, id in { "GoldenBuick", "VIP", "TacticalSegway", "RolePriority" } do
			local data = Catalog.Passes[id]
			local owned = profile.passes[id]
			local price = profile.prices[id]
			local b = self:row(
				data.name .. "\n" .. data.description,
				if owned then "Owned" elseif price then "R$ " .. price else "Unavailable",
				function()
					if not owned and price then
						self.send("Pass", id)
					end
				end
			)
			if not owned and not price then
				b.BackgroundColor3 = colors.dim
				b.AutoButtonColor = false
			end
		end
	elseif self.tab == "Receipt" then
		local me = self.me
		self:row(
			"THRIFTY ACRES RECEIPT\n" .. (snapshot.result or "Round in progress") .. " • Bank goods at a Buick trunk."
		)
		if me then
			for _, item in me.receipt or {} do
				self:row(item.name .. "  $" .. item.value)
			end
			self:row(
				"BANKED: $"
					.. me.banked
					.. "\nROUND REWARD: $"
					.. me.reward
					.. (if me.status == "Escaped" then " (includes $75 escape bonus)" else "")
			)
		end
	end
end
function UI:resize(viewport)
	local compact = viewport.X < 600 or viewport.Y < 500
	local short = viewport.Y < 500
	local mode = if short then "short" elseif compact then "narrow" else "full"
	if self.layoutMode == mode then
		return
	end
	self.layoutMode = mode
	self.compact = compact
	local y = if short then 50 elseif compact then 76 else 88
	local height = if short then 106 elseif compact then 138 else 154
	self.top.Size = UDim2.new(0.96, 0, 0, if short then 42 elseif compact then 62 else 74)
	self.title.TextSize = if compact then 13 else 18
	self.timer.TextSize = if compact then 14 else 21
	self.team.TextSize = if compact then 12 else 17
	self.statsConstraint.MinSize = Vector2.new(if compact then 0 else 160, height)
	self.statsConstraint.MaxSize = Vector2.new(330, height)
	self.stats.Size = UDim2.new(if compact then 0.47 else 0.38, 0, 0, height)
	self.stats.Position = UDim2.new(0.02, 0, 0, y)
	self.role.Size = UDim2.new(1, -24, 0, if compact then 20 else 32)
	self.role.TextSize = if compact then 11 else 16
	for i, meter in { self.capacity, self.fizz } do
		local meterY = if short then 24 + (i - 1) * 28 elseif compact then 30 + (i - 1) * 35 else 40 + (i - 1) * 46
		meter.text.Position = UDim2.fromOffset(12, meterY)
		meter.text.Size = UDim2.new(1, -24, 0, if compact then 16 else 21)
		meter.text.TextSize = if compact then 11 else 13
		meter.fill.Parent.Position = UDim2.fromOffset(12, meterY + (if compact then 18 else 25))
		meter.fill.Parent.Size = UDim2.new(1, -24, 0, if compact then 6 else 10)
	end
	self.bank.Position = UDim2.fromOffset(12, if short then 82 elseif compact then 103 else 130)
	self.bank.Size = UDim2.new(1, -24, 0, if short then 24 elseif compact then 28 else 20)
	self.bank.TextSize = if compact then 10 else 12
	self.alert.Position = if compact then UDim2.new(0.51, 0, 0, y) else UDim2.fromScale(0.43, 0.14)
	self.alert.Size = if compact then UDim2.new(0.47, 0, 0, if short then 30 else 60) else UDim2.fromScale(0.55, 0.12)
	self.alert.TextSize = if compact then 10 else 16
	self.cars.Position = if compact
		then UDim2.new(0.51, 0, 0, y + (if short then 34 else 64))
		else UDim2.fromScale(0.43, 0.26)
	self.cars.Size = if compact then UDim2.new(0.47, 0, 0, if short then 44 else 72) else UDim2.fromScale(0.55, 0.14)
	self.cars.TextSize = if compact then 10 else 14
	self.bottom.Size = UDim2.new(0.96, 0, 0, if compact then 72 else 96)
	self.bottom.Position = UDim2.new(0.02, 0, 1, if compact then -80 else -104)
	for _, child in self.bottom:GetChildren() do
		if child:IsA("TextButton") then
			child.TextSize = if compact then 11 else 14
		end
	end
	self.hint.TextSize = if compact then 9 else 12
	self.hint.Size = UDim2.new(1, -24, 0, if compact then 20 else 26)
	self.menuTitle.TextSize = if compact then 13 else 18
	for _, child in self.panel:GetChildren() do
		if child:IsA("TextButton") then
			child.TextSize = if compact then 11 else 14
		end
	end
	for i, b in { self.cameraNext, self.cameraExit } do
		b.Position = UDim2.new(
			if compact then 0.51 + (i - 1) * 0.245 else 0.43 + (i - 1) * 0.28,
			0,
			1,
			if compact then -122 else -222
		)
		b.Size = UDim2.new(if compact then 0.225 else (if i == 1 then 0.25 else 0.27), 0, 0, 38)
		b.TextSize = if compact then 10 else 14
	end
	self.toast.Position = UDim2.new(0.1, 0, 1, if compact then -178 else -168)
	self.toast.TextSize = if compact then 12 else 16
	self:rebuild()
end
function UI:notify(text)
	self.toast.Text = text
	self.toast.Visible = true
	local token = {}
	self.toastToken = token
	task.delay(4, function()
		if self.toastToken == token then
			self.toast.Visible = false
		end
	end)
end
function UI:cycleCamera()
	self.camera = self.camera % 4 + 1
	self.send("CCTV", self.camera)
end
function UI:exitCamera()
	self.camera = 0
	self.send("CCTV", 0)
end
function UI:render(snapshot)
	local oldPhase = self.last and self.last.phase
	self.last = snapshot
	self.me = nil
	for _, p in snapshot.players do
		if p.id == Players.LocalPlayer.UserId and p.connected then
			self.me = p
		end
	end
	local p = self.me
	self.isCop = p and p.role == "Cop"
	self.cameraNext.Visible = self.isCop == true and p.status == "Active"
	self.cameraExit.Visible = self.cameraNext.Visible
	local seconds = math.ceil(snapshot.remaining)
	self.timer.Text = string.upper(snapshot.phase)
		.. "\n"
		.. string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
	self.team.Text = "$" .. snapshot.extracted .. " / $500\nEXTRACTED"
	self.role.Text = if p then string.upper(p.role .. " • " .. p.status) else "LOBBY • NEXT ROUND"
	self.capacity.text.Text = if p
		then string.format("BLOOMERS %g / %g", p.bulk, p.capacity)
		else "CHOOSE A CLASS IN MENU"
	self.capacity.fill.Size = UDim2.fromScale(if p then math.clamp(p.bulk / p.capacity, 0, 1) else 0, 1)
	self.fizz.text.Text = if p
		then "FIZZ " .. math.floor(p.fizz) .. "%"
		else (if snapshot.practice then "SOLO STUDIO PRACTICE" else "2–10 PLAYERS")
	self.fizz.fill.Size = UDim2.fromScale(if p then p.fizz / 100 else 0, 1)
	self.bank.Text = "Carried $"
		.. (if p then p.carried or 0 else 0)
		.. " • Banked $"
		.. (if p then p.banked else 0)
		.. " • Wallet $"
		.. snapshot.profile.bucks
	if self.compact then
		self.bank.Text = "Carried $"
			.. (if p then p.carried or 0 else 0)
			.. " • Bank $"
			.. (if p then p.banked else 0)
			.. "\nWallet $"
			.. snapshot.profile.bucks
	end
	local cd = if p then math.max(0, math.ceil(p.abilityAt - snapshot.now)) else 0
	self.primary.Text = if self.isCop
		then "Q / TAG GRAN"
		elseif p and p.class == "Hoarder" then "SILENT PICKUP"
		else (if cd > 0 then "ABILITY " .. cd .. "s" else "Q / ABILITY")
	local wandCooldown = if p then math.max(0, math.ceil(p.wandAt - snapshot.now)) else 0
	self.secondary.Text = if self.isCop
		then (if wandCooldown > 0 then "WAND " .. wandCooldown .. "s" else "R / WAND")
		else "B / LEAVE CAR"
	self.mount.Text = if self.isCop then "G / SEGWAY" else "H / BUICK HORN"
	local lines = {}
	for _, car in snapshot.cars do
		table.insert(
			lines,
			"BUICK "
				.. car.id
				.. ": $"
				.. car.cargo
				.. (
					if car.departed
						then " • GONE"
						elseif car.leavesAt then " • LEAVES " .. math.max(
							0,
							math.ceil(car.leavesAt - snapshot.now)
						) .. "s"
						else " • AT CURB"
				)
		)
	end
	self.cars.Text = table.concat(lines, "\n")
	local alerts = {}
	for _, alert in snapshot.alerts or {} do
		if snapshot.now - alert.at < 6 then
			table.insert(alerts, alert.text)
		end
	end
	while #alerts > (if self.compact then 1 else 2) do
		table.remove(alerts, 1)
	end
	self.alert.Text = table.concat(alerts, "\n")
	if oldPhase ~= snapshot.phase then
		if snapshot.phase == "Payout" then
			self.tab = "Receipt"
			self.panel.Visible = true
		elseif snapshot.phase == "Buick Intro" or snapshot.phase == "Heist" then
			self.panel.Visible = false
		end
		self:rebuild()
	elseif self.panel.Visible and (self.tab == "Receipt" or self.tab == "Wardrobe" or self.tab == "Classes") then
		local signature = game:GetService("HttpService")
			:JSONEncode({ snapshot.profile, snapshot.choice, p and p.reward, snapshot.result })
		if signature ~= self.menuSignature then
			self.menuSignature = signature
			self:rebuild()
		end
	end
end
function UI:toggle()
	self.panel.Visible = not self.panel.Visible
	if self.panel.Visible then
		self:rebuild()
	end
end
return UI
