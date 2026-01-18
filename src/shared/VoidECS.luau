--!strict
local TableUtils = require(script.Parent.TableUtils)
type HashMap<K,V> = {[K]:V}

export type ECSID<T=unknown> = {__T:T}
export type Entity<T=nil> = {__T:T}
export type Component<T=unknown> = {__T:T}
export type TagComponent = Component<true>

type ComponentData<T> = HashMap<Entity,T>
type World<T=any> = HashMap< Component<T>, ComponentData<T> >


local ComponentFlagMask = 0b10000000000000000000000000000000
local PairFlagMask = 0b11000000000000000000000000000000
-- local TargetMask =  0b00111111111111111000000000000000

local FreeEntityIds: HashMap<Entity,true> = {}
local FreeComponentIds: HashMap<Component<unknown>,true> = {}

local EntityCount = 0
local ComponentCount = 0
local ComponentNextId = 0
local EntityNextId = 0


local World : World = {}
local export = {}

do --Assertion logic.
    function export.IsComponent<T>(object:ECSID<T>)
        return bit32.band(object::any,ComponentFlagMask) == ComponentFlagMask
    end

    function export.IsPair<T>(object:ECSID<T>)
        return bit32.band(object::any,PairFlagMask) == PairFlagMask
    end

    function export.AssertComponent<T>(object:ECSID<T>)
        assert(export.IsComponent(object),"Type Error! Expected component.")
    end

    function export.AssertEntity<T>(object:ECSID<T>)
        assert(not export.IsComponent(object),"Type Error! Expected entity.")
    end

    function export.AssertEntityComponent<T1,T2>(Entity:ECSID<T1>,Component:ECSID<T2>)
        export.AssertEntity(Entity);export.AssertComponent(Component);
    end

    function export.AssertPair<T1,T2>(object:ECSID<T1>)
        assert(export.IsPair(object), "Type Error! expected pair")
    end
end

do --Creation logic.
    function export.Component()

        local ID = (-1 :: any) :: Component

        if TableUtils.IsEmpty(FreeComponentIds) then
            ID = ComponentNextId :: any+ComponentFlagMask
            ComponentNextId += 1
            ComponentCount += 1
        else
            ID = next(FreeComponentIds)::any
            FreeComponentIds[ID] = nil;
        end

    
        World[ID::any] = {};
        return ID;
    end

    function export.Pair(Target:Entity)
        local ID = (-1 :: any) :: Component

        if TableUtils.IsEmpty(FreeComponentIds) then
            ID = ComponentNextId :: any
            ComponentNextId += 1
            ComponentCount += 1
        else
            ID = next(FreeComponentIds)::any
            FreeComponentIds[ID] = nil
        end

        

        ID = ID::any + bit32.lshift(Target::any, 15) + (PairFlagMask)

        World[ID::any] = {};
        return ID;
    end


    function export.Entity() : Entity
        local ID = (-1 :: any) :: Entity

        if TableUtils.IsEmpty(FreeEntityIds) then
            ID = EntityNextId :: any
            EntityNextId += 1
            EntityCount += 1
        else
            ID = next(FreeEntityIds)::any
            FreeEntityIds[ID] = nil;
        end

        return ID::any;
    end


end

do -- Setting Logic
    function export.Add<A>(Entity:Entity,Component:TagComponent)
        export.AssertEntityComponent(Entity, Component)
        World[Component][Entity] = true;
    end

    function export.Get<V>(Entity:Entity,Component:Component<V>) : V
        export.AssertEntityComponent(Entity, Component)
        return World[Component][Entity] :: V
    end

    function export.GetPairTarget<V>(Pair:Component<V>) : Entity
        export.AssertPair(Pair)
        return (bit32.extract(Pair::any,15,15)::any)::Entity
    end

    function export.Set<T>(Entity:Entity,Component:Component<T>,Value:T)
        export.AssertEntityComponent(Entity, Component)
        World[Component][Entity] = Value;
    end

    function export.Remove(Entity:Entity,Component:TagComponent)
        export.AssertEntityComponent(Entity, Component)
        World[Component][Entity] = nil
    end
end

function export.ReadComponentId<T>(Component:Component<T>)
    return bit32.replace(Component::any,0,15,17)
end

do --Logic logic ? (starting to lose its meaning)
    function export.Has(Entity:Entity,...:Component)
        export.AssertEntity(Entity)
        local Args = {...}
        local Passed = TableUtils.All(Args, function(Index: number, ComponentId: Component): boolean 
            export.AssertComponent(ComponentId)
            return World[ComponentId][Entity] ~= nil
        end)

        return Passed;
    end
end

do --Iteration logic.
    -- no <...T>    ):<

    function export.GetPairsWithTarget(Entity:Entity) : World
        export.AssertEntity(Entity)
        return TableUtils.Filter(World, function(Component: Component<any>, _): boolean
            if (bit32.band(Component::any,PairFlagMask) ~= PairFlagMask or
             bit32.extract(Component::any,15,15) ~= Entity::any) then return false end

            return true
        end)
    end


    function export.Query<T...>(...:Component)
        local Args = {...} :: {Component}
        local PassedEntites:HashMap<Entity,true> = {}
        

        local base = Args[1];

        for EntityId in World[base] do
            if not export.Has(EntityId,...) then
                continue
            end
            PassedEntites[EntityId] = true
        end



        local EntityID : Entity = next(PassedEntites)::Entity;

        local function iter()
            if EntityID == nil then return nil end

            local ReturnBuffer : {} = {EntityID}
            
            for _,ComponentId in Args do
                ReturnBuffer[#ReturnBuffer+1] = World[ComponentId][EntityID]
            end
            
            EntityID = next(PassedEntites,EntityID)::Entity;
            return unpack(ReturnBuffer);

        end


        return setmetatable(PassedEntites, {__iter = function()
                return iter
        end})
    end

    function export.ForEach<T>(Component:Component<T>,CallBack:(EntityID:Entity,Value:T)->())
        for EntityId,Value:T in World[Component] do
            CallBack(EntityId,Value);
        end
    end

end


do --Deletion logic.
    function export.FreeComponent<T>(Component:Component<T>)
        export.AssertComponent(Component)

        for Entity in World[Component] do
            World[Component][Entity] = nil
        end
        World[Component] = nil;
        
        ComponentCount -= 1

        if (export.IsPair(Component)) then 
            FreeComponentIds[bit32.replace(Component::any,0,15,16)::any] = true;
        else
            FreeComponentIds[Component] = true
        end

    end

    function export.FreeEntity(Entity:Entity)
        export.AssertEntity(Entity)
        for ComponentId,ComponentData in World do
            ComponentData[Entity] = nil
        end
        EntityCount -= 1;
        FreeEntityIds[Entity] = true;

        for Component in export.GetPairsWithTarget(Entity) do
            export.FreeComponent(Component)
        end
        
    end
end

return export