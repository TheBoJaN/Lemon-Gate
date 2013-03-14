/*==============================================================================================
	Expression Advanced: Entity's.
	Purpose: Entity's are stuffs.
	Creditors: Rusketh
==============================================================================================*/
local E_A = LemonGate

local GetLongType = E_A.GetLongType

local Abs = math.abs
local Atan2 = math.atan2
local Sqrt = math.sqrt
local Asin = math.asin
local Clamp = math.Clamp

local Round = 0.0000001000000
local Rad2Deg = 180 / math.pi
local NULL_ENTITY = Entity(-1)

/*==============================================================================================
	Class & WireMod
==============================================================================================*/
E_A:SetCost(EA_COST_CHEAP)

E_A:RegisterClass("entity", "e", function() return NULL_ENTITY end)

E_A:RegisterOperator("assign", "e", "", E_A.AssignOperator)
E_A:RegisterOperator("variable", "e", "e", E_A.VariableOperator)
E_A:RegisterOperator("trigger", "e", "n", E_A.TriggerOperator)

local function Input(self, Memory, Value)
	self.Memory[Memory] = Value
end

local function Output(self, Memory)
	return self.Memory[Memory]
end

E_A:WireModClass("entity", "ENTITY", Input, Output)

/*==============================================================================================
	Section: Comparison Operators
==============================================================================================*/
E_A:SetCost(EA_COST_NORMAL)

E_A:RegisterOperator("negeq", "ee", "n", function(self, ValueA, ValueB)
	return (ValueA(self) == ValueB(self)) and 0 or 1
end)

E_A:RegisterOperator("eq", "ee", "n", function(self, ValueA, ValueB)
	return (ValueA(self) == ValueB(self)) and 1 or 0
end)

/*==============================================================================================
	Section: Conditional Operators
==============================================================================================*/
E_A:SetCost(EA_COST_NORMAL)

E_A:RegisterOperator("is", "e", "n", function(self, Value)
	local Entity = Value(self)
	return (Entity and Entity:IsValid()) and 1 or 0
end)

E_A:RegisterOperator("not", "e", "n", function(self, Value)
	local Entity = Value(self)
	return (Entity and Entity:IsValid()) and 0 or 1
end)

E_A:RegisterOperator("or", "ee", "e", function(self, ValueA, ValueB)
	local Entity = ValueA(self)
	return (Entity and Entity:IsValid()) and Entity or ValueB(self)
end)

E_A:RegisterOperator("and", "ee", "n", function(self, ValueA, ValueB)
	local A, B = ValueA(self), ValueB(self)
	return (A and B and A:IsValid() and B:IsValid()) and 1 or 0
end)

/*==============================================================================================
	Section: Casting and converting
==============================================================================================*/
local tostring = tostring

E_A:RegisterFunction("toString", "e", "s", function(self, Value)
	return tostring( Value(self) )
end)

E_A:RegisterOperator("cast", "se", "s", function(self, Value, ConvertType)
	return tostring( Value(self) )
end)

/*==============================================================================================
	Section: Get Entity
==============================================================================================*/
E_A:RegisterFunction("entity", "n", "e", function(self, Value)
	local V = Value(self)
	return Entity(V)
end)

E_A:RegisterFunction("voidEntity", "", "e", function(self)
	return Entity(-1)
end)

/*==============================================================================================
	Section: Entity is something
==============================================================================================*/
E_A:RegisterFunction("isNPC", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() and Entity:IsNPC() then return 1 end
	return 0
end)

E_A:RegisterFunction("isWorld", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() and Entity:IsWorld() then return 1 end
	return 0
end)

E_A:RegisterFunction("isOnGround", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() and Entity:IsOnGround() then return 1 end
	return 0
end)

E_A:RegisterFunction("isUnderWater", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() and Entity:WaterLevel() > 0 then return 1 end
	return 0
end)

E_A:RegisterFunction("isValid", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() then return 1 end
	return 0
end)

E_A:RegisterFunction("isPlayerHolding", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() and Entity:IsPlayerHolding() then return 1 end
	return 0
end)

E_A:RegisterFunction("isOnFire", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() and Entity:IsOnFire() then return 1 end
	return 0
end)

E_A:RegisterFunction("isWeapon", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() and Entity:IsWeapon() then return 1 end
	return 0
end)

E_A:RegisterFunction("isFrozen", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return 0 end
	
	local Phys = Entity:GetPhysicsObject()
	if !Phys or !Phys:IsValid() or !Phys:IsMoveable() then return 0 end
	return 1
end)

E_A:RegisterFunction("owner", "e:", "e", function(self, Value)
	local Ent = Value(self)
	if !Ent or !Ent:IsValid() then return Entity(-1) end
	return E_A.GetOwner( Ent ) or Entity(-1)
end)

/*==============================================================================================
	Section: Entity Info
==============================================================================================*/
E_A:RegisterFunction("class", "e:", "s", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return "" end
	
	return Entity:GetClass()
end)

E_A:RegisterFunction("model", "e:", "s", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return "" end
	
	return Entity:GetModel()
end)

E_A:RegisterFunction("name", "e:", "s", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return "" end
	
	return Entity:GetName() or Entity:Name()
end)

E_A:RegisterFunction("health", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return 0 end
	
	return Entity:Health()
end)

E_A:RegisterFunction("radius", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return 0 end
	
	return Entity:BoundingRadius()
end)

/*==============================================================================================
	Section: Vehicle Stuff
==============================================================================================*/
E_A:RegisterFunction("isVehicle", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() and Entity:IsVehicle() then return 1 end
	return 0
end)

E_A:RegisterFunction("driver", "e:", "e", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() and Entity:IsVehicle() then return Entity:GetDriver() end
	return NULL_ENTITY
end)

E_A:RegisterFunction("passenger", "e:", "e", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() and Entity:IsVehicle() then return Entity:GetPassenger() end
	return NULL_ENTITY
end)

/*==============================================================================================
	Section: Mass
==============================================================================================*/
E_A:SetCost(EA_COST_ABNORMAL)

E_A:RegisterFunction("mass", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return 0 end
	
	local Phys = Entity:GetPhysicsObject()
	if !Phys or !Phys:IsValid() then return 0 end
	
	return Phys:GetMass()
end)

E_A:RegisterFunction("massCenterWorld", "e:", "v", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	local Phys = Entity:GetPhysicsObject()
	if !Phys or !Phys:IsValid() then return {0, 0, 0} end
	
	local V = E:LocalToWorld(Phys:GetMassCenter())
	return {V.x, V.y, V.z}
end)

E_A:RegisterFunction("massCenter", "e:", "v", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	local Phys = Entity:GetPhysicsObject()
	if !Phys or !Phys:IsValid() then return {0, 0, 0} end
	
	local V = Phys:GetMassCenter()
	return {V.x, V.y, V.z}
end)

/*==============================================================================================
	Section: OBB Box
==============================================================================================*/
E_A:RegisterFunction("boxSize", "e:", "v", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	local V = Entity:OBBMaxs() - Entity:OBBMins()
	return {V.x, V.y, V.z}
end)

E_A:RegisterFunction("boxCenter", "e:", "v", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	local V = Entity:OBBCenter()
	return {V.x, V.y, V.z}
end)

E_A:RegisterFunction("boxCenterWorld", "e:", "v", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	local V = Entity:LocalToWorld(Entity:OBBCenter())
	return {V.x, V.y, V.z}
end)

E_A:RegisterFunction("boxMax", "e:", "v", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	local V = Entity:OBBMaxs()
	return {V.x, V.y, V.z}
end)

E_A:RegisterFunction("boxMin", "e:", "v", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	local V = Entity:OBBMins()
	return {V.x, V.y, V.z}
end)

/******************************************************************************/

E_A:RegisterFunction("aabbMin", "e:", "v", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	local Phys = Entity:GetPhysicsObject()
	if !Phys or !Phys:IsValid() then return {0, 0, 0} end
	
	local V = Phys:GetAABB()
	return {V.x, V.y, V.z}
end)

E_A:RegisterFunction("aabbMax", "e:", "v", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	local Phys = Entity:GetPhysicsObject()
	if !Phys or !Phys:IsValid() then return {0, 0, 0} end
	
	local _, V Phys:GetAABB()
	return {V.x, V.y, V.z}
end)

/*==============================================================================================
	Section: Force
==============================================================================================*/
E_A:SetCost(EA_COST_EXPENSIVE)

E_A:RegisterFunction("applyForce", "e:v", "", function(self, ValueA, ValueB)
	local Entity, V = ValueA(self), ValueB(self)
	
	if !Entity or !Entity:IsValid() then return end
	
	if !E_A.IsOwner(self.Player, Entity) then return  end
	
	local Phys = Entity:GetPhysicsObject()
	
	if Phys and Phys:IsValid() then
		Phys:ApplyForceCenter(Vector(V[1], V[2], V[3]))
	end
end)

E_A:RegisterFunction("applyOffsetForce", "e:vv", "", function(self, ValueA, ValueB, ValueC)
	local Entity, B, C = ValueA(self), ValueB(self), ValueC(self)
	if !Entity or !Entity:IsValid() then return end
	if !E_A.IsOwner(self.Player, Entity) then return end
	
	local Phys = Entity:GetPhysicsObject()
	
	if Phys and Phys:IsValid() then
		Phys:ApplyForceOffset(Vector(B[1], B[2], B[3]), Vector(C[1], C[2], C[3]))
	end
end)

E_A:RegisterFunction("applyAngForce", "e:a", "", function(self, ValueA, ValueB)
	local Entity, A = ValueA(self), ValueB(self)
	if !Entity or !Entity:IsValid() then return end
	if !E_A.IsOwner(self.Player, Entity) then return end
	
	local Phys = Entity:GetPhysicsObject()
	
	if Phys and Phys:IsValid() then
	
		-- assign vectors
		local Up = Entity:GetUp()
		local Left = Entity:GetRight() * -1
		local Forward = Entity:GetForward()

		-- apply pitch force
		if A[1] ~= 0 and A[1] < math.huge then
			local Pitch = Up * (A[1] * 0.5)
			Phys:ApplyForceOffset( Forward, Pitch )
			Phys:ApplyForceOffset( Forward * -1, Pitch * -1 )
		end

		-- apply yaw force
		if A[2] ~= 0 and A[2] < math.huge then
			local Yaw = Forward * (A[2] * 0.5)
			Phys:ApplyForceOffset( Left, Yaw )
			Phys:ApplyForceOffset( Left * -1, Yaw * -1 )
		end

		-- apply roll force
		if A[3] ~= 0 and A[3] < math.huge then
			local Roll = Left * (A[3] * 0.5)
			Phys:ApplyForceOffset( Up, Roll )
			Phys:ApplyForceOffset( Up * -1, Roll * -1 )
		end
	end
end)

E_A:RegisterFunction("vel", "e:", "v", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	local Phys = Entity:GetPhysicsObject()
	
	if Phys and Phys:IsValid() then return Entity:GetVelocity() end
	return {0, 0, 0}
end)

E_A:RegisterFunction("angVel", "e:", "A", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	if Phys and Phys:IsValid() then return Entity:GetAngleVelocity() end
	return {0, 0, 0}
end)

/*==============================================================================================
	Section: Vectors
==============================================================================================*/
E_A:SetCost(EA_COST_NORMAL)

E_A:RegisterFunction("pos", "e:", "v", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	local Pos = Entity:GetPos()
	
	return {Pos.x, Pos.y, Pos.z}
end)

/*==============================================================================================
	Section: Angles
==============================================================================================*/
E_A:RegisterFunction("ang", "e:", "a", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return {0, 0, 0} end
	
	local Ang = Entity:GetAngles()
	
	return {Ang.p, Ang.y, Ang.r}
end)

/*==============================================================================================
	Section: Constraints
==============================================================================================*/
E_A:SetCost(EA_COST_NORMAL)

local constraint = constraint
local HasConstraints = constraint.HasConstraints
local GetAllConstrainedEntities = constraint.GetAllConstrainedEntities
local ConstraintTable = constraint.GetTable
local FindConstraint = constraint.FindConstraint

E_A:RegisterFunction("hasConstraints", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() then return 0 end
	
	return #ConstraintTable(Entity)
end)

E_A:RegisterFunction("isConstrained", "e:", "n", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() or !HasConstraints(Entity) then return 0 end
	
	return 1
end)

E_A:RegisterFunction("isWeldedTo", "e:", "e", function(self, Value)
	local Entity = Value(self)
	if !Entity or !Entity:IsValid() or !HasConstraints(Entity) then return NULL_ENTITY end
	
	local Constraint = FindConstraint(Entity, "Weld")
	
	if !Constraint then
		return NULL_ENTITY
	
	elseif Constraint.Ent1 == Entity then
		return Constraint.Ent2
	else
		return Constraint.Ent1 or NULL_ENTITY
	end
end)


E_A:SetCost(EA_COST_EXPENSIVE)

E_A:RegisterFunction("getConstraints", "e:", "t", function(self, Value)
	local Entity, Table = Value(self), E_A.NewTable()
	if !Entity or !Entity:IsValid() or !HasConstraints(Entity) then return Table end
	
	for _, Constraint in pairs( GetAllConstrainedEntities(Entity) ) do
		if Constraint and Constraint:IsValid() and Constraint ~= Entity then
			Table:Insert(nil, "e", Constraint)
		end
	end
	
	return Table
end)

/*==============================================================================================
	Section: Bearing & Elevation
==============================================================================================*/
E_A:SetCost(EA_COST_ABNORMAL)

E_A:RegisterFunction("bearing", "e:v", "n", function(self, ValueA, ValueB)
	local Entity, B = ValueA(self), ValueB(self)
	
	if Entity and Entity:IsValid() then
		local Pos = Entity:WorldToLocal( Vector(B[1], B[2], B[3]) )
		return Rad2Deg * -Atan2(Pos.y, Pos.x)
	end
	
	return 0
end)

E_A:RegisterFunction("elevation", "e:v", "n", function(self, ValueA, ValueB)
	local Entity, B = ValueA(self), ValueB(self)
	
	if Entity and Entity:IsValid() then
		local Pos = Entity:WorldToLocal( Vector(B[1], B[2], B[3]) )
		local Len = Pos:Length()
		if Len > Round then 
			return Rad2Deg * Asin(Pos.z / Len)
		end
	end
	
	return 0
end)

E_A:RegisterFunction("heading", "e:v", "a", function(self, ValueA, ValueB)
	local Entity, B = ValueA(self), ValueB(self)
	
	if Entity and Entity:IsValid() then
		local Pos = Entity:WorldToLocal(Vector(B[1], B[2], B[3]))
		local Bearing = Rad2Deg * -Atan2(Pos.y, Pos.x)
		local Len = Pos:Length()
		
		if Len > Round then
			local Elevation = Rad2Deg * Asin(Pos.z / Len)
			return { Elevation, Bearing, 0 }
		end
		
		return { 0, Bearing, 0 }
	end
	
	return {0, 0, 0}
end)

/*==============================================================================================
	Section: Color & Material
==============================================================================================*/
E_A:RegisterFunction("getColor", "e:", "c", function(self, Value)
	local Entity = Value(self)
	
	if Entity and Entity:IsValid() then
		local C = Entity:GetColor( )
        return { C.r, C.g, C.b, C.a }
	end
	
	return { 0, 0, 0, 0 }
end)

E_A:RegisterFunction("setColor", "e:c", "", function(self, ValueA, ValueB)
	local Entity, B = ValueA(self), ValueB(self)
	
	if Entity and Entity:IsValid() and E_A.IsOwner(self.Player, Entity) then
        Entity:SetColor( Color( B[1], B[2], B[3], B[4] ) )
        Entity:SetRenderMode(B[4] == 255 and RENDERMODE_NORMAL or RENDERMODE_TRANSALPHA)
	end
end)

E_A:RegisterFunction("getMaterial", "e:", "s", function(self, Value)
	local Entity = Value(self)
	if Entity and Entity:IsValid() then
		return Entity:GetMaterial() or ""
	end
	
	return ""
end)

E_A:RegisterFunction("setMaterial", "e:s", "", function(self, ValueA, ValueB)
	local Entity, Material = ValueA(self), ValueB(self)
	if Entity and Entity:IsValid() and E_A.IsOwner(self.Player, Entity) then
		Entity:SetMaterial(Material)
	end
end)

/*==============================================================================================
	Section: Finding
==============================================================================================*/
local Players = player.GetAll
local FindByClass = ents.FindByClass
local FindInSphere = ents.FindInSphere
local FindInBox = ents.FindInBox
local FindInCone = ents.FindInCone
local FindByModel = ents.FindByModel

local BanedEntities = { -- E2 filters these.
	["info_player_allies"] = true,
	["info_player_axis"] = true,
	["info_player_combine"] = true,
	["info_player_counterterrorist"] = true,
	["info_player_deathmatch"] = true,
	["info_player_logo"] = true,
	["info_player_rebel"] = true,
	["info_player_start"] = true,
	["info_player_terrorist"] = true,
	["info_player_blu"] = true,
	["info_player_red"] = true,
	["prop_dynamic"] = true,
	["physgun_beam"] = true,
	["player_manager"] = true,
	["predicted_viewmodel"] = true,
	["gmod_ghost"] = true,
}
	
local function FilterResults(Entities)
	local Table = E_A.NewTable()
	
	for _, Entity in pairs( Entities ) do
		if Entity:IsValid() and !BanedEntities[  Entity:GetClass() ] then
			Table:Insert(nil, "e", Entity)
		end
	end
	
	return Table
end

E_A:SetCost(EA_COST_ABNORMAL)

E_A:RegisterFunction("getPlayers", "", "t", function(self)
	return E_A.NewResultTable(Players(), "e")
end)

E_A:SetCost(EA_COST_EXPENSIVE)

E_A:RegisterFunction("findByClass", "s", "t", function(self, Value)
	V = Value(self)
	Ents = FindByClass(V)
	
	return FilterResults(Ents)
end)

E_A:RegisterFunction("findByModel", "s", "t", function(self, Value)
	V = Value(self)
	Ents = FindByModel(V)
	
	return FilterResults(Ents)
end)

E_A:RegisterFunction("findInSphere", "vn", "t", function(self, ValueA, ValueB)
	local A, B = ValueA(self), ValueB(self)
	local V = Vector(A[1], A[2], A[3])
	
	local Ents = FindInSphere(V, B)
	return FilterResults(Ents)
end)

E_A:RegisterFunction("findInBox", "vv", "t", function(self, ValueA, ValueB)
	local A, B = ValueA(self), ValueB(self)
	local VA, VB = Vector(A[1], A[2], A[3]), Vector(B[1], B[2], B[3])
	
	local Ents = FindInBox(VA, VB)
	return FilterResults(Ents)
end)

E_A:RegisterFunction("findInCone", "vvna", "t", function(self, ValueA, ValueB, ValueC, ValueD)
	local A, B, C, D = ValueA(self), ValueB(self), ValueC(self), ValueD(self)
	local VA, VB = Vector(A[1], A[2], A[3]), Vector(B[1], B[2], B[3])
	local AD = Angle(D[1], D[2], D[3])
	
	local Ents = FindInCone(VA, VB, C, AD)
	return FilterResults(Ents)
end)

/*==============================================================================================
	Section: Casting and converting
==============================================================================================*/
E_A:SetCost(EA_COST_ABNORMAL)

local tostring = tostring

E_A:RegisterFunction("toString", "e", "s", function(self, Value)
	return tostring(Value(self))
end)

E_A:RegisterFunction("toString", "e:", "s", function(self, Value)
	return tostring(Value(self))
end)

E_A:RegisterOperator("cast", "se", "s", function(self, Value, ConvertType)
	return tostring(Value(self))
end)