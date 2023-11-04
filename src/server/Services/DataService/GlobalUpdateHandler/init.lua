local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.packages.knit)

local Promise = require(ReplicatedStorage.packages.promise)

local GlobalUpdates = {}

function GlobalUpdates:HandleLockedUpdate(globalUpdates, update)
	
	local DataService = Knit.GetService('DataService')
	
	local id = update[1]
	local data = update[2]
	
	--[[
	
	@@Expected data format
	
	data = {
		
		updateType = string,
		sender = userId,
		target = userId,
		sendTime = os.time()
		metadata = {
			any  = any
		}
	}
	
	]]--
	
	if self[data.updateType] ~= nil then
		self[data.updateType](self, update, DataService)
	end
	
	globalUpdates:ClearLockedUpdate(id)
	
end

function GlobalUpdates:Gold(update, DataService)
	
	local id = update[1]
	local data = update[2]
	
	DataService:IncrementDataValueInPath(game:GetService('Players'):GetPlayerByUserId(data.target), 'Gold', data.metadata.gold)
	
	--[[
	
	@@Expected data format
	
	DataService:SendGlobalUpdateToPlayer(data.sender, {

		updateType = 'Gold',
		sender = userID,
		target = userID,
		sendTime = os.time(),
		metadata = {
			Gold = amount
		}

	})
	
	]]--
	
end

local giftCheckFunction = {}
for i, j in script:WaitForChild('GiftsCheck'):GetChildren() do
	giftCheckFunction[j.Name] = require(j)
end
	
function GlobalUpdates:GiftCheck(targetId, updateType, metadata, DataService)
	
	--@@ returns a promise that resolve as true if the checkPass and with false if it doesnt
	return Promise.new(function(resolve, reject)
		resolve(giftCheckFunction[updateType](targetId, updateType, metadata, DataService))
	end)
		
	
end

return GlobalUpdates
