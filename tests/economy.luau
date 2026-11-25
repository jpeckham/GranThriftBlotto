-- Executes the real Economy module; only external Roblox services are replaced.
-- The store double applies actual UpdateAsync transforms to a durable test record.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local rb = require("@lune/roblox")
local Profile = require("../src/ReplicatedStorage/Shared/Profile")
local Catalog = require("../src/ReplicatedStorage/Shared/Catalog")
local Config = require("../src/ReplicatedStorage/Shared/Config")
local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in value do
		result[key] = copy(item)
	end
	return result
end
local function fixture(initial, studio)
	local store = { record = initial, fail = false }
	function store:UpdateAsync(_key, transform)
		if self.fail then
			error("DataStore offline")
		end
		local value = transform(copy(self.record))
		if self.conflict then
			self.conflict = false
			self.record.lease = { owner = "another-server", expires = os.time() + 180 }
			value = transform(copy(self.record))
		end
		if value == nil then
			return nil
		end
		self.record = copy(value)
		return copy(value)
	end
	local config = table.clone(Config)
	config.Products = { [99] = { bucks = 50 } }
	local marketplace = { PromptGamePassPurchaseFinished = { Connect = function() end } }
	local player = { UserId = 7, Parent = true }
	local players = {
		GetPlayers = function()
			return { player }
		end,
		GetPlayerByUserId = function(_, id)
			return if id == 7 then player else nil
		end,
	}
	local services = {
		Players = players,
		DataStoreService = {
			GetDataStore = function()
				if studio then
					error("You must publish this place to the web to access DataStore.")
				end
				return store
			end,
		},
		MarketplaceService = marketplace,
		RunService = {
			IsStudio = function()
				return studio == true
			end,
		},
		HttpService = {
			GenerateGUID = function()
				return "test-guid"
			end,
		},
		ReplicatedStorage = { Shared = { Profile = "Profile", Config = "Config", Catalog = "Catalog" } },
	}
	local id = 0
	local env = {
		Enum = rb.Enum,
		warn = function() end,
		task = { wait = function() end, spawn = function() end },
		game = {
			JobId = "test-job",
			GetService = function(_, name)
				assert(services[name], name)
				return services[name]
			end,
			BindToClose = function() end,
		},
		require = function(name)
			return ({ Profile = Profile, Config = config, Catalog = Catalog })[name]
		end,
	}
	local module = luau.load(
		fs.readFile("src/ServerScriptService/Core/Economy.luau"),
		{ environment = env, debugName = "Economy under service boundary tests" }
	)()
	local function server()
		local instance = module.new()
		id += 1
		instance.token = "test-server-" .. id
		return instance
	end
	return store, server, player, marketplace
end
return {
	["An unpublished Studio place starts without opening a DataStore"] = function()
		local _, server, player = fixture(Profile.new(), true)
		local economy = server()
		economy:load(player)
		assert(economy:snapshot(player).ready and economy:snapshot(player).bucks == 0)
		assert(economy:reward(player, "studio-round", 50))
		assert(economy:snapshot(player).bucks == 50)
	end,
	["A failed load recovers when the player rejoins the same server"] = function()
		local raw = Profile.new()
		raw.bucks = 500
		local store, server, player = fixture(raw)
		store.fail = true
		local economy = server()
		economy:load(player)
		assert(not economy:snapshot(player).ready)
		player.Parent = nil
		economy:save(player, true)
		store.fail = false
		player.Parent = true
		economy:load(player)
		assert(economy:snapshot(player).ready and economy:snapshot(player).bucks == 500)
	end,
	["Receipt is not acknowledged if an UpdateAsync rerun loses the lease"] = function()
		local store, server, player, marketplace = fixture(Profile.new())
		local economy = server()
		economy:load(player)
		store.conflict = true
		local result = marketplace.ProcessReceipt({ PlayerId = 7, ProductId = 99, PurchaseId = "conflict-receipt" })
		assert(result == rb.Enum.ProductPurchaseDecision.NotProcessedYet)
		assert(store.record.bucks == 0 and not store.record.receipts["conflict-receipt"])
		assert(economy:snapshot(player).bucks == 0 and not economy:snapshot(player).ready)
	end,
	["Failed profile load never overwrites an existing balance"] = function()
		local raw = Profile.new()
		raw.bucks = 500
		local store, server, player = fixture(raw)
		store.fail = true
		local economy = server()
		economy:load(player)
		assert(not economy:snapshot(player).ready)
		store.fail = false
		assert(not economy:buy(player, "PlumDress"))
		assert(not economy:save(player, false))
		assert(store.record.bucks == 500 and not store.record.owned.PlumDress)
	end,
	["Session lease prevents another server from spending the wallet"] = function()
		local raw = Profile.new()
		raw.bucks = 500
		local store, server, player = fixture(raw)
		local first = server()
		first:load(player)
		assert(first:buy(player, "PlumDress"))
		local second = server()
		second:load(player)
		assert(not second:snapshot(player).ready)
		assert(not second:buy(player, "MintDress"))
		assert(store.record.bucks == 350 and store.record.owned.PlumDress)
		assert(first:save(player, true))
		local third = server()
		third:load(player)
		assert(third:snapshot(player).ready and third:snapshot(player).bucks == 350)
	end,
	["Failed purchase persistence does not charge the cache or durable record"] = function()
		local raw = Profile.new()
		raw.bucks = 500
		local store, server, player = fixture(raw)
		local economy = server()
		economy:load(player)
		store.fail = true
		assert(not economy:buy(player, "PlumDress"))
		assert(economy:snapshot(player).bucks == 500 and store.record.bucks == 500)
		store.fail = false
		assert(economy:buy(player, "PlumDress"))
		assert(store.record.bucks == 350)
	end,
	["Receipt acknowledgment requires durable grant and retries grant once"] = function()
		local store, server, player, marketplace = fixture(Profile.new())
		local economy = server()
		economy:load(player)
		local receipt = { PlayerId = 7, ProductId = 99, PurchaseId = "receipt-7" }
		store.fail = true
		assert(marketplace.ProcessReceipt(receipt) == rb.Enum.ProductPurchaseDecision.NotProcessedYet)
		assert(store.record.bucks == 0 and economy:snapshot(player).bucks == 0)
		store.fail = false
		assert(marketplace.ProcessReceipt(receipt) == rb.Enum.ProductPurchaseDecision.PurchaseGranted)
		assert(marketplace.ProcessReceipt(receipt) == rb.Enum.ProductPurchaseDecision.PurchaseGranted)
		assert(store.record.bucks == 50 and store.record.receipts["receipt-7"])
	end,
}
