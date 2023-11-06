-- Author: gutoggg
-- Title: Car class

--//Roblox Services
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Constants
local PACKAGE_FOLDER = ReplicatedStorage:WaitForChild('src'):WaitForChild('packages')

--//Dependencies
local Janitor = require(PACKAGE_FOLDER:WaitForChild("janitor"))

local Wheel = {}
Wheel.__index = Wheel

function Wheel.new(suspensionPoint : Attachment,  car )
    local self = setmetatable({}, Wheel) 
    self.Janitor = Janitor.new()
    self.Car = car
    self.Attachment = suspensionPoint

	self.WheelModel = ReplicatedStorage.assets:WaitForChild("WheelModel"):Clone()
	self.WheelModel.Parent = self.Car.Chassis
	
    self.Config = {
        MaxLength = 3,
        RestDistance = 2.7,
        Strength = 35,
        Damping = 0.5
    }

    self.Stats = {
        Offset = 0,
        Velocity = 0
    }

    print("Creating Wheel" .. self.Attachment.Name)
    return self

end

function Wheel:Update(dt)
    self:CastRay()
    self:CalculateSpringOffset()
	self:CalculateInstantVelocity(dt)
	self:PositioningWheel()
	self:ApplyForces()
end

function Wheel:ApplyForces()
    if self.RayResult then
		self:CalculateSpringForce()
		local springForce =  Vector3.new(0,self.Stats.SpringForce,0)
		self.Car.Chassis:SetAttribute(self.Attachment.Name .. "Force", springForce)
        self.Car.Chassis:ApplyImpulseAtPosition(springForce, self.Attachment.WorldPosition)
    end
end

function Wheel:PositioningWheel()
    local suspencionCFrame = self.Attachment.WorldCFrame
    local wheelRadius = self.WheelModel.Size.Y/2
	if self.RayResult then
		local position = self.RayResult.Position
        local normal = self.RayResult.Normal

        local newWheelCFrame = CFrame.new(position + wheelRadius * normal, position + wheelRadius * normal + suspencionCFrame.RightVector )
		self.WheelModel.CFrame = newWheelCFrame
    else
        self.WheelModel.Position = (suspencionCFrame.Position + -suspencionCFrame.UpVector * self.Config.MaxLength) + Vector3.new(0, wheelRadius, 0)
	end
end

function Wheel:CastRay()
    local rayResult = workspace:Raycast(self.Attachment.WorldPosition, -self.Attachment.WorldCFrame.UpVector * self.Config.MaxLength, RaycastParams.new({
        FilterDescendantsInstances = {self.Car.Chassis, self.WheelModel},
        FilterType = Enum.RaycastFilterType.Exclude
    }))
	
	self.RayResult = rayResult
end

function Wheel:CalculateSpringForce()
    local offset = self.Stats.Offset
    local velocity = self.Stats.Velocity
    local strength = self.Config.Strength
    local damping = self.Config.Damping
    local dampeningForce = (damping * velocity)
	local springForce = (offset * strength)
    self.Stats.SpringForce = springForce - dampeningForce
end

function Wheel:CalculateSpringOffset()
    local hitDistance

	if self.RayResult == nil then
       hitDistance = self.Config.MaxLength
    else
		hitDistance = self.RayResult.Distance
    end
    local offset =  self.Config.RestDistance - hitDistance
    self.Stats.Offset = offset
end

function Wheel:CalculateInstantVelocity()
    local chassis : Part = self.Car.Chassis
    local wheelVel = chassis:GetVelocityAtPosition(self.Attachment.WorldPosition)
    local vel  = 0
    if self.RayResult then
        vel = self.RayResult.Normal:Dot(wheelVel)
    end
    self.Stats.Velocity = vel
end

function Wheel:Destroy()
    self.Janitor:Destroy()
end

return Wheel
