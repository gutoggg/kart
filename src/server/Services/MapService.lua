--//Roblox Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")
local ServerScriptService = game:GetService('ServerScriptService')

--//Constants
local SHARED_SRC_FOLDER = ReplicatedStorage:WaitForChild('src')
local SERVER_SRC_FOLDER = ServerScriptService:WaitForChild('src')
local PACKAGE_FOLDER = SHARED_SRC_FOLDER:WaitForChild('packages')
local CLASSES_FOLDER = SERVER_SRC_FOLDER:WaitForChild('classes')
local METADATA_FOLDER = SERVER_SRC_FOLDER:WaitForChild("metadata")

--//Placeholders
local MapService

--//Knit
local Knit = require(PACKAGE_FOLDER:WaitForChild("knit"))

--//Dependencies
local MapsMetadata = require(METADATA_FOLDER:WaitForChild("MapsMetadata"))

local MapsFolder = game:GetService("ReplicatedStorage"):WaitForChild("assets"):WaitForChild("MapsFolder")

local MapService = Knit.CreateService {
	Name = "MapService",
	Client = {
	}
}

local mapQuantity = #MapsMetadata.Maps
local Lobby = workspace:WaitForChild("GameAssets"):WaitForChild("Lobby")
local Map = nil

function MapService:KnitInit()

end

function MapService:KnitStart()

end

function MapService:LoadRandomMap()
    local choosenMap = mapQuantity > 1 and math.random(1, #MapsMetadata.Maps) or 1
    self:LoadMap(MapsMetadata.Maps[choosenMap].Id)
end

function MapService:LoadMap(mapId : string)
    self:UnloadMap()
    local newMapInstance = MapsFolder:WaitForChild(mapId):Clone()
    newMapInstance.Parent = workspace:WaitForChild("Map")
    Map = newMapInstance
end

function MapService:UnloadMap()
    if Map then
        Map:Destroy()
    end
end

function MapService:GetCurrentMap()
    return Map
end

function MapService:GetLobby()
    return Lobby
end

function MapService:GetCurrentMapSpawnsList()
    return Map:WaitForChild("Spawns"):GetChildren()
end

function MapService:GetLobbySpawnsList()
    return Lobby:WaitForChild("Spawns"):GetChildren()
end

return MapService