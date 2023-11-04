--//Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Constants
local PACKAGE_FOLDER = ReplicatedStorage:WaitForChild('src'):WaitForChild('packages')

--//Knit
local Knit = require(PACKAGE_FOLDER:WaitForChild("knit"))

--//Setup
Players.CharacterAutoLoads = false

local Game = {}
Game.__index = Game

function Game.new()
    local self = setmetatable({}, Game)
    return self
end

function Game:Start()

    

end

function Game:Pause()

end



return Game