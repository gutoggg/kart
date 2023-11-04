--//Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Constants
local SRC_FOLDER = ServerScriptService:WaitForChild("src")
local SERVICES_FOLDER = SRC_FOLDER:WaitForChild("services")
local CLASSES_FOLDER = SRC_FOLDER:WaitForChild("classes")
local PACKAGE_FOLDER = ReplicatedStorage:WaitForChild('src'):WaitForChild('packages')

--//Knit
local Knit = require(PACKAGE_FOLDER:WaitForChild("knit"))

--//Dependencies
local Signal = require(PACKAGE_FOLDER:WaitForChild('signal'))
local Promise = require(PACKAGE_FOLDER:WaitForChild('promise'))
local ProfileService = require(PACKAGE_FOLDER:WaitForChild("profileservice"))
local Table = require(PACKAGE_FOLDER:WaitForChild("tableutil"))
local ProfileTemplate = require(script.DataTemplate)
local GlobalUpdateHandler = require(script.GlobalUpdateHandler)
local Profiles = {}
local profileConnections = {}
local onDataChange = Signal.new()

--//PLACEHOLDERS
local sh

local DATABASE_NAME = "TestDB72"

local DataService = Knit.CreateService {

	Name = "DataService",
	Client = {

	}
}

function DataService:KnitInit()

	DataService.ProfileStore = ProfileService.GetProfileStore(
		DATABASE_NAME,
		ProfileTemplate
	)

	game:GetService('Players').PlayerAdded:Connect(function(player) 
		DataService:_loadPlayerProfile(player)
	end)

	game:GetService('Players').PlayerRemoving:Connect(function(player)
		local profile = Profiles[player]
		if profile ~= nil then
			profile:Release()
		end
	end)

	onDataChange:Connect(function(_player, _path, _state, _key)
		if _state == true then 
			DataService:_createOrUpdateOnReplicatedFolder(_player, _path)
		elseif _state == false then
			DataService:_deleteOnReplicatedFolder(_player, _path, _key)
		end
	end)
end

function DataService:KnitStart()
	local Players = game:GetService('Players')
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function() 
			DataService:_loadPlayerProfile(player)
		end)
	end	
end

function DataService:DataChanged(_player, _path)
	onDataChange:Fire(_player, _path, true)
end

function DataService:ChangeValueOnProfile(_player, _path, _newValue)
	local function ChangeValue(parent, key, value)
		parent[key] = value	
	end
	DataService:_recursiveAction(Profiles[_player].Data, _path, _newValue, ChangeValue)
	onDataChange:Fire(_player, _path, true)
	return Profiles[_player].Data
end

function DataService:GetOfflineProfileFromUserId(userId)
	local key = "Player_"..userId
	return DataService.ProfileStore:ViewProfileAsync(key)
end

function DataService:AppendTableToProfileInPath(_player, _path, _value, _key)
	assert(_player ~= nil, "To create a replicated folder, the argument needs to be a player, got nil")
	assert(typeof(_player) == "Instance", "To create a replicated folder, the argument needs to be a player Instance")
	assert(_player:IsA("Player") , "Argument instance needs to be a 'Player'")
	assert(Profiles[_player], "No profile found with passed player" )

	local function AddTable(parent, key, value)
		assert(type(parent[key]) == "table", "The final of the path value needs to be a table. Got a " .. type(parent[key]) )
		table.insert(parent[key], value)	
	end

	local function AddTableWithKey(parent, key, value)
		assert(type(parent[key]) == "table", "The final of the path value needs to be a table. Got a " .. type(parent[key]) )
		parent[key][_key] = value
	end

	if _key ~= nil then
		assert(type(_key) == "string", "Table key needs to be a string, got " .. type(_key))

		DataService:_recursiveAction(Profiles[_player].Data, _path, _value, AddTableWithKey)
	else
		DataService:_recursiveAction(Profiles[_player].Data, _path, _value, AddTable)

	end

	onDataChange:Fire(_player, _path, true)
	return Profiles[_player].Data
end

function DataService:IncrementDataValueInPath(_player, _path, _value)
	assert(type(_path) == "string", "Path needs to be a string")
	assert(_value ~= nil, "Value needs to be different of nil")
	assert(type(_value) == "number", "Value needs to be a number")

	if Profiles[_player] == nil then
		return
	end

	local Folder, Attribute = DataService:_navigateOnReplicatedDataFolder(_player, _path)
	local function Increment(parent, key, value)
		assert(type(parent[key]) == "number", "Data value needs to be a number")
		parent[key] += value
	end
	DataService:_recursiveAction(Profiles[_player].Data, _path, _value, Increment)
	onDataChange:Fire(_player, _path, true)
	return Profiles[_player].Data
end

function DataService:DeleteDataValueInPath(_player, _path)
	local function Delete(parent, key, value)
		if string.match(key, '[0-9]+') ~= nil and string.len(string.match(key, '[0-9]+')) == string.len(key) then
			table.remove(parent, key)
		elseif type(key) == "string" then
			parent[key] = nil
		end 
		onDataChange:Fire(_player, _path, false, key)
	end
	DataService:_recursiveAction(Profiles[_player].Data, _path, nil, Delete)

	return Profiles[_player].Data
end

function DataService:GetPlayerData(_player)
	if Profiles[_player] ~= nil then
		return Table.Copy(Profiles[_player].Data)
	end
end

function DataService:GetPlayerDataAsync(player)
	assert(player, "Player object expect, got nil")
	assert(player:IsA("Player"), "Player object expected, got " .. type(player))

	return Promise.new(function(resolve, reject)
		task.spawn(function()
			local trys = 0
			local maxTrys = 100
			while trys < maxTrys do
				if Profiles[player] ~= nil then
					resolve(Table.Copy(Profiles[player].Data)) 
				end
				trys+=1
				wait(1)
			end
			reject("No profile found")
		end)
	end)
end

function DataService:GetPlayerProfileAsync(player)
	return Profiles[player]
end

function DataService:SendGlobalUpdateToPlayer(playerId, data)

	assert(playerId, 'Player id is needed to sent the global update')

	local playerProfileKey = 'Player_' .. playerId

	DataService.ProfileStore:GlobalUpdateProfileAsync(
		playerProfileKey, 
		function(globalUpdates)
			globalUpdates:AddActiveUpdate(data)
		end
	)
end

--[[
### INTERNAL METHODS
--]]

function DataService:_getDataFromPath(datastructure, path)

	if typeof(path) == "string" then
		path = DataService:_stringToArray(path)
	end
	local function travel(parent, subpath)
		local key = subpath[1]
		if tonumber(key) and #subpath > 1 then 
			key = tonumber(key) 
		end
		if #subpath == 1 then
			return parent[key]

		else
			table.remove(subpath, 1)
			if parent[key] ~= nil then
				return travel(parent[key], subpath)
			else
				return
			end
		end
	end

	return travel(datastructure, path)
end


function DataService:_createOrUpdateOnReplicatedFolder(_player, _path)
	local function SetFolderData(_data, _folder)
		for i, j in pairs(_data) do
			if type(j) ~= "table" then
				_folder:SetAttribute(i, j)
			else
				if not _folder:FindFirstChild(i) then
					local newFolder = Instance.new("Folder")
					newFolder.Name = i
					newFolder.Parent = _folder
				end
				SetFolderData(j, _folder[i])
			end 
		end
	end
	
	local Folder, AttributeName = DataService:_navigateOnReplicatedDataFolder(_player, _path)
	local data = DataService:_getDataFromPath(Profiles[_player].Data, _path)

	if AttributeName then
		Folder:SetAttribute(AttributeName, data)
	else
		SetFolderData(data, Folder)
	end
end

function DataService:_renderReplicatedFolder(player)
	assert(player ~= nil, "To create a replicated folder, the argument needs to be a player, got nil")
	assert(typeof(player) == "Instance", "To create a replicated folder, the argument needs to be a player Instance")
	assert(player:IsA("Player") , "Argument instance needs to be a 'Player'")
	assert(Profiles[player], "No profile found with passed player" )

	local ReplicationFolder = Instance.new("Folder")
	ReplicationFolder.Name = "_replicationFolder"
	local function mapArray(array, folder)
		for i, j in pairs(array) do
			if type(j) == "table" then
				local newFolder = Instance.new("Folder")
				newFolder.Name = i
				newFolder.Parent = folder
				mapArray(j, newFolder)
			else
				folder:SetAttribute(i, j)				
			end
		end
	end
	mapArray(Profiles[player].Data, ReplicationFolder)
	if player:FindFirstChild("_replicationFolder") ~= nil then
		player["_replicationFolder"]:Destroy()
	end
	ReplicationFolder.Parent = player
end

function DataService:_navigateOnReplicatedDataFolder(player, path)
	local Steps = string.split(path, ".")
	local ActualStep = player:FindFirstChild("_replicationFolder")
	local function TestIfExistFolder(_parent, _seekedName)
		local folder = _parent:FindFirstChild(_seekedName)
		if folder then
			return folder
		else
			return 'false'
		end
	end
	if ActualStep then

		for i, j in pairs(Steps) do

			if i == #Steps then
				local attributeTest = ActualStep:GetAttribute(j)
				if attributeTest ~= nil then
					return ActualStep, j
				else
					local result = TestIfExistFolder(ActualStep, j)
					if result ~= 'false' then
						ActualStep = result
					end
				end
			else
				local result = TestIfExistFolder(ActualStep, j)
				if result ~= 'false' then
					ActualStep = result
				end
			end
		end
	end

	return ActualStep, nil
end

function DataService:_lockPlayerActiveGlobalUpdates(player)

	local playerProfile = Profiles[player]

	assert(playerProfile, 'No player profile found')

	local globalUpdates = playerProfile.GlobalUpdates

	for index, update in globalUpdates:GetActiveUpdates() do
		globalUpdates:LockActiveUpdate(update[1])
	end

	for index, lockedUpdate in globalUpdates:GetLockedUpdates() do
		self:_handleLockedUpdate(globalUpdates, lockedUpdate)
	end

end

function DataService:_handleLockedUpdate(globalUpdates, update)

	local id = update[1]
	local data = update[2]

	GlobalUpdateHandler:HandleLockedUpdate(globalUpdates, update)

end

function DataService:_loadPlayerProfile(player)
	local profile = DataService.ProfileStore:LoadProfileAsync("Player_" .. player.UserId)

	if profile ~= nil then
		profile:AddUserId(player.UserId) 
		profile:Reconcile() 

		local connection = profile:ListenToRelease(function()
			profileConnections[player]:Disconnect()
			Profiles[player] = nil
			player:Kick()
		end)

		profileConnections[player] = connection

		if player:IsDescendantOf(game:GetService('Players')) == true then
			Profiles[player] = profile

			DataService:_renderReplicatedFolder(player)
			DataService:IncrementDataValueInPath(player, "Stats.SessionsPlayed", 1)

			local globalUpdates = profile.GlobalUpdates

			self:_lockPlayerActiveGlobalUpdates(player)

			globalUpdates:ListenToNewActiveUpdate(function(id, data)
				globalUpdates:LockActiveUpdate(id)
			end)

			globalUpdates:ListenToNewLockedUpdate(function(id, data)
				self:_handleLockedUpdate(globalUpdates, {id, data})
			end)

			player:SetAttribute("DataLoaded", true)

			return player, profile
		else
			profile:Release()
		end
	else
		player:Kick() 
	end
end

function DataService:_stringToArray(str)
	local arr = {}
	for s in string.gmatch(str, "[^.]+") do arr[#arr+1] = s end
	return arr
end

function DataService:_arrayToString(arr)
	return table.concat(arr, ".")
end

function DataService:_recursiveAction(datastructure, path, value, action)
	if typeof(path) == "string" then
		path = DataService:_stringToArray(path)
	end
	local function travel(parent, subpath)
		local key = subpath[1]
		if tonumber(key) and #subpath > 1 then 
			key = tonumber(key) 
		end 
		if #subpath == 1 then
			action(parent, key, value)
		else
			table.remove(subpath, 1)		
			if parent[key] ~= nil then
				travel(parent[key], subpath)
			end

			return
		end
	end
	return travel(datastructure, path)
end

function DataService:GetReleasePlayerProfilePromise(player : Player)

	return Promise.new(function(resolve, reject) 
		local playerProfile = Profiles[player]

		if playerProfile == nil then
			warn('No player profile found')
			return reject()
		end
		profileConnections[player]:Disconnect()
		playerProfile:Release()
		local success, errmsg
		playerProfile:ListenToHopReady(function()
			resolve()
		end)
	end)

end

function DataService:_deleteOnReplicatedFolder(_player, _path, key)

	local Folder, AttributeName = DataService:_navigateOnReplicatedDataFolder(_player, _path)
	local folderParent = Folder.Parent

	if AttributeName then
		Folder:SetAttribute(AttributeName, nil)
	elseif string.match(key, '[0-9]+') ~= nil and string.len(string.match(key, '[0-9]+')) == string.len(key) then
		folderParent[key]:Destroy()
		for i = tonumber(key) + 1, #folderParent:GetChildren() + 1 , 1 do
			folderParent[i].Name = 	i - 1			
		end
	else
		folderParent[key]:Destroy()
	end

end

return DataService