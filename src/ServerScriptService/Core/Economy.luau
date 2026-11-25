local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Marketplace = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Profile)
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Economy = {}
Economy.__index = Economy
local function retry(callback)
	for attempt = 1, 3 do
		local ok, value = pcall(callback)
		if ok then
			return true, value
		end
		if attempt < 3 then
			task.wait(attempt)
		else
			warn("Profile operation failed: " .. tostring(value))
		end
	end
	return false, nil
end
function Economy.new()
	local self = setmetatable({
		sessions = {},
		prices = {},
		closing = false,
		store = DataStoreService:GetDataStore(Config.DataStore),
		token = game.JobId .. HttpService:GenerateGUID(false),
	}, Economy)
	task.spawn(function()
		for name, id in Config.Passes do
			if id > 0 then
				local ok, info = pcall(Marketplace.GetProductInfo, Marketplace, id, Enum.InfoType.GamePass)
				if ok and info.IsForSale then
					self.prices[name] = info.PriceInRobux
				end
			end
		end
	end)
	Marketplace.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
		if not purchased then
			return
		end
		local s = self.sessions[player.UserId]
		if not s then
			return
		end
		for name, configured in Config.Passes do
			if configured > 0 and configured == id then
				s.passes[name] = true
			end
		end
	end)
	Marketplace.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		local s = self.sessions[receipt.PlayerId]
		if not player or not s or not s.writable or not Config.Products[receipt.ProductId] then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local granted = false
		self:locked(s, function()
			local nextProfile = Profile.normalize(s.profile)
			if not Profile.receipt(nextProfile, receipt.PurchaseId, receipt.ProductId, Config.Products) then
				return
			end
			if self:write(player, s, nextProfile, false) then
				s.profile = nextProfile
				granted = true
			end
		end)
		return if granted
			then Enum.ProductPurchaseDecision.PurchaseGranted
			else Enum.ProductPurchaseDecision.NotProcessedYet
	end
	task.spawn(function()
		while not self.closing do
			task.wait(45)
			for _, player in Players:GetPlayers() do
				task.spawn(function()
					self:save(player, false)
				end)
			end
		end
	end)
	game:BindToClose(function()
		self.closing = true
		local remaining = 0
		for _, player in Players:GetPlayers() do
			remaining += 1
			task.spawn(function()
				self:save(player, true)
				remaining -= 1
			end)
		end
		local untilTime = os.clock() + 25
		while remaining > 0 and os.clock() < untilTime do
			task.wait(0.1)
		end
	end)
	return self
end
function Economy:locked(s, callback)
	while s.busy do
		task.wait()
	end
	s.busy = true
	local ok, result = pcall(callback)
	s.busy = false
	if not ok then
		warn(result)
	end
	return ok and result
end
function Economy:load(player)
	if self.sessions[player.UserId] then
		return
	end
	local s = {
		profile = Profile.new(),
		passes = {},
		writable = false,
		loading = true,
		busy = false,
		status = "Loading profile",
	}
	self.sessions[player.UserId] = s
	if RunService:IsStudio() then
		s.writable = true
		s.practice = true
		s.status = "Studio session — currency is not saved"
	else
		local acquired = false
		local ok, data = retry(function()
			acquired = false
			return self.store:UpdateAsync("player_" .. player.UserId, function(raw)
				if
					type(raw) == "table"
					and type(raw.lease) == "table"
					and raw.lease.owner ~= self.token
					and (raw.lease.expires or 0) > os.time()
				then
					return nil
				end
				local p = Profile.normalize(raw)
				p.lease = { owner = self.token, expires = os.time() + Config.ProfileLease }
				acquired = true
				return p
			end)
		end)
		if ok and acquired and data then
			s.profile = Profile.normalize(data)
			s.writable = true
			s.status = "Saved profile"
		else
			s.status = "Profile unavailable — economy disabled; rejoin to retry"
		end
	end
	for name, id in Config.Passes do
		if id > 0 then
			local ok, owned = pcall(Marketplace.UserOwnsGamePassAsync, Marketplace, player.UserId, id)
			s.passes[name] = ok and owned
		end
	end
	s.loading = false
	if not player.Parent then
		self:save(player, true)
	end
end
function Economy:write(player, s, profile, release)
	if not s.writable then
		return false
	end
	if s.practice then
		return true
	end
	local acquired = false
	local ok, persisted = retry(function()
		acquired = false
		return self.store:UpdateAsync("player_" .. player.UserId, function(raw)
			acquired = false
			if type(raw) ~= "table" or type(raw.lease) ~= "table" or raw.lease.owner ~= self.token then
				return nil
			end
			local p = Profile.normalize(profile)
			if not release then
				p.lease = { owner = self.token, expires = os.time() + Config.ProfileLease }
			end
			acquired = true
			return p
		end)
	end)
	if ok and (not acquired or not persisted) then
		s.writable = false
		s.status = "Profile session expired — economy disabled"
	end
	return ok and acquired and persisted ~= nil
end
function Economy:save(player, release)
	local s = self.sessions[player.UserId]
	if not s then
		return false
	end
	return self:locked(s, function()
		if release and not s.writable and not s.loading then
			self.sessions[player.UserId] = nil
			return true
		end
		local ok = self:write(player, s, s.profile, release)
		if release and ok then
			s.writable = false
			self.sessions[player.UserId] = nil
		end
		return ok
	end)
end
function Economy:mutate(player, callback)
	local s = self.sessions[player.UserId]
	if not s or not s.writable or s.loading then
		return false
	end
	return self:locked(s, function()
		local nextProfile = Profile.normalize(s.profile)
		if not callback(nextProfile) then
			return false
		end
		if self:write(player, s, nextProfile, false) then
			s.profile = nextProfile
			return true
		end
		return false
	end)
end
function Economy:reward(player, roundId, amount)
	return self:mutate(player, function(p)
		return Profile.reward(p, roundId, amount)
	end)
end
function Economy:buy(player, id)
	return self:mutate(player, function(p)
		return Profile.purchase(p, id)
	end)
end
function Economy:equip(player, id)
	return self:mutate(player, function(p)
		return Profile.equip(p, id)
	end)
end
function Economy:snapshot(player)
	local s = self.sessions[player.UserId]
	local p = Profile.normalize(s and s.profile)
	p.passes = if s then table.clone(s.passes) else {}
	p.status = if s then s.status else "Loading profile"
	p.ready = s ~= nil and not s.loading and s.writable
	p.prices = self.prices
	return p
end
function Economy:promptPass(player, name)
	local id = Config.Passes[name]
	if id and id > 0 and self.prices[name] ~= nil and Catalog.Passes[name] then
		Marketplace:PromptGamePassPurchase(player, id)
	end
end
return Economy
