local rb = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local Catalog = require("../src/ReplicatedStorage/Shared/Catalog")
-- Lune supplies real Roblox UI instances. The proxy adds only engine events,
-- which Lune doesn't implement; properties and descendants remain real.
local function harness()
	local proxies = setmetatable({}, { __mode = "k" })
	local wrap
	wrap = function(raw)
		if proxies[raw] then
			return proxies[raw]
		end
		local events = {}
		local proxy = { raw = raw }
		proxies[raw] = proxy
		setmetatable(proxy, {
			__index = function(_, key)
				if key == "Activated" then
					if not events[key] then
						local callbacks = {}
						events[key] = {
							Connect = function(_, callback)
								table.insert(callbacks, callback)
							end,
							Fire = function()
								for _, callback in callbacks do
									callback()
								end
							end,
						}
					end
					return events[key]
				end
				if key == "GetChildren" or key == "GetDescendants" then
					return function()
						local result = {}
						for _, child in raw[key](raw) do
							table.insert(result, wrap(child))
						end
						return result
					end
				end
				if key == "WaitForChild" then
					return function(_, name)
						return wrap(assert(raw:FindFirstChild(name)))
					end
				end
				local value = raw[key]
				if type(value) == "function" then
					return function(_, ...)
						return value(raw, ...)
					end
				end
				return value
			end,
			__newindex = function(_, key, value)
				raw[key] = if type(value) == "table" and rawget(value, "raw") then value.raw else value
			end,
		})
		return proxy
	end
	local playerGui = rb.Instance.new("Folder")
	playerGui.Name = "PlayerGui"
	local player = {
		UserId = 7,
		WaitForChild = function(_, name)
			assert(name == "PlayerGui")
			return wrap(playerGui)
		end,
	}
	local services = {
		Players = { LocalPlayer = player },
		ReplicatedStorage = {
			WaitForChild = function()
				return {
					WaitForChild = function(_, name)
						assert(name == "Catalog")
						return "Catalog"
					end,
				}
			end,
		},
		HttpService = {
			JSONEncode = function(_, value)
				return serde.encode("json", value)
			end,
		},
	}
	local env = {
		game = {
			GetService = function(_, name)
				return assert(services[name], name)
			end,
		},
		require = function(token)
			assert(token == "Catalog")
			return Catalog
		end,
		Instance = {
			new = function(class)
				return wrap(rb.Instance.new(class))
			end,
		},
		Enum = rb.Enum,
		UDim2 = rb.UDim2,
		UDim = rb.UDim,
		Vector2 = rb.Vector2,
		Color3 = rb.Color3,
		task = { delay = function() end },
	}
	local UI = luau.load(
		fs.readFile("src/StarterPlayer/StarterPlayerScripts/UI.luau"),
		{ environment = env, debugName = "UI service-boundary tests" }
	)()
	local sent = {}
	local ui = UI.new(function(kind, id)
		table.insert(sent, { kind = kind, id = id })
	end)
	return ui, sent
end
local function snapshot(role)
	return {
		phase = "Heist",
		remaining = 200,
		now = 40,
		extracted = 0,
		cars = {},
		alerts = {},
		profile = { bucks = 0, owned = {}, equipped = {}, passes = {}, prices = {} },
		choice = { class = "Manager" },
		players = {
			{
				id = 7,
				name = "Tester",
				connected = true,
				role = role,
				class = "Manager",
				status = "Active",
				bulk = 2,
				capacity = 10,
				fizz = 10,
				banked = 0,
				abilityAt = 0,
				wandAt = 45,
				reward = 0,
				receipt = {},
				carried = 70,
			},
		},
	}
end
return {
	["Gran touch controls can unboard and use the Buick horn"] = function()
		local ui, sent = harness()
		ui:render(snapshot("Gran"))
		ui.secondary.Activated:Fire()
		ui.mount.Activated:Fire()
		assert(sent[1].kind == "LeaveCar" and sent[2].kind == "Horn")
	end,
	["Touch CCTV buttons cycle and exit the camera"] = function()
		local ui, sent = harness()
		ui:render(snapshot("Cop"))
		assert(ui.cameraNext and ui.cameraExit and ui.cameraNext.Visible and ui.cameraExit.Visible)
		ui.cameraNext.Activated:Fire()
		ui.cameraExit.Activated:Fire()
		assert(sent[1].kind == "CCTV" and sent[1].id == 1)
		assert(sent[2].kind == "CCTV" and sent[2].id == 0)
		ui:render(snapshot("Gran"))
		assert(not ui.cameraNext.Visible and not ui.cameraExit.Visible)
	end,
	["HUD shows carried value and wand cooldown"] = function()
		local ui = harness()
		ui:render(snapshot("Cop"))
		assert(ui.secondary.Text:find("5s", 1, true))
		ui:render(snapshot("Gran"))
		assert(ui.bank.Text:find("70", 1, true))
	end,
}
