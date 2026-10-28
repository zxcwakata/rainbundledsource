local Hooking = {}

local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

local SelfFire = require("@src/Game/SelfFire")

local LOBBY_PLACE_ID = 4111023553

local oldFireServer = nil
local oldUnreliableFireServer = nil
local oldNameCall = nil
local oldNewIndex = nil
local oldToString = nil
local usingMetaMethodHooks = false

local banRemotes = {}

local INPUT_LEFT_CLICK = 1
local INPUT_RIGHT_CLICK = 2
local INPUT_CRITICAL = 3
local INPUT_CAST = 4
local INPUT_BLOCK = 5

local INPUT_TYPE_BEFORE = 1
local INPUT_TYPE_AFTER = 2

local BLOCK_INPUT_MOVE_MAP = {
	[INPUT_LEFT_CLICK] = "M1s",
	[INPUT_CRITICAL] = "Criticals",
	[INPUT_CAST] = "Mantras",
}

local pendingActionRolls = {}
local actionRollPumpConnection = nil

local hookmetamethod = function(target, method, hook)
	local metatable = getrawmetatable(target)
	setreadonly(metatable, false)
	local original = metatable[method]
	metatable[method] = hook
	setreadonly(metatable, true)
	return original
end

local function captureVMToken()
	local token
	local ok = pcall(function()
		if type(getreg) == "function" then
			token = getreg()
		elseif type(getfenv) == "function" then
			token = getfenv(0)
		end
	end)
	if ok then
		return token
	end
	return nil
end

local MAIN_VM_TOKEN = captureVMToken()

local function foreignVM()
	if MAIN_VM_TOKEN == nil then
		return false
	end
	local token = captureVMToken()
	return token ~= nil and token ~= MAIN_VM_TOKEN
end

local function drainActionRolls()
	if not next(pendingActionRolls) then
		return
	end
	local queued = pendingActionRolls
	pendingActionRolls = {}
	for rollType in next, queued do
		pcall(function()
			-- Try to use existing InputClient/Defense if available
			local ok, InputClient = pcall(require, "@src/Game/InputClient")
			if ok and InputClient and InputClient.dodge then
				pcall(InputClient.dodge, { rollCancel = true, actionRolling = true })
			end
		end)
	end
end

local onInterceptedInput = function(type, state)
	if aztup and aztup.flags and aztup.flags.action_rolling and state == INPUT_TYPE_AFTER then
		pendingActionRolls[type] = true
	end
end

local onNameCall = function(self, ...)
	if foreignVM() then
		return oldNameCall(self, ...)
	end
	if checkcaller() then
		return oldNameCall(self, ...)
	end
	if banRemotes[self] then
		return oldNameCall(self, ...)
	end
	if typeof(self) ~= "Instance" then
		return oldNameCall(self, ...)
	end

	local method = getnamecallmethod()
	local name = self.Name

	if name == "ClientEffectBatch" and method == "FireServer" then
		return
	end

	return oldNameCall(self, ...)
end

local onUnreliableFireServer = function(self, ...)
	if foreignVM() then
		return oldUnreliableFireServer(self, ...)
	end
	if banRemotes[self] then
		return oldUnreliableFireServer(self, ...)
	end
	if SelfFire.active then
		return oldUnreliableFireServer(self, ...)
	end

	local KeyHandling
	local okKh = pcall(require, "@src/Game/KeyHandling")
	if okKh then
		KeyHandling = okKh
	end

	local inputType = nil
	if KeyHandling and KeyHandling.getCachedRemote then
		local leftClickRemote = KeyHandling.getCachedRemote("LeftClick")
		local criticalRemote = KeyHandling.getCachedRemote("CriticalClick")
		local feintClickRemote = KeyHandling.getCachedRemote("FeintClick")
		local offhandAttackRemote = KeyHandling.getCachedRemote("OffhandAttack")

		if criticalRemote and self == criticalRemote then
			inputType = INPUT_CRITICAL
		end
		if leftClickRemote and self == leftClickRemote then
			inputType = INPUT_LEFT_CLICK
		end
		if (feintClickRemote and self == feintClickRemote) or (offhandAttackRemote and self == offhandAttackRemote) then
			inputType = INPUT_RIGHT_CLICK
		end
	end

	if inputType then
		local Defense
		local okDef = pcall(require, "@src/Features/Combat/Defense")
		if okDef then Defense = okDef end

		local blockMove = BLOCK_INPUT_MOVE_MAP[inputType]
		if Defense and Defense.shouldBlockInput and blockMove then
			local okb, blocked = pcall(Defense.shouldBlockInput, blockMove)
			if okb and blocked then
				return
			end
		end

		if inputType == INPUT_LEFT_CLICK and Defense and Defense.tryAutoMixup then
			local okm, handled = pcall(Defense.tryAutoMixup)
			if okm and handled then
				return
			end
		end

		onInterceptedInput(inputType, INPUT_TYPE_BEFORE)
		local result = oldUnreliableFireServer(self, ...)
		onInterceptedInput(inputType, INPUT_TYPE_AFTER)
		return result
	end

	return oldUnreliableFireServer(self, ...)
end

local onFireServer = function(self, ...)
	if foreignVM() then
		return oldFireServer(self, ...)
	end
	if banRemotes[self] then
		return oldFireServer(self, ...)
	end
	if SelfFire.active then
		return oldFireServer(self, ...)
	end

	local KeyHandling
	local okKh = pcall(require, "@src/Game/KeyHandling")
	if okKh then KeyHandling = okKh end

	local inputType = nil
	if KeyHandling and KeyHandling.getCachedRemote then
		local blockRemote = KeyHandling.getCachedRemote("Block")
		if blockRemote and self == blockRemote then
			inputType = INPUT_BLOCK
		end
	end

	if inputType then
		onInterceptedInput(inputType, INPUT_TYPE_BEFORE)
		local result = oldFireServer(self, ...)
		onInterceptedInput(inputType, INPUT_TYPE_AFTER)
		return result
	end

	return oldFireServer(self, ...)
end

local onNewIndex = function(self, index, value, ...)
	if foreignVM() then
		return oldNewIndex(self, index, value, ...)
	end
	if checkcaller() then
		return oldNewIndex(self, index, value, ...)
	end
	if typeof(self) ~= "Instance" then
		return oldNewIndex(self, index, value, ...)
	end

	if index ~= "Text" and index ~= "ActiveController" and index ~= "MouseIconEnabled" and index ~= "WalkSpeed" then
		return oldNewIndex(self, index, value, ...)
	end

	if index == "MouseIconEnabled" then
		return oldNewIndex(self, index, true)
	end

	return oldNewIndex(self, index, value, ...)
end

local onToString = function(str, ...)
	if foreignVM() then
		return oldToString(str, ...)
	end

	if str == "EEKEWAEJIWAJDOIWAJDIOJAWDIOJAWODJOAIW" then
		return coroutine.yield()
	end

	return oldToString(str, ...)
end

function Hooking.earlyInit()
	if game.PlaceId == LOBBY_PLACE_ID then
		return
	end

	pcall(function()
		local lp = playersService.LocalPlayer
		if not lp then return end
		local ps = lp:FindFirstChild("PlayerScripts")
		if not ps then return end
		local clientActor = ps:FindFirstChild("ClientActor")
		if not clientActor then return end
		local cm = clientActor:FindFirstChild("ClientManager")
		if cm and typeof(cm) == "Instance" then
			cm.Enabled = false
		end
	end)

	oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, onFireServer)
	oldUnreliableFireServer = hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, onUnreliableFireServer)
	oldToString = hookfunction(tostring, onToString)

	if hookmetamethod then
		oldNameCall = hookmetamethod(game, "__namecall", onNameCall)
		oldNewIndex = hookmetamethod(game, "__newindex", onNewIndex)
		usingMetaMethodHooks = true
	else
		local gm = getrawmetatable(game)
		setreadonly(gm, false)
		oldNameCall = gm.__namecall
		oldNewIndex = gm.__newindex
		gm.__namecall = onNameCall
		gm.__newindex = onNewIndex
		setreadonly(gm, true)
		usingMetaMethodHooks = false
	end
end

function Hooking.init()
	if game.PlaceId == LOBBY_PLACE_ID then
		return
	end

	pcall(function()
		local requests = replicatedStorage:WaitForChild("Requests", 10)
		if requests then
			for _, req in ipairs(requests:GetChildren()) do
				pcall(function()
					if #getconnections(req.Changed) > 0 then
						banRemotes[req] = true
					end
				end)
			end
		end
	end)

	pcall(function()
		if KeyHandling then
			if KeyHandling.prewarm then
				KeyHandling.prewarm({ "LeftClick", "CriticalClick", "FeintClick", "OffhandAttack", "Block" })
			end
		end
	end)

	if actionRollPumpConnection then
		pcall(function() actionRollPumpConnection:Disconnect() end)
		actionRollPumpConnection = nil
	end
	actionRollPumpConnection = runService.Heartbeat:Connect(drainActionRolls)
end

function Hooking.detach()
	if actionRollPumpConnection then
		pcall(function() actionRollPumpConnection:Disconnect() end)
		actionRollPumpConnection = nil
	end
	table.clear(pendingActionRolls)

	if oldToString then
		pcall(hookfunction, tostring, oldToString)
		oldToString = nil
	end

	if oldNameCall then
		if usingMetaMethodHooks and hookmetamethod then
			pcall(hookmetamethod, game, "__namecall", oldNameCall)
		else
			local gm = getrawmetatable(game)
			setreadonly(gm, false)
			gm.__namecall = oldNameCall
			setreadonly(gm, true)
		end
		oldNameCall = nil
	end

	if oldNewIndex then
		if usingMetaMethodHooks and hookmetamethod then
			pcall(hookmetamethod, game, "__newindex", oldNewIndex)
		else
			local gm = getrawmetatable(game)
			setreadonly(gm, false)
			gm.__newindex = oldNewIndex
			setreadonly(gm, true)
		end
		oldNewIndex = nil
	end

	if oldFireServer then
		pcall(hookfunction, Instance.new("RemoteEvent").FireServer, oldFireServer)
		oldFireServer = nil
	end

	if oldUnreliableFireServer then
		pcall(hookfunction, Instance.new("UnreliableRemoteEvent").FireServer, oldUnreliableFireServer)
		oldUnreliableFireServer = nil
	end

	usingMetaMethodHooks = false
end

return Hooking
