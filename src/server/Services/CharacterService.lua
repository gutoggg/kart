--//Roblox Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")

--//Constants
local PACKAGE_FOLDER = ReplicatedStorage:WaitForChild('src'):WaitForChild('packages')
local CLASSES_FOLDER = ReplicatedStorage:WaitForChild("src"):WaitForChild('classes')

--//Placeholders
local TeleportService

--//Knit
local Knit = require(PACKAGE_FOLDER:WaitForChild("knit"))

--//Modules
local SteppedConnection = require(CLASSES_FOLDER:WaitForChild('SteppedConnection'))

local CharacterService = Knit.CreateService {
	Name = "CharacterService",
	Client = {
	}
}

function CharacterService:KnitInit()
    Players.CharacterAutoLoads = false

    Players.PlayerAdded:Connect(function(playerAdded : Player)
        self:OnPlayerAdded(playerAdded)
    end)
end

function CharacterService:KnitStart()
    TeleportService = Knit.GetService("TeleportService")
end

function CharacterService:OnPlayerAdded(player : Player)
    self:LoadPlayerCharacter(player)
    TeleportService:TeleportPlayerListToLooby({player})
end

function CharacterService:LoadPlayerCharacter(player : Player)
    player:LoadCharacter()
end

return CharacterService