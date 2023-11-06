-- Date: 2021/06/27
-- Author: gutoggg
-- Title: Car class

--//Roblox Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Constants
local PACKAGE_FOLDER = ReplicatedStorage:WaitForChild('src'):WaitForChild('packages')

--//Dependencies
local Wheel = require(script.Parent.Wheel)
local Janitor = require(PACKAGE_FOLDER:WaitForChild("janitor"))

local Car = {}
Car.__index = Car

function Car.new(chassis : Part)
    local self = setmetatable({}, Car)

    self.Janitor = Janitor.new()
    self.Chassis = chassis

    self.Janitor:Add(self.Chassis, "AncestryChanged", function()
        if not self.Chassis:IsDescendantOf(workspace) then
            self:Destroy()
        end
    end)

    return self
end

function Car:Init()
    self:SetupWheels()
end

function Car:Start()
    local update = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)

    self.Janitor:Add(update, "Disconnect")
end

function Car:Update(dt)
    for i, wheel in self.Wheels do
        wheel:Update(dt)
    end
end

function Car:SetupWheels()
    self.Wheels = {
        FR = Wheel.new(self.Chassis:WaitForChild("FR"), self), -- Front Right
        FL = Wheel.new(self.Chassis:WaitForChild("FL"), self), -- Front Left
        BR = Wheel.new(self.Chassis:WaitForChild("BR"), self), -- Back Right
        BL = Wheel.new(self.Chassis:WaitForChild("BL"), self) -- Back Left
    }

    for i, wheel in self.Wheels do
        self.Janitor:Add(wheel, "Destroy")
    end
    
end

function Car:GetWheels()
    return self.Wheels
end

function Car:GetWheel(wheelName : string)
    return self.Wheels[wheelName]
end

function Car:GetChassis()
    return self.Chassis
end

function Car:Destroy()
    self.Janitor:Destroy()
end

return Car
