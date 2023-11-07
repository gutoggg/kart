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
        Damping = 0.5,
        Grip = .01,
        MaxSpeed = 30 --studs per second
        }

    self.Stats = {
        Offset = 0,
        SuspensionVelocity = 0,
        AccelInput = 0
    }

    print("Creating Wheel" .. self.Attachment.Name)
    return self

end

function Wheel:Update(dt)
    self:CastRay()
    self:CalculateSpringOffset()
	self:CalculateSuspensionVelocity(dt)
	self:PositioningWheel()
    self:CalculateSteeringForce(dt)
    self:CalculateEngineForce(dt)
	self:ApplyForces()
end

function Wheel:EvaluateCurve(x)
    if x >= 0 and x < 0.4 then
        return x ^ 2 
    elseif x >= 0.4 and x < 0.65 then
        return x ^ 1.5
    else 
        return (1 - x) ^ 2
    end
end

function Wheel:CalculateEngineForce(dt)
    local engineDirection = self.Attachment.WorldCFrame.LookVector
    local carVelocity = self.Car.Chassis:GetVelocity(self.Car.Chassis)
    local carSpeed = engineDirection:Dot(carVelocity)
    local normalizedSpeed = math.clamp(math.abs(carSpeed)/self.Config.MaxSpeed, 0, 1)
    local availableTorque =  (self:EvaluateCurve(normalizedSpeed) * self.Stats.AccelInput ) + 0.001
    self.Stats.EngineForce = engineDirection * availableTorque
end

function Wheel:CalculateSteeringForce(dt)
    local steeringDirection = self.Attachment.WorldCFrame.RightVector
    local tireWorldVel = self.Car.Chassis:GetVelocityAtPosition(self.Attachment.WorldPosition)
    local steeringVel = tireWorldVel:Dot(steeringDirection)
    local desiredVelChange = -steeringVel * self.Config.Grip
    local desiredAccel = desiredVelChange / dt
    self.Stats.SteeringForce = steeringDirection * self.WheelModel.Mass * desiredAccel
end

function Wheel:ApplyForces()
    if self.RayResult then
		self:CalculateSpringForce()
		local springForce =  Vector3.new(0,self.Stats.SpringForce,0)
        local steeringForce = self.Stats.SteeringForce
        local engineForce = self.Stats.EngineForce
        local totalForce = springForce + steeringForce + engineForce
        self.Car.Chassis:ApplyImpulseAtPosition(totalForce, self.Attachment.WorldPosition)
    end
end

function Wheel:PositioningWheel()
    local suspencionCFrame = self.Attachment.WorldCFrame
    local wheelRadius = self.WheelModel.Size.Y/2
	if self.RayResult then
		local position = self.RayResult.Position
        local normal = self.RayResult.Normal

        local newWheelCFrame = CFrame.new(position + wheelRadius * normal, position + wheelRadius * normal + suspencionCFrame.LookVector )
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
    local velocity = self.Stats.SuspensionVelocity
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

function Wheel:CalculateSuspensionVelocity()
    local chassis : Part = self.Car.Chassis
    local wheelVel = chassis:GetVelocityAtPosition(self.Attachment.WorldPosition)
    local vel  = 0
    if self.RayResult then
        vel = self.RayResult.Normal:Dot(wheelVel)
    end
    self.Stats.SuspensionVelocity = vel
end

function Wheel:Destroy()
    self.Janitor:Destroy()
end

return Wheel
