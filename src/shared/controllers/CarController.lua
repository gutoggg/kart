--//Roblox Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--//Constants
local PACKAGE_FOLDER = ReplicatedStorage:WaitForChild('src'):WaitForChild('packages')
local CLASSES_FOLDER = ReplicatedStorage:WaitForChild("src"):WaitForChild('classes')

--//Placeholders

--//Knit
local Knit = require(PACKAGE_FOLDER:WaitForChild("knit"))

--Dependencies
local Car = require(CLASSES_FOLDER:WaitForChild("Car"))

--//Controller
local CarController = Knit.CreateController {
    Name = "CarController"
}

function CarController:KnitInit()

end

function CarController:KnitStart()
    local newChassis = ReplicatedStorage:WaitForChild("assets"):WaitForChild("Car"):Clone()
    
    newChassis.Parent = workspace
    task.wait(2)
    newChassis.Position = Vector3.new(-15.94, 5.444, 19.644)
    local newCar = Car.new(newChassis)
    newCar:Init()
    newCar:Start()
end

return CarController